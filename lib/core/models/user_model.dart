import 'package:cloud_firestore/cloud_firestore.dart';

/// /users/{uid} — PRD-exact schema.
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String role; // "admin" | "staff" | "donor"
  final List<String> preferredCategories; // donor only
  final List<String> donationHistory; // drive_ids, donor only
  final String? fcmToken; // admin only
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    this.preferredCategories = const [],
    this.donationHistory = const [],
    this.fcmToken,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isDonor => role == 'donor';

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return UserModel(
      uid: d['uid'] as String,
      displayName: d['display_name'] as String,
      email: d['email'] as String,
      role: d['role'] as String,
      preferredCategories: List<String>.from(d['preferred_categories'] ?? []),
      donationHistory: List<String>.from(d['donation_history'] ?? []),
      fcmToken: d['fcm_token'] as String?,
      createdAt: (d['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'display_name': displayName,
    'email': email,
    'role': role,
    'preferred_categories': preferredCategories,
    'donation_history': donationHistory,
    'fcm_token': fcmToken,
    'created_at': Timestamp.fromDate(createdAt),
  };
}
