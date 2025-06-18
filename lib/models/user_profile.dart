import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart';

class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final List<String> skills;
  final bool availability;
  final GeoPoint? lastLocation;
  final String? profileImageUrl;
  final String roleType;
  final bool isAdmin;

  UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.skills,
    this.lastLocation,
    this.profileImageUrl,
    this.availability = true,
    this.roleType = 'general',
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'skills': skills,
      'availability': availability,
      'lastLocation': lastLocation,
      'profileImageUrl': profileImageUrl,
      'roleType': roleType,
      'isAdmin': isAdmin,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<void> saveToFirestore(UserProfile user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await docRef.set(user.toMap(), SetOptions(merge: true));
  }
}
