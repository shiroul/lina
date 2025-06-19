import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_profile.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  File? _image;
  bool isLoading = false;
  List<String> skills = [];
  String emergencyContact = '';
  final picker = ImagePicker();

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future uploadProfile() async {
    if (skills.isEmpty) return;
    setState(() => isLoading = true);
    try {
      // Ask for location permission
      final permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin lokasi diperlukan untuk melanjutkan.')),
        );
        setState(() => isLoading = false);
        return;
      }

      // Upload profile image
      String imgUrl = '';
      if (_image != null) {
        final ref = FirebaseStorage.instance.ref().child('profiles/${DateTime.now().millisecondsSinceEpoch}_${_image!.path.split('/').last}');
        await ref.putFile(_image!);
        imgUrl = await ref.getDownloadURL();
      }

      // Get current user and location
      final user = FirebaseAuth.instance.currentUser!;
      final position = await Geolocator.getCurrentPosition();

      // Construct and save the user profile
      final profile = UserProfile(
        uid: user.uid,
        name: user.displayName ?? 'Nama Tidak Diketahui',
        age: 25, // Replace
        gender: 'm', // Replace
        phone: emergencyContact,
        skills: skills,
        lastLocation: GeoPoint(position.latitude, position.longitude),
        profileImageUrl: imgUrl.isNotEmpty ? imgUrl : null,
      );
      await UserProfile.saveToFirestore(profile);
      // Simpan keahlian dan kontak darurat ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'skills': skills,
        'emergencyContact': emergencyContact,
        if (imgUrl.isNotEmpty) 'profileImageUrl': imgUrl,
      });

      Navigator.pushReplacementNamed(context, '/notification');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    double w = MediaQuery.of(c).size.width;
    double containerW = w > 500 ? 400 : w * 0.9;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(title: Text('Lengkapi Profil Anda')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: containerW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(width: 3, color: Colors.black)),
            child: Column(children: [
              LinearProgressIndicator(value: 2 / 5),
              SizedBox(height: 20),
              GestureDetector(onTap: pickImage, child: _image == null ? Icon(Icons.photo_camera, size: 80) : Image.file(_image!, height: 100)),
              SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: Text('Keahlian Anda:', style: TextStyle(fontWeight: FontWeight.bold))),
              Wrap(
                spacing: 10,
                children: ['P3K & Kesehatan', 'Logistik & Distribusi', 'Dokumentasi', 'Bantuan Umum']
                    .map((s) => FilterChip(
                          label: Text(s),
                          selected: skills.contains(s),
                          onSelected: (val) => setState(() => val ? skills.add(s) : skills.remove(s)),
                        ))
                    .toList(),
              ),
              SizedBox(height: 20),
              TextField(decoration: InputDecoration(labelText: 'Kontak Darurat'), keyboardType: TextInputType.phone, onChanged: (v) => emergencyContact = v),
              SizedBox(height: 20),
              ElevatedButton(onPressed: isLoading ? null : uploadProfile, child: isLoading ? CircularProgressIndicator() : Text('Lanjutkan')),
            ]),
          ),
        ),
      ),
    );
  }
}
