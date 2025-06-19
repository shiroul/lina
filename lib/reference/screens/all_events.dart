import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllEventsPage extends StatelessWidget {
  const AllEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double containerW = w > 500 ? 450 : w * 0.9;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Semua Misi Bencana'),
        backgroundColor: Colors.red[700],
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
                Text(
                  '🆘 Daftar Bencana Aktif',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activeEvents')
                      .where('status', isEqualTo: 'active')
                      .orderBy('reportedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text('Memuat data bencana...'),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          color: Colors.red[50],
                          child: Column(
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 50),
                              SizedBox(height: 10),
                              Text(
                                'Terjadi kesalahan saat memuat data',
                                style: TextStyle(color: Colors.red),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Refresh by rebuilding widget
                                  (context as Element).markNeedsBuild();
                                },
                                child: Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Container(
                          padding: EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle, 
                                   color: Colors.green, size: 60),
                              SizedBox(height: 15),
                              Text(
                                'Tidak ada bencana aktif',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Semua situasi dalam kondisi aman',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final location = data['location'] as Map<String, dynamic>;
                        final reportedAt = data['reportedAt'] as Timestamp?;
                        final requiredVolunteers = data['requiredVolunteers'] as Map<String, dynamic>;
                        final signedVolunteers = data['signedVolunteers'] as Map<String, dynamic>;
                        
                        // Calculate total required and signed volunteers
                        int totalRequired = (requiredVolunteers['general'] ?? 0) + 
                                          (requiredVolunteers['medic'] ?? 0) + 
                                          (requiredVolunteers['logistics'] ?? 0);
                        
                        int totalSigned = (signedVolunteers['general']?.length ?? 0) + 
                                        (signedVolunteers['medic']?.length ?? 0) + 
                                        (signedVolunteers['logistics']?.length ?? 0);
                        
                        String timeAgo = 'Baru saja';
                        if (reportedAt != null) {
                          final diff = DateTime.now().difference(reportedAt.toDate());
                          if (diff.inDays > 0) {
                            timeAgo = '${diff.inDays} hari lalu';
                          } else if (diff.inHours > 0) {
                            timeAgo = '${diff.inHours} jam lalu';
                          } else if (diff.inMinutes > 0) {
                            timeAgo = '${diff.inMinutes} menit lalu';
                          }
                        }
                        
                        // Determine urgency color
                        Color urgencyColor = Colors.orange;
                        String urgencyText = 'Sedang';
                        if (data['severityLevel'] == 'tinggi') {
                          urgencyColor = Colors.red;
                          urgencyText = 'Tinggi';
                        } else if (data['severityLevel'] == 'rendah') {
                          urgencyColor = Colors.green;
                          urgencyText = 'Rendah';
                        }
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Header with urgency indicator
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: urgencyColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${data['type']} - ${location['city']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: urgencyColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        urgencyText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Event details
                              Padding(
                                padding: EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, 
                                             size: 16, color: Colors.grey[600]),
                                        SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            '${location['city']}, ${location['province']}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, 
                                             size: 16, color: Colors.grey[600]),
                                        SizedBox(width: 5),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      data['details'] ?? 'Tidak ada detail tambahan',
                                      style: TextStyle(fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 15),
                                    
                                    // Volunteer progress
                                    Row(
                                      children: [
                                        Icon(Icons.people, 
                                             size: 16, color: Colors.blue),
                                        SizedBox(width: 5),
                                        Text('Relawan: '),
                                        Text(
                                          '$totalSigned/$totalRequired',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: totalSigned >= totalRequired 
                                                ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: totalRequired > 0 
                                          ? totalSigned / totalRequired : 0,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        totalSigned >= totalRequired 
                                            ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    
                                    // Action buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/detail',
                                                arguments: {
                                                  'eventId': doc.id,
                                                  'eventData': data,
                                                },
                                              );
                                            },
                                            child: Text('Detail'),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: totalSigned >= totalRequired 
                                                ? null 
                                                : () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/role',
                                                      arguments: {
                                                        'eventId': doc.id,
                                                        'eventData': data,
                                                      },
                                                    );
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: totalSigned >= totalRequired 
                                                  ? Colors.grey : Colors.red[700],
                                              foregroundColor: Colors.white,
                                            ),
                                            child: Text(
                                              totalSigned >= totalRequired 
                                                  ? 'Penuh' : 'Bergabung',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
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
}