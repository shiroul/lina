import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}
  
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool isLoading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: screenWidth > 500 ? 400 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 3, color: Colors.black),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text("Masuk Akun Relawan",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  SizedBox(height: 20),
                  Image.network(
                    'https://s6.imgcdn.dev/YcODPe.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 15),
                  Text("Masukkan email dan password Anda", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => email = val,
                    validator: (val) => !val!.contains('@') ? 'Masukkan email valid' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    onChanged: (val) => password = val,
                    validator: (val) => val!.length < 6 ? 'Min 6 karakter' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    ),
                    child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Masuk"),
                  ),
                  SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/registration'),
                    child: Text("Belum punya akun? Daftar", style: TextStyle(fontSize: 10)),
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
