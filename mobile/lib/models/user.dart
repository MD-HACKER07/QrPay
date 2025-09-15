class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final String? upiId;
  final String? qrCodeUrl;
  final String? qrData;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Enhanced profile fields
  final String? dateOfBirth;
  final String? gender;
  final String? occupation;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? emergencyContact;
  final String? emergencyContactName;
  final bool isKycCompleted;
  final String? panNumber;
  final String? aadharNumber;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.upiId,
    this.qrCodeUrl,
    this.qrData,
    this.balance = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.dateOfBirth,
    this.gender,
    this.occupation,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.emergencyContact,
    this.emergencyContactName,
    this.isKycCompleted = false,
    this.panNumber,
    this.aadharNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'phoneNumber': phoneNumber,
      'upiId': upiId,
      'qrCodeUrl': qrCodeUrl,
      'qrData': qrData,
      'balance': balance,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'occupation': occupation,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
      'isKycCompleted': isKycCompleted,
      'panNumber': panNumber,
      'aadharNumber': aadharNumber,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['createdAt']),
      phoneNumber: json['phoneNumber'],
      upiId: json['upiId'],
      qrCodeUrl: json['qrCodeUrl'],
      qrData: json['qrData'],
      balance: (json['balance'] ?? 0.0).toDouble(),
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      occupation: json['occupation'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      emergencyContact: json['emergencyContact'],
      emergencyContactName: json['emergencyContactName'],
      isKycCompleted: json['isKycCompleted'] ?? false,
      panNumber: json['panNumber'],
      aadharNumber: json['aadharNumber'],
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is Map && value.containsKey('_seconds')) {
      // Firestore Timestamp format
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    return DateTime.now();
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumber,
    String? upiId,
    String? qrCodeUrl,
    String? qrData,
    double? balance,
    String? dateOfBirth,
    String? gender,
    String? occupation,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? emergencyContact,
    String? emergencyContactName,
    bool? isKycCompleted,
    String? panNumber,
    String? aadharNumber,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      upiId: upiId ?? this.upiId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      qrData: qrData ?? this.qrData,
      balance: balance ?? this.balance,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      isKycCompleted: isKycCompleted ?? this.isKycCompleted,
      panNumber: panNumber ?? this.panNumber,
      aadharNumber: aadharNumber ?? this.aadharNumber,
    );
  }
}