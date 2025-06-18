import 'package:flutter/material.dart';

class DisasterDetailPage extends StatelessWidget {
  const DisasterDetailPage({super.key});

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
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 3, color: Colors.black),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🆘 Banjir Jakarta Timur',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                detailRow('📛 Tipe Bencana:', 'Banjir'),
                detailRow('⏰ Waktu Dilaporkan:', '10 Juni 2025 - 14:00 WIB'),
                detailRow('📄 Detail Tambahan:',
                    'Ketinggian air mencapai 50cm, rumah warga terendam di RW 03 dan RW 07. Dibutuhkan evakuasi dan logistik.'),
                detailRow('📍 Lokasi:',
                    'Koordinat: -6.2146, 106.8451\nKota: Jakarta Timur\nProvinsi: DKI Jakarta'),
                SizedBox(height: 20),
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Color(0xFFE8F4F8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 40),
                        SizedBox(height: 8),
                        Text('Peta Lokasi Bencana (MapView placeholder)', style: TextStyle(fontSize: 12)),
                      ],
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
}
