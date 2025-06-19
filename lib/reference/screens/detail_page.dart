import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DisasterDetailPage extends StatefulWidget {
  const DisasterDetailPage({super.key});

  @override
  State<DisasterDetailPage> createState() => _DisasterDetailPageState();
}

class _DisasterDetailPageState extends State<DisasterDetailPage> {
  MapController? _mapController;
  Map<String, dynamic>? eventData;
  String? eventId;
  bool isLoading = true;
  List<Marker> markers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments passed from previous screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      eventId = args['eventId'];
      eventData = args['eventData'];
      _setupMap();
    } else {
      // Fallback: load sample data
      _loadSampleData();
    }
    
    setState(() {
      isLoading = false;
    });
  }

  void _setupMap() {
    if (eventData != null && eventData!['location'] != null) {
      final location = eventData!['location'];
      final coordinates = location['coordinates'] as GeoPoint;
      
      markers.add(
        Marker(
          point: LatLng(coordinates.latitude, coordinates.longitude),
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  eventData!['type'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _loadSampleData() {
    // Sample data for testing when no arguments provided
    eventData = {
      'type': 'Banjir Jakarta Timur',
      'details': 'Ketinggian air mencapai 50cm, rumah warga terendam di RW 03 dan RW 07. Dibutuhkan evakuasi dan logistik.',
      'reportedAt': Timestamp.now(),
      'location': {
        'coordinates': GeoPoint(-6.2146, 106.8451),
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
      'severityLevel': 'tinggi',
      'status': 'active',
    };
    eventId = 'sample-event';
    _setupMap();
  }

  void _openInExternalMaps() async {
    if (eventData == null || eventData!['location'] == null) return;
    
    final coordinates = eventData!['location']['coordinates'] as GeoPoint;
    final lat = coordinates.latitude;
    final lng = coordinates.longitude;
    
    // Try multiple map apps
    final List<Map<String, String>> mapOptions = [
      {
        'name': 'Google Maps',
        'url': 'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        'app': 'comgooglemaps://?q=$lat,$lng'
      },
      {
        'name': 'Apple Maps',
        'url': 'https://maps.apple.com/?q=$lat,$lng',
        'app': 'maps://?q=$lat,$lng'
      },
      {
        'name': 'OpenStreetMap',
        'url': 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=15',
        'app': ''
      },
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Buka di Aplikasi Peta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...mapOptions.map((option) => ListTile(
              leading: Icon(Icons.map),
              title: Text(option['name']!),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final appUrl = option['app']!;
                  final webUrl = option['url']!;
                  
                  if (appUrl.isNotEmpty && await canLaunchUrl(Uri.parse(appUrl))) {
                    await launchUrl(Uri.parse(appUrl));
                  } else {
                    await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tidak dapat membuka peta: $e')),
                  );
                }
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double cardW = w > 500 ? 450 : w * 0.9;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        appBar: AppBar(title: Text('Detail Bencana')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (eventData == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        appBar: AppBar(title: Text('Detail Bencana')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Data bencana tidak ditemukan'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final location = eventData!['location'] as Map<String, dynamic>;
    final coordinates = location['coordinates'] as GeoPoint;
    final reportedAt = eventData!['reportedAt'] as Timestamp?;
    final requiredVolunteers = eventData!['requiredVolunteers'] as Map<String, dynamic>;
    final signedVolunteers = eventData!['signedVolunteers'] as Map<String, dynamic>;

    String formattedDate = 'Tidak diketahui';
    if (reportedAt != null) {
      final date = reportedAt.toDate();
      formattedDate = '${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
    }

    // Calculate volunteer statistics
    int totalRequired = (requiredVolunteers['general'] ?? 0) + 
                       (requiredVolunteers['medic'] ?? 0) + 
                       (requiredVolunteers['logistics'] ?? 0);
                       
    int totalSigned = (signedVolunteers['general']?.length ?? 0) + 
                     (signedVolunteers['medic']?.length ?? 0) + 
                     (signedVolunteers['logistics']?.length ?? 0);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Detail Bencana'),
        actions: [
          IconButton(
            onPressed: _openInExternalMaps,
            icon: Icon(Icons.open_in_new),
            tooltip: 'Buka di Aplikasi Peta',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🆘 ${eventData!['type']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                
                // Severity indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(eventData!['severityLevel']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tingkat: ${_getSeverityText(eventData!['severityLevel'])}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                
                detailRow('📛 Tipe Bencana:', eventData!['type']),
                detailRow('⏰ Waktu Dilaporkan:', formattedDate),
                detailRow('📄 Detail Tambahan:', eventData!['details']),
                detailRow('📍 Lokasi:',
                    'Koordinat: ${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}\nKota: ${location['city']}\nProvinsi: ${location['province']}'),
                
                SizedBox(height: 20),
                
                // Volunteer requirements
                Text('👥 Kebutuhan Relawan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),
                
                _volunteerRequirementCard('Bantuan Umum', 
                    requiredVolunteers['general'] ?? 0, 
                    signedVolunteers['general']?.length ?? 0),
                    
                _volunteerRequirementCard('P3K & Medis', 
                    requiredVolunteers['medic'] ?? 0, 
                    signedVolunteers['medic']?.length ?? 0),
                    
                _volunteerRequirementCard('Logistik', 
                    requiredVolunteers['logistics'] ?? 0, 
                    signedVolunteers['logistics']?.length ?? 0),
                
                SizedBox(height: 20),
                
                // Map view with OpenStreetMap (FREE!)
                Text('🗺️ Lokasi pada Peta (OpenStreetMap):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),
                
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: LatLng(coordinates.latitude, coordinates.longitude),
                        zoom: 15.0,
                        maxZoom: 18.0,
                        minZoom: 10.0,
                      ),
                      children: [
                        // OpenStreetMap tiles (FREE!)
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.lina',
                          maxZoom: 19,
                        ),
                        
                        // Disaster markers
                        MarkerLayer(
                          markers: markers,
                        ),
                        
                        // Attribution (required for OpenStreetMap)
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              '© OpenStreetMap contributors',
                              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 10),
                
                // Map action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openInExternalMaps,
                        icon: Icon(Icons.open_in_new),
                        label: Text('Buka di App Peta'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (_mapController != null) {
                            _mapController!.move(
                              LatLng(coordinates.latitude, coordinates.longitude),
                              18.0,
                            );
                          }
                        },
                        icon: Icon(Icons.zoom_in),
                        label: Text('Zoom In'),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 15),
                
                // Alternative map sources info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 Info Peta',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '• Menggunakan OpenStreetMap (100% GRATIS)\n'
                        '• Data peta dari kontributor global\n'
                        '• Tidak memerlukan API key berbayar\n'
                        '• Tap "Buka di App Peta" untuk navigasi',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Action buttons
                if (totalSigned < totalRequired) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/role',
                          arguments: {
                            'eventId': eventId,
                            'eventData': eventData,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text('Bergabung Sebagai Relawan'),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 30),
                        SizedBox(height: 8),
                        Text(
                          'Kebutuhan Relawan Terpenuhi',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Terima kasih atas antusiasme Anda',
                          style: TextStyle(color: Colors.green[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget detailRow(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(content),
      ]),
    );
  }

  Widget _volunteerRequirementCard(String role, int required, int signed) {
    bool isFull = signed >= required;
    Color statusColor = isFull ? Colors.green : Colors.orange;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$signed dari $required relawan'),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isFull ? 'Penuh' : 'Butuh ${required - signed}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'tinggi':
        return Colors.red;
      case 'sedang':
        return Colors.orange;
      case 'rendah':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _getSeverityText(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'tinggi':
        return 'Tinggi';
      case 'sedang':
        return 'Sedang';
      case 'rendah':
        return 'Rendah';
      default:
        return 'Sedang';
    }
  }
}