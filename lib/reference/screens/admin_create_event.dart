import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/disaster_event.dart';

class AdminCreateEventPage extends StatefulWidget {
  const AdminCreateEventPage({super.key});

  @override
  _AdminCreateEventPageState createState() => _AdminCreateEventPageState();
}

class _AdminCreateEventPageState extends State<AdminCreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  String type = '', details = '', city = '', province = '';
  int general = 0, medic = 0, logistics = 0;
  GeoPoint? coordinates;
  bool isSubmitting = false;

  Future<void> getLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      coordinates = GeoPoint(pos.latitude, pos.longitude);
    });
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate() || coordinates == null) return;
    setState(() => isSubmitting = true);
    final event = DisasterEvent(
      type: type,
      details: details,
      coordinates: coordinates!,
      city: city,
      province: province,
      requiredVolunteers: {
        'general': general,
        'medic': medic,
        'logistics': logistics,
      },
    );
    await event.save();
    setState(() => isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event created!')));
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buat Event Bencana')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(decoration: InputDecoration(labelText: 'Tipe Bencana'), onChanged: (v) => type = v, validator: (v) => v!.isEmpty ? 'Wajib' : null),
            TextFormField(decoration: InputDecoration(labelText: 'Detail Bencana'), onChanged: (v) => details = v, validator: (v) => v!.isEmpty ? 'Wajib' : null),
            TextFormField(decoration: InputDecoration(labelText: 'Kota'), onChanged: (v) => city = v, validator: (v) => v!.isEmpty ? 'Wajib' : null),
            TextFormField(decoration: InputDecoration(labelText: 'Provinsi'), onChanged: (v) => province = v, validator: (v) => v!.isEmpty ? 'Wajib' : null),
            SizedBox(height: 10),
            Text('Jumlah Relawan Dibutuhkan'),
            TextFormField(decoration: InputDecoration(labelText: 'Umum'), keyboardType: TextInputType.number, onChanged: (v) => general = int.parse(v)),
            TextFormField(decoration: InputDecoration(labelText: 'P3K'), keyboardType: TextInputType.number, onChanged: (v) => medic = int.parse(v)),
            TextFormField(decoration: InputDecoration(labelText: 'Logistik'), keyboardType: TextInputType.number, onChanged: (v) => logistics = int.parse(v)),
            SizedBox(height: 20),
            coordinates == null ? CircularProgressIndicator() : Text('📍 Lokasi: ${coordinates!.latitude}, ${coordinates!.longitude}'),
            SizedBox(height: 20),
            ElevatedButton(onPressed: isSubmitting ? null : submit, child: Text('Buat Event')),
          ]),
        ),
      ),
    );
  }
}
