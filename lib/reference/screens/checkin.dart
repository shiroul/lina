import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  _CheckinPageState createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool checkedIn = false;
  bool isLoading = false;
  Position? position;
  Map<String, dynamic>? userEventData;
  Map<String, dynamic>? eventData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserEventData();
  }

  Future<void> _loadUserEventData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get user's current event registration
      final registrationQuery = await FirebaseFirestore.instance
          .collection('volunteerRegistrations')
          .where('volunteerId', isEqualTo: user.uid)
          .where('status', whereIn: ['registered', 'checked-in'])
          .orderBy('registeredAt', descending: true)
          .limit(1)
          .get();

      if (registrationQuery.docs.isNotEmpty) {
        final registrationData = registrationQuery.docs.first.data();
        setState(() {
          userEventData = registrationData;
          checkedIn = registrationData['status'] == 'checked-in';
        });

        // Get event details
        final eventDoc = await FirebaseFirestore.instance
            .collection('activeEvents')
            .doc(registrationData['eventId'])
            .get();

        if (eventDoc.exists) {
          setState(() {
            eventData = eventDoc.data();
          });
        }
      } else {
        setState(() {
          errorMessage = 'Anda belum terdaftar untuk event aktif';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
      });
    }

    // Get current location
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'Layanan lokasi tidak aktif';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'Izin lokasi ditolak';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'Izin lokasi ditolak permanen. Aktifkan di pengaturan.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        position = pos;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal mendapatkan lokasi: $e';
      });
    }
  }

  Future<void> _performCheckin() async {
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lokasi belum tersedia')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || userEventData == null) return;

    setState(() => isLoading = true);

    try {
      // Update registration status to checked-in
      final registrationQuery = await FirebaseFirestore.instance
          .collection('volunteerRegistrations')
          .where('volunteerId', isEqualTo: user.uid)
          .where('eventId', isEqualTo: userEventData!['eventId'])
          .get();

      for (var doc in registrationQuery.docs) {
        await doc.reference.update({
          'status': 'checked-in',
          'checkinAt': FieldValue.serverTimestamp(),
          'checkinLocation': GeoPoint(position!.latitude, position!.longitude),
        });
      }

      // Create check-in record
      await FirebaseFirestore.instance.collection('checkins').add({
        'volunteerId': user.uid,
        'eventId': userEventData!['eventId'],
        'checkinAt': FieldValue.serverTimestamp(),
        'location': GeoPoint(position!.latitude, position!.longitude),
        'role': userEventData!['role'],
      });

      setState(() {
        checkedIn = true;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal check-in: $e')),
      );
    }
  }

  Future<void> _callCoordinator() async {
    const phoneNumber = 'tel:+628123456790';
    try {
      if (await canLaunchUrl(Uri.parse(phoneNumber))) {
        await launchUrl(Uri.parse(phoneNumber));
      } else {
        throw 'Could not launch $phoneNumber';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat menghubungi: $e')),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    const whatsappUrl = 'https://wa.me/628123456790?text=Halo,%20saya%20relawan%20dari%20aplikasi%20LINA';
    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka WhatsApp: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double containerW = w > 500 ? 450 : w * 0.9;

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        appBar: AppBar(title: Text('Check-in Posko')),
        body: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (errorMessage!.contains('belum terdaftar')) {
                      Navigator.pushNamed(context, '/allEvents');
                    } else {
                      _loadUserEventData();
                    }
                  },
                  child: Text(errorMessage!.contains('belum terdaftar') 
                      ? 'Lihat Event Tersedia' 
                      : 'Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (userEventData == null || eventData == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        appBar: AppBar(title: Text('Check-in Posko')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final location = eventData!['location'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Check-in Posko'),
        backgroundColor: checkedIn ? Colors.green[700] : Colors.blue[700],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: containerW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 3, color: Colors.black),
            ),
            child: Column(
              children: [
                Text(
                  'Check-in Posko ${location['city']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 15),

                // Event info
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
                        '📋 Info Event',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('🆘 ${eventData!['type']}'),
                      Text('📍 ${location['city']}, ${location['province']}'),
                      Text('👤 Peran: ${_getRoleDisplayName(userEventData!['role'])}'),
                    ],
                  ),
                ),
                SizedBox(height: 15),

                // Status card
                Container(
                  color: checkedIn ? Color(0xFFE8F5E8) : Color(0xFFFFF3CD),
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Icon(
                        checkedIn ? Icons.check_circle : Icons.schedule,
                        color: checkedIn ? Colors.green : Colors.orange,
                        size: 40,
                      ),
                      SizedBox(height: 10),
                      Text(
                        checkedIn ? '✅ Anda sudah check-in' : '⏳ Belum check-in',
                        style: TextStyle(
                          color: checkedIn ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      if (checkedIn) ...[
                        Text('Status: Aktif di lapangan'),
                        Text('Waktu check-in: ${DateTime.now().toString().substring(0, 16)}'),
                      ] else ...[
                        Text('Silakan lakukan check-in untuk memulai tugas'),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 15),

                // Digital badge (if checked in)
                if (checkedIn) ...[
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🏷️ Badge Digital Relawan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'ID: #REL${userEventData!['eventId'].substring(0, 6).toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text('Peran: ${_getRoleDisplayName(userEventData!['role'])}'),
                              Text('Status: Aktif'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                ],

                // Location status
                Container(
                  height: 100,
                  color: Color(0xFFE8F4F8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          position != null ? Icons.location_on : Icons.location_searching,
                          color: position != null ? Colors.green : Colors.orange,
                          size: 30,
                        ),
                        SizedBox(height: 5),
                        Text(
                          position != null 
                              ? 'Lokasi Anda terdeteksi ✓' 
                              : 'Mendapatkan lokasi...',
                          style: TextStyle(fontSize: 12),
                        ),
                        if (position != null) ...[
                          Text(
                            'Lat: ${position!.latitude.toStringAsFixed(4)}, Lng: ${position!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // Coordinator contact
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '📞 Kontak Koordinator',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Pak Basuki - 0812-3456-7890'),
                      Text('Pos Komando Utama'),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _callCoordinator,
                              icon: Icon(Icons.phone),
                              label: Text('Telepon'),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openWhatsApp,
                              icon: Icon(Icons.message),
                              label: Text('WhatsApp'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),

                // Instructions
                if (checkedIn) ...[
                  Container(
                    color: Color(0xFFFFF3CD),
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          '📋 Instruksi Terkini:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Kumpul di area ${_getRoleDisplayName(userEventData!['role'])}. Hubungi koordinator untuk instruksi lebih lanjut.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                ],

                // Main action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading 
                        ? null 
                        : (checkedIn 
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Check-out'),
                                    content: Text('Apakah Anda yakin ingin mengakhiri tugas hari ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushNamed(context, '/history');
                                        },
                                        child: Text('Ya, Selesai'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : _performCheckin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: checkedIn ? Colors.orange : Colors.green,
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
                              Text('Memproses...'),
                            ],
                          )
                        : Text(
                            checkedIn ? 'Selesai Tugas' : 'Check-in Sekarang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 15),

                // Working hours info
                Text(
                  'Waktu kerja: 14:00 – 18:00\n${checkedIn ? "Jangan lupa check-out setelah selesai" : "Pastikan check-in sebelum memulai tugas"}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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