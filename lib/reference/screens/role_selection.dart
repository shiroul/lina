import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? selectedRole;
  Map<String, dynamic>? eventData;
  String? eventId;
  bool isLoading = false;
  List<String> userSkills = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments passed from previous screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      eventId = args['eventId'];
      eventData = args['eventData'];
    } else {
      // Load sample data for testing
      _loadSampleData();
    }
    
    _loadUserSkills();
  }

  void _loadSampleData() {
    eventData = {
      'type': 'Banjir Jakarta Timur',
      'location': {
        'city': 'Jakarta Timur',
        'province': 'DKI Jakarta',
      },
      'requiredVolunteers': {
        'general': 10,
        'medic': 3,
        'logistics': 5,
      },
      'signedVolunteers': {
        'general': [],
        'medic': [],
        'logistics': [],
      },
    };
    eventId = 'sample-event';
  }

  Future<void> _loadUserSkills() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          userSkills = (data['skills'] as List?)?.cast<String>() ?? [];
        });
      }
    } catch (e) {
      print('Error loading user skills: $e');
    }
  }

  Future<void> _registerForEvent() async {
    if (selectedRole == null || eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih salah satu peran terlebih dahulu.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda harus login terlebih dahulu.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Determine the volunteer type based on selected role
      String volunteerType = 'general';
      if (selectedRole!.contains('P3K') || selectedRole!.contains('Kesehatan')) {
        volunteerType = 'medic';
      } else if (selectedRole!.contains('Logistik')) {
        volunteerType = 'logistics';
      } else if (selectedRole!.contains('Evakuasi')) {
        volunteerType = 'general'; // or create 'evacuation' type if needed
      }

      // Check if user is already registered for this event
      final eventDoc = await FirebaseFirestore.instance
          .collection('activeEvents')
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        throw Exception('Event tidak ditemukan');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final signedVolunteers = eventData['signedVolunteers'] as Map<String, dynamic>;

      // Check if user is already registered in any capacity
      bool alreadyRegistered = false;
      String existingRole = '';
      
      for (String role in ['general', 'medic', 'logistics']) {
        final volunteers = signedVolunteers[role] as List<dynamic>? ?? [];
        if (volunteers.contains(user.uid)) {
          alreadyRegistered = true;
          existingRole = role;
          break;
        }
      }

      if (alreadyRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda sudah terdaftar untuk event ini sebagai $existingRole')),
        );
        setState(() => isLoading = false);
        return;
      }

      // Check if the selected role is still available
      final requiredVolunteers = eventData['requiredVolunteers'] as Map<String, dynamic>;
      final currentSignedCount = (signedVolunteers[volunteerType] as List?)?.length ?? 0;
      final requiredCount = requiredVolunteers[volunteerType] ?? 0;

      if (currentSignedCount >= requiredCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maaf, kuota untuk peran ini sudah penuh')),
        );
        setState(() => isLoading = false);
        return;
      }

      // Register user for the event
      await FirebaseFirestore.instance
          .collection('activeEvents')
          .doc(eventId)
          .update({
        'signedVolunteers.$volunteerType': FieldValue.arrayUnion([user.uid])
      });

      // Update user's active event status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'currentEventId': eventId,
        'currentEventRole': volunteerType,
        'availability': false, // User is now busy
      });

      // Create volunteer registration record
      await FirebaseFirestore.instance
          .collection('volunteerRegistrations')
          .add({
        'volunteerId': user.uid,
        'eventId': eventId,
        'role': volunteerType,
        'selectedRoleText': selectedRole,
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'registered', // registered, checked-in, completed
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil mendaftar sebagai $selectedRole!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to check-in page or home
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double cardW = w > 500 ? 450 : w * 0.9;

    if (eventData == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        appBar: AppBar(title: Text('Pilih Peran')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final location = eventData!['location'] as Map<String, dynamic>;
    final requiredVolunteers = eventData!['requiredVolunteers'] as Map<String, dynamic>;
    final signedVolunteers = eventData!['signedVolunteers'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Pilih Peran'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Bantuan'),
                  content: Text(
                    'Pilih peran sesuai dengan keahlian Anda:\n\n'
                    '• Bantuan Logistik: Distribusi bantuan, mengatur barang\n'
                    '• P3K & Kesehatan: Pertolongan pertama, bantuan medis\n'
                    '• Evakuasi: Membantu mengevakuasi korban\n\n'
                    'Peran yang tersedia akan ditampilkan berdasarkan kebutuhan event.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
            child: Text('Bantuan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: cardW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 3, color: Colors.black),
            ),
            child: Column(
              children: [
                Text(
                  'Pilih Peran untuk ${eventData!['type']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  '📍 ${location['city']}, ${location['province']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 20),

                // Role cards
                _buildRoleCard(
                  'Bantuan Logistik',
                  'Distribusi bantuan, mengatur barang, koordinasi supplies',
                  Colors.green,
                  'Rendah',
                  requiredVolunteers['logistics'] ?? 0,
                  (signedVolunteers['logistics'] as List?)?.length ?? 0,
                  userSkills.contains('Logistik & Distribusi'),
                ),
                
                _buildRoleCard(
                  'P3K & Kesehatan',
                  'Pertolongan pertama, bantuan medis, perawatan korban',
                  Colors.orange,
                  'Sedang',
                  requiredVolunteers['medic'] ?? 0,
                  (signedVolunteers['medic'] as List?)?.length ?? 0,
                  userSkills.contains('P3K & Kesehatan'),
                ),
                
                _buildRoleCard(
                  'Evakuasi & Bantuan Umum',
                  'Membantu evakuasi korban, bantuan umum, koordinasi lapangan',
                  Colors.red,
                  'Tinggi',
                  requiredVolunteers['general'] ?? 0,
                  (signedVolunteers['general'] as List?)?.length ?? 0,
                  userSkills.contains('Bantuan Umum'),
                ),

                SizedBox(height: 20),

                // Event briefing section
                Container(
                  color: Color(0xFFE8F4F8),
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text(
                        '📹 Briefing Keselamatan (Wajib)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        color: Colors.black,
                        height: 60,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow, color: Colors.white, size: 30),
                              SizedBox(width: 8),
                              Text(
                                'Video Keselamatan (2 menit)',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Pastikan Anda menonton briefing keselamatan sebelum bergabung',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                // Schedule and meeting point
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📅 Informasi Kegiatan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('⏰ Jadwal: Hari ini, 14:00 – 18:00'),
                      Text('📍 Berkumpul: Posko ${location['city']}'),
                      Text('👥 Koordinator: Akan diberitahu setelah registrasi'),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _registerForEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedRole != null ? Colors.red[700] : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Mendaftar...'),
                            ],
                          )
                        : Text(
                            selectedRole != null 
                                ? 'Daftar Sebagai $selectedRole' 
                                : 'Pilih Peran Terlebih Dahulu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String desc, Color riskColor, String riskText, 
                       int required, int signed, bool hasSkill) {
    bool isAvailable = signed < required;
    bool isSelected = selectedRole == title;
    
    return Card(
      color: isSelected 
          ? riskColor.withOpacity(0.3) 
          : (isAvailable ? riskColor.withOpacity(0.1) : Colors.grey[100]),
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                title, 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.black : Colors.grey,
                ),
              ),
            ),
            if (hasSkill) ...[
              Icon(Icons.star, color: Colors.amber, size: 16),
              SizedBox(width: 4),
            ],
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAvailable ? riskColor : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAvailable ? '$signed/$required' : 'Penuh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(desc),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Risiko: $riskText',
                  style: TextStyle(
                    fontSize: 12,
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasSkill) ...[
                  SizedBox(width: 10),
                  Text(
                    '⭐ Sesuai keahlian Anda',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: isAvailable ? () {
          setState(() {
            selectedRole = isSelected ? null : title;
          });
        } : null,
        selected: isSelected,
        enabled: isAvailable,
        trailing: isSelected 
            ? Icon(Icons.check_circle, color: riskColor)
            : (isAvailable ? Icon(Icons.radio_button_unchecked) : Icon(Icons.block, color: Colors.grey)),
      ),
    );
  }
}