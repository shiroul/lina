import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final eventId = args != null ? args['eventId'] as String? : null;
    double w = MediaQuery.of(context).size.width;
    double cardW = w > 500 ? 450 : w * 0.9;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(title: Text('Pilih Peran'), actions: [TextButton(onPressed: () {}, child: Text('Bantuan', style: TextStyle(color: Colors.white)))]),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: cardW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(width: 3, color: Colors.black)),
            child: eventId == null
                ? Text('Data bencana tidak ditemukan.')
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('activeEvents').doc(eventId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('Data bencana tidak ditemukan.');
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final type = data['type'] ?? '-';
                      final details = data['details'] ?? '-';
                      final location = data['location'] ?? {};
                      final city = location['city'] ?? '-';
                      final province = location['province'] ?? '-';
                      final ts = data['reportedAt'] as Timestamp?;
                      final timeStr = ts != null ? _timeAgo(ts.toDate()) : '-';
                      final requiredVolunteers = data['requiredVolunteers'] as Map<String, dynamic>? ?? {};
                      final signedVolunteers = data['signedVolunteers'] as Map<String, dynamic>? ?? {};
                      String? selectedCategory;
                      String? errorMsg;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          // Hitung sisa slot untuk setiap kategori
                          Map<String, int> slotLeft = {};
                          requiredVolunteers.forEach((key, value) {
                            final signed = (signedVolunteers[key] as List?)?.length ?? 0;
                            slotLeft[key] = (value as int) - signed;
                          });
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              SizedBox(height: 8),
                              Text('Lokasi: $city, $province'),
                              SizedBox(height: 8),
                              Text('Waktu: $timeStr'),
                              SizedBox(height: 8),
                              Text('Detail: $details'),
                              SizedBox(height: 15),
                              Text('Pilih Peran Sesuai Kemampuan', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 15),
                              ...requiredVolunteers.entries.map((e) => Card(
                                    color: (selectedCategory == e.key) ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                                    child: RadioListTile<String>(
                                      value: e.key,
                                      groupValue: selectedCategory,
                                      onChanged: slotLeft[e.key]! > 0 ? (val) => setState(() => selectedCategory = val) : null,
                                      title: Text('${e.key}', style: TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Sisa slot: ${slotLeft[e.key]} dari ${e.value}'),
                                      secondary: slotLeft[e.key]! == 0 ? Icon(Icons.lock, color: Colors.red) : null,
                                    ),
                                  )),
                              if (errorMsg != null) ...[
                                SizedBox(height: 10),
                                Text(errorMsg!, style: TextStyle(color: Colors.red)),
                              ],
                              SizedBox(height: 20),
                              Container(
                                color: Color(0xFFE8F4F8),
                                padding: EdgeInsets.all(15),
                                child: Column(children: [
                                  Text('📹 Video Briefing Singkat (2 menit)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  Container(
                                    color: Colors.black,
                                    height: 60,
                                    child: Center(child: Icon(Icons.play_arrow, color: Colors.white)),
                                  ),
                                ]),
                              ),
                              SizedBox(height: 15),
                              Text('⏰ Jadwal: Hari ini, 14:00 – 18:00\n📍 Berkumpul: Posko Cipinang Besar', style: TextStyle(fontSize: 12)),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: (selectedCategory == null || slotLeft[selectedCategory] == 0)
                                    ? null
                                    : () async {
                                        setState(() => errorMsg = null);
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) {
                                          setState(() => errorMsg = 'Anda harus login.');
                                          return;
                                        }
                                        // Ambil ulang data event untuk menghindari race condition
                                        final doc = await FirebaseFirestore.instance.collection('activeEvents').doc(eventId).get();
                                        final freshData = doc.data() as Map<String, dynamic>?;
                                        if (freshData == null) {
                                          setState(() => errorMsg = 'Data bencana tidak ditemukan.');
                                          return;
                                        }
                                        final freshSigned = (freshData['signedVolunteers'] as Map<String, dynamic>? ?? {});
                                        final freshRequired = (freshData['requiredVolunteers'] as Map<String, dynamic>? ?? {});
                                        final freshList = (freshSigned[selectedCategory] as List?) ?? [];
                                        final max = (freshRequired[selectedCategory] as int?) ?? 0;
                                        if (freshList.length >= max) {
                                          setState(() => errorMsg = 'Slot relawan sudah penuh.');
                                          return;
                                        }
                                        if (freshList.contains(user.uid)) {
                                          setState(() => errorMsg = 'Anda sudah terdaftar di kategori ini.');
                                          return;
                                        }
                                        // Cek apakah user sudah terdaftar di kategori lain pada event ini
                                        bool alreadyInThisEvent = false;
                                        for (final entry in freshSigned.entries) {
                                          final list = (entry.value as List?) ?? [];
                                          if (list.contains(user.uid)) {
                                            alreadyInThisEvent = true;
                                            break;
                                          }
                                        }
                                        if (alreadyInThisEvent) {
                                          setState(() => errorMsg = 'Anda sudah terdaftar di event ini.');
                                          return;
                                        }
                                        // Cek apakah user sudah terdaftar di event lain
                                        final userEvents = await FirebaseFirestore.instance.collection('activeEvents')
                                          .where('signedVolunteers.${selectedCategory}', arrayContains: user.uid)
                                          .get();
                                        if (userEvents.docs.isNotEmpty) {
                                          setState(() => errorMsg = 'Anda sudah terdaftar di event lain.');
                                          return;
                                        }
                                        // Update Firestore (tambah UID ke array)
                                        await FirebaseFirestore.instance.collection('activeEvents').doc(eventId).update({
                                          'signedVolunteers.$selectedCategory': FieldValue.arrayUnion([user.uid])
                                        });
                                        Navigator.pop(context);
                                      },
                                child: Text('Ikut Sekarang'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
