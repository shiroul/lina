import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double cardW = w > 500 ? 450 : w * 0.9;

    String? selectedRole;

    Widget roleCard(String title, String desc, Color riskColor, String riskText) {
      return Card(
        color: riskColor.withOpacity(0.2),
        child: ListTile(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(desc),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: riskColor), borderRadius: BorderRadius.circular(4)),
            child: Text(riskText, style: TextStyle(fontSize: 10)),
          ),
          onTap: () {
            selectedRole = title;
            // Trigger rebuild to show selection (if needed)
            (context as Element).markNeedsBuild();
          },
          selected: selectedRole == title,
          selectedTileColor: riskColor.withOpacity(0.3),
        ),
      );
    }

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
            child: Column(children: [
              Text('Pilih Peran Sesuai Kemampuan', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 15),
              roleCard('Bantuan Logistik', 'Distribusi bantuan, mengatur barang', Colors.green, 'Rendah'),
              roleCard('P3K & Kesehatan ✓', 'Pertolongan pertama, bantuan medis', Colors.orange, 'Sedang'),
              roleCard('Evakuasi', 'Membantu mengevakuasi korban', Colors.red, 'Tinggi'),
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
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && selectedRole != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': selectedRole});
                    Navigator.pushNamed(context, '/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilih salah satu peran terlebih dahulu.')));
                  }
                },
                child: Text('Ikut Sekarang'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
