import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileSkillPage extends StatefulWidget {
  const ProfileSkillPage({super.key});

  @override
  State<ProfileSkillPage> createState() => _ProfileSkillPageState();
}

class _ProfileSkillPageState extends State<ProfileSkillPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '', phone = '', emergencyContact = '';
  List<String> skills = [];
  String? profileImageUrl;
  File? _image;
  bool isLoading = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    setState(() {
      name = data['name'] ?? '';
      phone = data['phone'] ?? '';
      emergencyContact = data['emergencyContact'] ?? '';
      skills = (data['skills'] as List?)?.cast<String>() ?? [];
      profileImageUrl = data['profileImageUrl'];
    });
  }

  @override
  void didUpdateWidget(covariant ProfileSkillPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadProfile();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': name,
      'phone': phone,
      'emergencyContact': emergencyContact,
      'skills': skills,
    });
    setState(() {
      isEditing = false;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double containerW = w > 500 ? 400 : w * 0.9;
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(title: Text('Profil & Keahlian')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: containerW,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(width: 3, color: Colors.black)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: isEditing ? _pickImage : null,
                      child: _image != null
                          ? ClipOval(child: Image.file(_image!, width: 100, height: 100, fit: BoxFit.cover))
                          : (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                              ? ClipOval(child: Image.network(profileImageUrl!, width: 100, height: 100, fit: BoxFit.cover))
                              : CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: TextEditingController(text: name),
                    decoration: InputDecoration(labelText: 'Nama Lengkap'),
                    onChanged: (v) => name = v,
                    validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                    enabled: isEditing,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: TextEditingController(text: phone),
                    decoration: InputDecoration(labelText: 'Nomor Telepon'),
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => phone = v,
                    validator: (v) => v!.isEmpty ? 'Nomor telepon wajib diisi' : null,
                    enabled: isEditing,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: TextEditingController(text: emergencyContact),
                    decoration: InputDecoration(labelText: 'Kontak Darurat'),
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => emergencyContact = v,
                    validator: (v) => v!.isEmpty ? 'Kontak darurat wajib diisi' : null,
                    enabled: isEditing,
                  ),
                  SizedBox(height: 20),
                  Text('Keahlian:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: ['P3K & Kesehatan', 'Logistik & Distribusi', 'Dokumentasi', 'Bantuan Umum']
                        .map((s) => FilterChip(
                              label: Text(s),
                              selected: skills.contains(s),
                              onSelected: isEditing ? (val) => setState(() => val ? skills.add(s) : skills.remove(s)) : null,
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (isEditing) {
                              _saveProfile();
                            } else {
                              setState(() => isEditing = true);
                            }
                          },
                    child: isLoading
                        ? CircularProgressIndicator()
                        : Text(isEditing ? 'Simpan' : 'Edit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
