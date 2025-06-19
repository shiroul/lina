import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerHistoryPage extends StatelessWidget {
  const VolunteerHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        appBar: AppBar(title: const Text('Riwayat Partisipasi')),
        body: const Center(
          child: Text('Anda harus login terlebih dahulu'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text('Riwayat Partisipasi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('activeEvents').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada data event.'));
          }
          final docs = snapshot.data!.docs;
          final uid = user.uid;
          List<Map<String, dynamic>> active = [];
          List<Map<String, dynamic>> history = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final signedVolunteers = data['signedVolunteers'] as Map<String, dynamic>? ?? {};
            String? userRole;
            signedVolunteers.forEach((role, list) {
              if (list is List && list.contains(uid)) {
                userRole = role;
              }
            });
            if (userRole != null) {
              final event = {
                ...data,
                'id': doc.id,
                'userRole': userRole,
              };
              if ((data['status'] ?? 'active') == 'active') {
                active.add(event);
              } else {
                history.add(event);
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔄 Registrasi Aktif',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (active.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xFFE8F4F8),
                    child: const Text('Tidak ada registrasi aktif.'),
                  )
                else
                  ...active.map((e) => _buildEventCard(e, true)),
                const SizedBox(height: 30),
                const Text(
                  '📜 Riwayat Event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Text('Belum ada riwayat partisipasi.'),
                  )
                else
                  ...history.map((e) => _buildEventCard(e, false)),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildEventCard(Map<String, dynamic> data, bool isActive) {
    final location = data['location'] is Map ? data['location']['city'] ?? '-' : '-';
    final type = data['type'] ?? 'Event Bencana';
    final details = data['details'] ?? '';
    final role = data['userRole'] ?? '-';
    final status = data['status'] ?? 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('📍 $location'),
          Text('👤 Peran: $role'),
          if (details.isNotEmpty) Text('📝 $details'),
          const SizedBox(height: 4),
          Text('Status: ${isActive ? 'Aktif' : status}'),
        ],
      ),
    );
  }
}
