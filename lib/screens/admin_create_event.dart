import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/disaster_event.dart';

class AdminCreateEventPage extends StatefulWidget {
  const AdminCreateEventPage({super.key});

  @override
  _AdminCreateEventPageState createState() => _AdminCreateEventPageState();
}

class _AdminCreateEventPageState extends State<AdminCreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  String type = '', details = '', city = '', province = '';
  GeoPoint? coordinates;
  bool isSubmitting = false;
  String? locationError;
  File? _image;
  String? cityName;
  String? provinceName;

  // Tambahan untuk kategori dan jumlah
  final List<String> categories = [
    'P3K & Kesehatan',
    'Logistik & Distribusi',
    'Dokumentasi',
    'Bantuan Umum',
  ];
  List<String> selectedCategories = [];
  Map<String, int> volunteerCounts = {};

  Future<void> getLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      GeoPoint geo = GeoPoint(pos.latitude, pos.longitude);
      String? city, province;
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        // Cari locality dan administrativeArea yang tidak kosong
        for (final place in placemarks) {
          if ((place.locality != null && place.locality!.isNotEmpty) && (place.administrativeArea != null && place.administrativeArea!.isNotEmpty)) {
            city = place.locality;
            province = place.administrativeArea;
            break;
          }
        }
        // Fallback jika tidak ada locality, ambil subAdministrativeArea
        if ((city == null || city.isEmpty) && placemarks.isNotEmpty) {
          city = placemarks.first.subAdministrativeArea ?? '';
        }
        if ((province == null || province.isEmpty) && placemarks.isNotEmpty) {
          province = placemarks.first.administrativeArea ?? '';
        }
      } catch (e) {
        // Jika gagal reverse geocoding, biarkan city/province kosong
      }
      setState(() {
        coordinates = geo;
        cityName = city;
        provinceName = province;
        locationError = null;
      });
    } catch (e) {
      setState(() {
        locationError = 'Tidak dapat mengambil lokasi. Pastikan GPS aktif dan izin lokasi diberikan.';
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate() || coordinates == null) return;
    setState(() => isSubmitting = true);
    // Pastikan cityName dan provinceName tidak null/kosong
    final String cityFinal = (cityName != null && cityName!.isNotEmpty) ? cityName! : '-';
    final String provinceFinal = (provinceName != null && provinceName!.isNotEmpty) ? provinceName! : '-';
    final event = DisasterEvent(
      type: type,
      details: details,
      coordinates: coordinates!,
      city: cityFinal,
      province: provinceFinal,
      requiredVolunteers: Map<String, int>.from(volunteerCounts),
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
            // UI upload foto lokasi di atas form
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) setState(() => _image = File(picked.path));
              },
              child: _image == null
                  ? Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]),
                            SizedBox(height: 8),
                            Text('Upload Foto Lokasi', style: TextStyle(color: Colors.grey[600]))
                          ],
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_image!, width: double.infinity, height: 160, fit: BoxFit.cover),
                    ),
            ),
            SizedBox(height: 20),
            TextFormField(decoration: InputDecoration(labelText: 'Tipe Bencana'), onChanged: (v) => type = v, validator: (v) => v!.isEmpty ? 'Wajib' : null),
            TextFormField(decoration: InputDecoration(labelText: 'Detail Bencana'), onChanged: (v) => details = v, validator: (v) => v!.isEmpty ? 'Wajib' : null),
            SizedBox(height: 10),
            Text('Kategori & Jumlah Relawan Dibutuhkan', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 10,
              children: categories.map((cat) => FilterChip(
                label: Text(cat),
                selected: selectedCategories.contains(cat),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      selectedCategories.add(cat);
                    } else {
                      selectedCategories.remove(cat);
                      volunteerCounts.remove(cat);
                    }
                  });
                },
              )).toList(),
            ),
            ...selectedCategories.map((cat) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(child: Text(cat)),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Jumlah'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        setState(() {
                          volunteerCounts[cat] = int.tryParse(v) ?? 0;
                        });
                      },
                      validator: (v) {
                        if (selectedCategories.contains(cat) && (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0)) {
                          return 'Isi jumlah';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            )),
            SizedBox(height: 20),
            locationError != null
              ? Text(locationError!, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              : coordinates == null
                ? Text('Mengambil lokasi...')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lokasi: ${cityName ?? '-'}, ${provinceName ?? '-'}'),
                      Text('Koordinat: ${coordinates!.latitude}, ${coordinates!.longitude}'),
                    ],
                  ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: isSubmitting ? null : submit, child: Text('Buat Event')),
          ]),
        ),
      ),
    );
  }
}
