import 'package:flutter/material.dart';

class EmergencyNotificationPage extends StatelessWidget {
  const EmergencyNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double cardW = w > 500 ? 450 : w * 0.9;
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(title: Text('Peringatan Bencana'), backgroundColor: Colors.red),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: cardW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(width: 3, color: Colors.black)),
            child: Column(children: [
              Container(
                color: Colors.red,
                width: double.infinity,
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 8), Text('PERINGATAN BENCANA', style: TextStyle(color: Colors.white))],
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: Color(0xFFFFE6E6),
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(children: [
                    Text('Banjir di Jakarta Timur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('📍 Kelurahan Cipinang Besar\n⏰ 15 menit yang lalu\n📊 Tinggi: 30‑50 cm'),
                  ]),
                ),
              ),
              SizedBox(height: 15),
              Align(alignment: Alignment.centerLeft, child: Text('Relawan Dibutuhkan:', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(height: 5),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('• 5 orang untuk logistik'),
                Text('• 3 orang untuk P3K'),
                Text('• 10 orang bantuan umum'),
              ]),
              SizedBox(height: 15),
              Container(
                height: 120,
                color: Color(0xFFE8F4F8),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.map, size: 40), Text('Peta Lokasi Bencana', style: TextStyle(fontSize: 10))])),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/role');
                  },
                  child: Text('Ikut Sekarang'),
              ),
              SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/detail'),
                child: Text('Lihat Detail'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text('Tidak Bisa', style: TextStyle(color: Colors.grey)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
