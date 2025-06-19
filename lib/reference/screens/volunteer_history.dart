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
        backgroundColor: Color(0xFFF5F5F0),
        appBar: AppBar(title: Text('Riwayat Partisipasi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Anda harus login terlebih dahulu'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    double w = MediaQuery.of(context).size.width;
    double containerW = w > 500 ? 450 : w * 0.9;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Riwayat Partisipasi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
                // User stats section
                FutureBuilder<Map<String, dynamic>>(
                  future: _getUserStats(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    final stats = snapshot.data ?? {};
                    
                    return Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '📊 Statistik Relawan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  '${stats['totalEvents'] ?? 0}',
                                  'Total Event',
                                  Icons.event,
                                  Colors.blue,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  '${stats['totalHours'] ?? 0}',
                                  'Jam Kontribusi',
                                  Icons.access_time,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  '${stats['completionRate'] ?? 0}%',
                                  'Tingkat Penyelesaian',
                                  Icons.check_circle,
                                  Colors.orange,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  '${stats['favoriteRole'] ?? 'Belum ada'}',
                                  'Peran Favorit',
                                  Icons.star,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 20),
                
                Text(
                  '📜 Riwayat Event',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                
                // History list
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('volunteerHistory')
                      .where('volunteerId', isEqualTo: user.uid)
                      .orderBy('completedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Container(
                        padding: EdgeInsets.all(20),
                        color: Colors.red[50],
                        child: Column(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Terjadi kesalahan saat memuat riwayat',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(30),
                        child: Column(
                          children: [
                            Icon(Icons.history, color: Colors.grey, size: 60),
                            SizedBox(height: 15),
                            Text(
                              'Belum ada riwayat partisipasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Bergabunglah dalam misi bencana untuk melihat riwayat di sini',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/allEvents');
                              },
                              child: Text('Lihat Misi Tersedia'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildHistoryCard(data);
                      }).toList(),
                    );
                  },
                ),
                
                SizedBox(height: 20),
                
                // Active registrations
                Text(
                  '🔄 Registrasi Aktif',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('volunteerRegistrations')
                      .where('volunteerId', isEqualTo: user.uid)
                      .where('status', whereIn: ['registered', 'checked-in'])
                      .orderBy('registeredAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(20),
                        color: Color(0xFFE8F4F8),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 40),
                            SizedBox(height: 10),
                            Text('Tidak ada registrasi aktif'),
                            Text(
                              'Anda sedang tidak terdaftar dalam event manapun',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildActiveRegistrationCard(context, data);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final completedAt = data['completedAt'] as Timestamp;
    final date = completedAt.toDate();
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    
    Color statusColor;
    IconData statusIcon;
    
    switch (data['status']) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'no-show':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['eventType'] ?? 'Event Bencana',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      _getStatusText(data['status']),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('📍 ${data['location'] ?? 'Lokasi tidak tersedia'}'),
          Text('👤 Peran: ${data['role'] ?? 'Tidak diketahui'}'),
          Text('📅 Selesai: $formattedDate'),
          if (data['hoursContributed'] != null) ...[
            Text('⏰ Kontribusi: ${data['hoursContributed']} jam'),
          ],
          if (data['feedback'] != null && data['feedback'].isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Catatan: ${data['feedback']}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveRegistrationCard(BuildContext context, Map<String, dynamic> data) {
    final registeredAt = data['registeredAt'] as Timestamp;
    final date = registeredAt.toDate();
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    
    Color statusColor = data['status'] == 'checked-in' ? Colors.green : Colors.blue;
    String statusText = data['status'] == 'checked-in' ? 'Sudah Check-in' : 'Terdaftar';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['selectedRoleText'] ?? 'Event Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('👤 Peran: ${data['role'] ?? 'Tidak diketahui'}'),
          Text('📅 Terdaftar: $formattedDate'),
          SizedBox(height: 12),
          
          if (data['status'] == 'registered') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/checkin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Check-in Sekarang'),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/checkin');
                    },
                    child: Text('Lihat Status'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showCompleteEventDialog(context, data);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCompleteEventDialog(BuildContext context, Map<String, dynamic> registrationData) {
    final feedbackController = TextEditingController();
    int hoursContributed = 4; // Default hours

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Selesaikan Partisipasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Berapa jam Anda berkontribusi?'),
              SizedBox(height: 10),
              Row(
                children: [
                  Text('Jam: '),
                  Expanded(
                    child: Slider(
                      value: hoursContributed.toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: '$hoursContributed jam',
                      onChanged: (value) {
                        setState(() {
                          hoursContributed = value.round();
                        });
                      },
                    ),
                  ),
                  Text('$hoursContributed'),
                ],
              ),
              SizedBox(height: 15),
              TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Bagaimana pengalaman Anda?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _completeEvent(
                  registrationData,
                  hoursContributed,
                  feedbackController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Terima kasih atas kontribusi Anda!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeEvent(Map<String, dynamic> registrationData, 
                              int hours, String feedback) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Add to volunteer history
      await FirebaseFirestore.instance.collection('volunteerHistory').add({
        'volunteerId': user.uid,
        'eventId': registrationData['eventId'],
        'eventType': registrationData['selectedRoleText'] ?? 'Event Bencana',
        'role': registrationData['role'],
        'location': 'Jakarta', // Get from event data
        'completedAt': FieldValue.serverTimestamp(),
        'hoursContributed': hours,
        'feedback': feedback,
        'status': 'completed',
      });

      // Update registration status
      final registrationQuery = await FirebaseFirestore.instance
          .collection('volunteerRegistrations')
          .where('volunteerId', isEqualTo: user.uid)
          .where('eventId', isEqualTo: registrationData['eventId'])
          .get();

      for (var doc in registrationQuery.docs) {
        await doc.reference.update({'status': 'completed'});
      }

      // Update user availability
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'availability': true,
        'currentEventId': FieldValue.delete(),
        'currentEventRole': FieldValue.delete(),
      });

    } catch (e) {
      print('Error completing event: $e');
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'no-show':
        return 'Tidak Hadir';
      default:
        return 'Unknown';
    }
  }

  Future<Map<String, dynamic>> _getUserStats(String userId) async {
    try {
      // Get volunteer history
      final historyQuery = await FirebaseFirestore.instance
          .collection('volunteerHistory')
          .where('volunteerId', isEqualTo: userId)
          .get();

      int totalEvents = historyQuery.docs.length;
      int totalHours = 0;
      int completedEvents = 0;
      Map<String, int> roleCounts = {};

      for (var doc in historyQuery.docs) {
        final data = doc.data();
        totalHours += (data['hoursContributed'] as int?) ?? 0;
        
        if (data['status'] == 'completed') {
          completedEvents++;
        }

        String role = data['role'] ?? 'unknown';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }

      int completionRate = totalEvents > 0 ? (completedEvents * 100 / totalEvents).round() : 0;
      
      String favoriteRole = 'Belum ada';
      if (roleCounts.isNotEmpty) {
        var sortedRoles = roleCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        favoriteRole = _getRoleDisplayName(sortedRoles.first.key);
      }

      return {
        'totalEvents': totalEvents,
        'totalHours': totalHours,
        'completionRate': completionRate,
        'favoriteRole': favoriteRole,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'general':
        return 'Bantuan Umum';
      case 'medic':
        return 'P3K & Kesehatan';
      case 'logistics':
        return 'Logistik';
      default:
        return role;
    }
  }
}