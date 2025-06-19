import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '', phone = '', email = '', password = '';
  bool isLoading = false;

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      // Simpan data registrasi ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.pushReplacementNamed(context, '/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double formWidth = w > 500 ? 400 : w * 0.9;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            width: formWidth,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 3, color: Colors.black),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
            ),
            child: Form(
              key: _formKey,
              child: Column(children: [
                Text('Daftar Relawan Bencana', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                SizedBox(height: 20),
                Image.network(
                  'https://s6.imgcdn.dev/YcODPe.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 15),
                Text('Bergabunglah membantu sesama saat bencana terjadi', textAlign: TextAlign.center),
                SizedBox(height: 20),
                TextFormField(decoration: InputDecoration(labelText: 'Nama Lengkap'), onChanged: (v) => name = v, validator: (v) => v!.isEmpty ? 'Required' : null),
                SizedBox(height: 10),
                TextFormField(decoration: InputDecoration(labelText: 'Nomor Telepon'), keyboardType: TextInputType.phone, onChanged: (v) => phone = v, validator: (v) => v!.isEmpty ? 'Required' : null),
                SizedBox(height: 10),
                TextFormField(decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, onChanged: (v) => email = v, validator: (v) => v!.contains('@') ? null : 'Enter valid email'),
                SizedBox(height: 10),
                TextFormField(obscureText: true, decoration: InputDecoration(labelText: 'Password'), onChanged: (v) => password = v, validator: (v) => v!.length < 6 ? 'Min 6 char' : null),
                SizedBox(height: 20),
                ElevatedButton(onPressed: isLoading ? null : register, child: isLoading ? CircularProgressIndicator() : Text('Daftar Sekarang')),
                SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text('Sudah punya akun? Masuk'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
