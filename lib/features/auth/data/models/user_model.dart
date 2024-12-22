// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/user.dart';
import 'package:equatable/equatable.dart';

class UserModel extends User with EquatableMixin {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final Map<String, dynamic>? metadata;

  // New authentication-related fields
  final String? authToken;
  final String? refreshToken;
  final DateTime? tokenExpiryTime;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
    this.metadata,
    this.authToken,
    this.refreshToken,
    this.tokenExpiryTime,
  }) : super(
    id: id,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    isEmailVerified: isEmailVerified,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      authToken: json['authToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenExpiryTime: json['tokenExpiryTime'] != null
          ? DateTime.parse(json['tokenExpiryTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'metadata': metadata,
      'authToken': authToken,
      'refreshToken': refreshToken,
      'tokenExpiryTime': tokenExpiryTime?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    Map<String, dynamic>? metadata,
    String? authToken,
    String? refreshToken,
    DateTime? tokenExpiryTime,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      metadata: metadata ?? this.metadata,
      authToken: authToken ?? this.authToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiryTime: tokenExpiryTime ?? this.tokenExpiryTime,
    );
  }

  // Helper methods for authentication
  bool get isAuthenticated => authToken != null;

  bool get needsTokenRefresh {
    if (tokenExpiryTime == null || authToken == null) return true;
    // Return true if token expires in less than 5 minutes
    return DateTime.now().isAfter(tokenExpiryTime!.subtract(
      const Duration(minutes: 5),
    ));
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    createdAt,
    lastLoginAt,
    isEmailVerified,
    metadata,
    authToken,
    refreshToken,
    tokenExpiryTime,
  ];

  // Factory constructor for creating an empty user
  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      isEmailVerified: false,
    );
  }

  // Factory constructor for creating a user from Firebase User
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified ?? false,
      metadata: {
        'lastSignInTime': firebaseUser.metadata?.lastSignInTime?.toIso8601String(),
        'creationTime': firebaseUser.metadata?.creationTime?.toIso8601String(),
      },
    );
  }
}