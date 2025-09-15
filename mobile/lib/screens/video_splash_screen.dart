import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/splash_screen_video.mp4');
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // Start playing the video
        _controller.play();
        
        // Listen for video completion
        _controller.addListener(() {
          if (_controller.value.position >= _controller.value.duration) {
            _navigateToNextScreen();
          }
        });
        
        // Fallback timer in case video doesn't complete
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _navigateToNextScreen();
          }
        });
      }
    } catch (e) {
      // Video failed to load - show static splash for minimum duration
      print('Video failed to load: $e');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _navigateToNextScreen();
        }
      });
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (mounted) {
      // Add a small delay to ensure splash screen is visible
      await Future.delayed(const Duration(milliseconds: 500));
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF667EEA),
      body: Stack(
        children: [
          // Video background - full screen
          if (_isVideoInitialized)
            Positioned.fill(
              child: VideoPlayer(_controller),
            ),
          
          // Fallback gradient background
          if (!_isVideoInitialized)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                    Color(0xFF6B73FF),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
