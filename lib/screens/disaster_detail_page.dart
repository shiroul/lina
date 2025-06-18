import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DisasterDetailPage extends StatelessWidget {
  final String eventId;
  const DisasterDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double cardW = w > 500 ? 450 : w * 0.9;
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(title: Text('Detail Bencana')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: cardW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(width: 3, color: Colors.black)),
            child: FutureBuilder<DocumentSnapshot>(
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
                final coords = location['coordinates'];
                LatLng? latLng;
                if (coords != null && coords.latitude != null && coords.longitude != null) {
                  latLng = LatLng(coords.latitude, coords.longitude);
                }
                final requiredVolunteers = data['requiredVolunteers'] as Map<String, dynamic>? ?? {};
                final ts = data['reportedAt'] as Timestamp?;
                final timeStr = ts != null ? _timeAgo(ts.toDate()) : '-';
                final media = data['media'] as List?;
                String? photoUrl;
                if (media != null && media.isNotEmpty && media.first is String) {
                  photoUrl = media.first;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (latLng != null)
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 200,
                            margin: EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FlutterMap(
                                options: MapOptions(
                                  center: latLng,
                                  zoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: latLng,
                                        width: 40,
                                        height: 40,
                                        child: Icon(Icons.location_on, color: Colors.red, size: 40),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.directions),
                              label: Text('Buka di Maps'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                              onPressed: () async {
                                final url = 'https://www.google.com/maps/search/?api=1&query=${latLng!.latitude},${latLng.longitude}';
                                final uri = Uri.parse(url);
                                try {
                                  final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  if (!success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Tidak dapat membuka aplikasi peta.')),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Tidak dapat membuka aplikasi peta.')),
                                  );
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 180,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                          image: DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 180,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: Center(child: Icon(Icons.photo, size: 48, color: Colors.grey)),
                      ),
                    Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    SizedBox(height: 8),
                    Text('Lokasi: $city, $province'),
                    if (coords != null) Text('Koordinat: ${coords.latitude}, ${coords.longitude}'),
                    SizedBox(height: 8),
                    Text('Waktu: $timeStr'),
                    SizedBox(height: 12),
                    Text('Detail:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(details),
                    SizedBox(height: 12),
                    Text('Kebutuhan Relawan:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...requiredVolunteers.entries.map((e) => Text('• ${e.value} ${e.key}')), 
                  ],
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
