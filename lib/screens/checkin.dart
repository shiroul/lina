import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  _CheckinPageState createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool checkedIn = false;
  Position? position;

  Future getCurrentLocation() async {
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext c) {
    double w = MediaQuery.of(c).size.width;
    double containerW = w > 500 ? 450 : w * 0.9;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(title: Text('Check-in Posko')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: containerW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(width: 3, color: Colors.black)),
            child: Column(children: [
              Text('Check-in Posko Cipinang', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 15),
              Container(
                color: Color(0xFFE8F5E8),
                padding: EdgeInsets.all(15),
                child: Column(children: [
                  Text('✅ Anda sudah terdaftar', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Badge Digital: #REL001234\nPeran: P3K & Kesehatan', style: TextStyle(fontSize: 12)),
                ]),
              ),
              SizedBox(height: 15),
              Container(
                height: 100,
                color: Color(0xFFE8F4F8),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.place),
                    Text(position == null ? 'Mendapatkan lokasi...' : 'Lokasi Anda terdeteksi', style: TextStyle(fontSize: 10)),
                  ]),
                ),
              ),
              SizedBox(height: 15),
              Text('📞 Pak Basuki - 0812‑3456‑7890\nPos Komando Utama', style: TextStyle(fontSize: 12)),
              SizedBox(height: 15),
              Container(
                color: Color(0xFFFFF3CD),
                padding: EdgeInsets.all(10),
                child: Text('Instruksi Terkini:\nKumpul di tenda P3K…', style: TextStyle(fontSize: 12)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => checkedIn = true),
                child: Text(checkedIn ? 'Checked-in' : 'Check-in Sekarang'),
              ),
              SizedBox(height: 10),
              OutlinedButton(onPressed: () {}, child: Text('Hubungi Petugas')),
              SizedBox(height: 15),
              Text('Waktu kerja: 14:00 – 18:00\nPastikan check-out setelah selesai', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ),
        ),
      ),
    );
  }
}
