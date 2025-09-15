import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user.dart' as app_user;
import '../models/user.dart';
import 'firebase_service.dart';
import 'qr_service.dart';

class AuthService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  static User? _currentUser;

  /// Sign in with Google using Firebase Auth
  static Future<User?> signInWithGoogle() async {
    try {
      firebase_auth.UserCredential userCredential;
      
      if (kIsWeb) {
        // For web, use Firebase Auth popup with proper error handling
        final googleProvider = firebase_auth.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        
        try {
          userCredential = await _auth.signInWithPopup(googleProvider);
        } on firebase_auth.FirebaseAuthException catch (e) {
          if (e.code == 'popup-blocked') {
            // Fallback to redirect method
            await _auth.signInWithRedirect(googleProvider);
            userCredential = await _auth.getRedirectResult();
            if (userCredential.user == null) {
              throw Exception('Sign-in was cancelled or failed');
            }
          } else {
            throw Exception('Google sign-in failed: ${e.message}');
          }
        }
      } else {
        // For mobile, use Google Sign-In plugin
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }
      
      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      // Try to load existing user from Firestore
      User? existing = await FirebaseService.getUser(firebaseUser.uid);

      if (existing != null) {
        // Persist and return existing user
        await _storeUserData(existing);
        _currentUser = existing;
        return existing;
      }

      // Create minimal user profile (no demo balance, no UPI setup here)
      final newUser = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? 'google.user@example.com',
        name: firebaseUser.displayName ?? 'Google User',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        balance: 0.0,
      );

      // Persist locally first
      await _storeUserData(newUser);
      _currentUser = newUser;

      // Create in Firestore (best-effort)
      try {
        await FirebaseService.createUser(newUser);
      } catch (e) {
        print('Warning: Could not store user in Firestore: $e');
      }

      return newUser;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign in with Apple
  static Future<User?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create user object
      final user = User(
        id: credential.userIdentifier ?? '',
        email: credential.email ?? 'apple.user@example.com',
        name: credential.givenName != null && credential.familyName != null
            ? '${credential.givenName} ${credential.familyName}'
            : 'Apple User',
        photoUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store user data locally first
      await _storeUserData(user);
      _currentUser = user;

      return user;
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  /// Sign in with email and password
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final firebase_auth.UserCredential userCredential = 
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      // Get or create user object
      User? user = await FirebaseService.getUser(firebaseUser.uid);
      
      if (user == null) {
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          name: firebaseUser.displayName ?? email.split('@')[0],
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await FirebaseService.createUser(user);
      }

      // Store user data locally
      await _storeUserData(user);
      _currentUser = user;

      return user;
    } catch (e) {
      throw Exception('Email sign-in failed: $e');
    }
  }

  /// Sign up with email and password
  static Future<User?> signUpWithEmail(String email, String password, String name, {String? phoneNumber}) async {
    try {
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw Exception('All fields are required');
      }

      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final firebase_auth.UserCredential userCredential = 
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      // Update display name
      await firebaseUser.updateDisplayName(name);

      // Create user object
      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store user data locally first, then try Firestore
      await _storeUserData(user);
      _currentUser = user;
      
      // Try to store in Firestore, but don't fail if it doesn't work
      try {
        await FirebaseService.createUser(user);
      } catch (e) {
        print('Warning: Could not store user in Firestore: $e');
        // Continue anyway - user is still authenticated
      }

      return user;
    } catch (e) {
      throw Exception('Email sign-up failed: $e');
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(User user) async {
    try {
      await FirebaseService.updateUser(user);
      _currentUser = user;
      await _storeUserData(user);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    _currentUser = null;
    
    // Clear stored user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  /// Generate demo phone number for testing
  static String _generateDemoPhoneNumber() {
    // Generate a demo phone number for testing
    final random = Random();
    final prefix = ['98', '99', '97', '96', '95', '94', '93', '92', '91', '90'][random.nextInt(10)];
    final suffix = random.nextInt(100000000).toString().padLeft(8, '0');
    return '$prefix$suffix';
  }


  /// Get current user
  static User? getCurrentUser() => _currentUser;

  /// Refresh current user data from Firestore
  static Future<User?> refreshCurrentUser() async {
    if (_currentUser == null) return null;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .get();
      
      if (doc.exists) {
        _currentUser = User.fromJson(doc.data()!);
        await _storeUserData(_currentUser!);
        return _currentUser;
      }
      return _currentUser;
    } catch (e) {
      print('Error refreshing user data: $e');
      return _currentUser;
    }
  }

  /// Check if user is signed in
  static bool isSignedIn() => _currentUser != null;

  /// Update current user data
  static Future<void> updateCurrentUser(User updatedUser) async {
    _currentUser = updatedUser;
    await _storeUserData(updatedUser);
  }

  /// Load user from storage
  static Future<User?> loadUser() async {
    try {
      const storage = FlutterSecureStorage();
      final userDataString = await storage.read(key: 'user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _currentUser = User.fromJson(userData);
        return _currentUser;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Store user data securely
  static Future<void> _storeUserData(User user) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Invalid email format');
      }

      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
}