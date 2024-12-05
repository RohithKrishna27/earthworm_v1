import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String userType; // 'farmer' or 'buyer'
  final DateTime createdAt;
  final String? customUserID; // New field for custom user ID

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.createdAt,
    required this.customUserID,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      userType: map['userType'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      customUserID: map['customUserID'], // Added custom user ID
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'createdAt': FieldValue.serverTimestamp(),
      if (customUserID != null) 'customUserID': customUserID,
    };
  }
}
