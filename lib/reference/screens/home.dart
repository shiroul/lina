import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<String> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['name'] ?? '';
  }

  Future<bool> isUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['isAdmin'] ?? false;
  }

  Future<Map<String, dynamic>> getUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'status': 'Standby', 'activeEvent': null};
    
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    
    // Check if user is registered for any active event
    final activeEventsQuery = await FirebaseFirestore.instance
        .collection('activeEvents')
        .where('signedVolunteers.general', arrayContains: user.uid)
        .get();
    
    final activeEventsMedic = await FirebaseFirestore.instance
        .collection('activeEvents')
        .where('signedVolunteers.medic', arrayContains: user.uid)
        .get();
        
    final activeEventsLogistics = await FirebaseFirestore.instance
        .collection('activeEvents')
        .where('signedVolunteers.logistics', arrayContains: user.uid)
        .get();

    if (activeEventsQuery.docs.isNotEmpty || activeEventsMedic.docs.isNotEmpty || activeEventsLogistics.docs.isNotEmpty) {
      final eventDoc = activeEventsQuery.docs.isNotEmpty 
          ? activeEventsQuery.docs.first 
          : (activeEventsMedic.docs.isNotEmpty ? activeEventsMedic.docs.first : activeEventsLogistics.docs.first);
      
      return {
        'status': 'Aktif',
        'activeEvent': eventDoc.data(),
        'eventId': eventDoc.id
      };
    }
    
    return {'status': 'Standby', 'activeEvent': null};
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double containerW = w > 500 ? 450 : w * 0.9;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Beranda Relawan'),
        actions: [
          FutureBuilder<bool>(
            future: isUserAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/createEvent');
                  },
                  icon: Icon(Icons.add_circle),
                  tooltip: 'Buat Event Bencana',
                );
              }
              return SizedBox.shrink();
            },
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: containerW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 3, color: Colors.black),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: getUserName(),
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? '';
                    return Text('👋 Selamat datang, Relawan${name.isNotEmpty ? ' $name' : ''}!', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
                  },
                ),
                SizedBox(height: 20),
                sectionTitle('📌 Status Anda Saat Ini'),
                FutureBuilder<Map<String, dynamic>>(
                  future: getUserStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return infoCard('Memuat status...');
                    }
                    
                    final statusData = snapshot.data ?? {};
                    final status = statusData['status'] ?? 'Standby';
                    final activeEvent = statusData['activeEvent'];
                    
                    if (status == 'Aktif' && activeEvent != null) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        color: Color(0xFFE8F5E8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: $status ✅', 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            SizedBox(height: 5),
                            Text('Event Aktif: ${activeEvent['type']}'),
                            Text('Lokasi: ${activeEvent['location']['city']}, ${activeEvent['location']['province']}'),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/checkin');
                              },
                              child: Text('Check-in Posko'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return infoCard('Status: Standby\nTidak ada tugas aktif.');
                    }
                  },
                ),
                SizedBox(height: 15),
                sectionTitle('🆘 Misi Bencana Terkini'),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activeEvents')
                      .where('status', isEqualTo: 'active')
                      .orderBy('reportedAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return infoCard('Tidak ada bencana aktif saat ini.');
                    }
                    
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final location = data['location'] as Map<String, dynamic>;
                        final reportedAt = data['reportedAt'] as Timestamp?;
                        
                        String timeAgo = 'Baru saja';
                        if (reportedAt != null) {
                          final diff = DateTime.now().difference(reportedAt.toDate());
                          if (diff.inHours > 0) {
                            timeAgo = '${diff.inHours} jam lalu';
                          } else if (diff.inMinutes > 0) {
                            timeAgo = '${diff.inMinutes} menit lalu';
                          }
                        }
                        
                        return listItem(
                          '${data['type']} ${location['city']}',
                          '${data['type']} • ${location['city']}, ${location['province']} • $timeAgo',
                          onTap: () {
                            Navigator.pushNamed(
                              context, 
                              '/detail',
                              arguments: {
                                'eventId': doc.id,
                                'eventData': data,
                              },
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/allEvents');
                  }, 
                  child: Text('Lihat Semua Misi')
                ),
                SizedBox(height: 15),
                sectionTitle('🛠 Profil & Keahlian'),
                listItem('Update Keahlian Anda', 'Tambahkan P3K, Logistik, Dokumentasi...', onTap: () {
                  Navigator.pushNamed(context, '/profileSkill');
                }),
                SizedBox(height: 15),
                sectionTitle('📜 Riwayat Partisipasi'),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('volunteerHistory')
                      .where('volunteerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .orderBy('completedAt', descending: true)
                      .limit(3)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return infoCard('Memuat riwayat...');
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return infoCard('Belum ada riwayat. Anda akan melihat misi yang telah diselesaikan di sini.');
                    }
                    
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final completedAt = data['completedAt'] as Timestamp;
                        
                        return listItem(
                          data['eventType'] ?? 'Event Bencana',
                          'Selesai: ${_formatDate(completedAt.toDate())} • Peran: ${data['role']}',
                        );
                      }).toList(),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  }, 
                  child: Text('Lihat Semua Riwayat')
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget infoCard(String content) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        color: Color(0xFFE8F4F8),
        child: Text(content),
      );

  Widget listItem(String title, String subtitle, {VoidCallback? onTap}) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      );
}