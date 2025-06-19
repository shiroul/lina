import 'package:cloud_firestore/cloud_firestore.dart';

class DisasterEvent {
  final String type;
  final String details;
  final GeoPoint coordinates;
  final String city;
  final String province;
  final Map<String, int> requiredVolunteers;
  final String severityLevel;
  final String status;

  DisasterEvent({
    required this.type,
    required this.details,
    required this.coordinates,
    required this.city,
    required this.province,
    required this.requiredVolunteers,
    this.severityLevel = 'sedang',
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'details': details,
      'reportedAt': FieldValue.serverTimestamp(),
      'location': {
        'coordinates': coordinates,
        'city': city,
        'province': province,
      },
      'requiredVolunteers': requiredVolunteers,
      'signedVolunteers': {
        'general': [],
        'medic': [],
        'logistics': [],
      },
      'media': [],
      'severityLevel': severityLevel,
      'status': status,
    };
  }

  Future<void> save() async {
    await FirebaseFirestore.instance.collection('activeEvents').add(toMap());
  }
}
