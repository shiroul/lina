import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'volunteer_history.dart'; // Ganti dengan import yang sesuai

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<String> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['name'] ?? '';
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
                    return Text('👋 Selamat datang, Relawan${name.isNotEmpty ? ' $name' : ''}!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
                  },
                ),
                SizedBox(height: 20),
                sectionTitle('📌 Status Anda Saat Ini'),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return infoCard('Status: Standby\nTidak ada tugas aktif.');
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('activeEvents').snapshots(),
                      builder: (context, eventSnap) {
                        if (!eventSnap.hasData) return infoCard('Status: Standby\nTidak ada tugas aktif.');
                        // Cek apakah user terdaftar di event manapun
                        String? activeEventId;
                        String? activeEventType;
                        String? activeEventLocation;
                        String? activeEventCategory;
                        for (final doc in eventSnap.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final signed = data['signedVolunteers'] as Map<String, dynamic>? ?? {};
                          for (final entry in signed.entries) {
                            final list = (entry.value as List?) ?? [];
                            if (list.contains(userId)) {
                              activeEventId = doc.id;
                              activeEventType = data['type'] ?? '-';
                              final loc = data['location'] ?? {};
                              activeEventLocation = (loc['city'] ?? '-') + ', ' + (loc['province'] ?? '-');
                              activeEventCategory = entry.key;
                              break;
                            }
                          }
                          if (activeEventId != null) break;
                        }
                        if (activeEventId != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              infoCard('Status: Relawan Aktif'),
                              SizedBox(height: 8),
                              Card(
                                color: Color(0xFFE8F4F8),
                                child: ListTile(
                                  title: Text('Tugas Aktif: $activeEventType'),
                                  subtitle: Text('Lokasi: $activeEventLocation\nKategori: $activeEventCategory'),
                                  trailing: Icon(Icons.assignment_turned_in, color: Colors.green),
                                  onTap: () {
                                    Navigator.pushNamed(context, '/detail', arguments: {'eventId': activeEventId});
                                  },
                                ),
                              ),
                            ],
                          );
                        } else {
                          return infoCard('Status: Standby\nTidak ada tugas aktif.');
                        }
                      },
                    );
                  },
                ),
                SizedBox(height: 15),
                sectionTitle('🆘 Misi Bencana Terkini'),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activeEvents')
                      .orderBy('reportedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return infoCard('Belum ada misi aktif.');
                    }
                    final events = snapshot.data!.docs;
                    return Column(
                      children: [
                        ...events.take(3).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final type = data['type'] ?? '-';
                          final location = data['location'] ?? {};
                          final city = location['city'] ?? '-';
                          final province = location['province'] ?? '-';
                          final ts = data['reportedAt'] as Timestamp?;
                          final timeStr = ts != null ? _timeAgo(ts.toDate()) : '-';
                          return listItem(
                            type,
                            '$city, $province • $timeStr',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/detail',
                                arguments: {'eventId': doc.id},
                              );
                            },
                          );
                        }).toList(),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigasi ke halaman semua misi
                          },
                          child: Text('Lihat Semua Misi'),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 15),
                sectionTitle('🛠 Profil & Keahlian'),
                listItem('Update Keahlian Anda', 'Tambahkan P3K, Logistik, Dokumentasi...', onTap: () {
                  Navigator.pushNamed(context, '/profileSkill');
                }),
                SizedBox(height: 15),
                sectionTitle('📜 Riwayat Partisipasi'),
                ListTile(
                  title: Text('Lihat Riwayat Partisipasi'),
                  subtitle: Text('Lihat event yang pernah Anda ikuti.'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VolunteerHistoryPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/createEvent');
        },
        child: Icon(Icons.add_box),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
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

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
