import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:provider/provider.dart';
import 'screens/registration.dart';
import 'screens/login.dart';
import 'screens/profile_setup.dart';
import 'screens/home.dart';
import 'screens/notification.dart';
import 'screens/detail_page.dart';
import 'screens/admin_create_event.dart';
import 'screens/role_selection.dart';
import 'screens/checkin.dart';
import 'screens/profile_skill.dart';
import 'screens/edit_profile.dart';
import 'screens/all_events.dart';
import 'screens/volunteer_history.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(DisasterVolunteerApp());
}

class DisasterVolunteerApp extends StatelessWidget {
  const DisasterVolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LINA - Peduli Bencana',
      theme: ThemeData(
        fontFamily: 'Courier',
        primarySwatch: Colors.blue,
        // Enhanced theme for better UX
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue[700],
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      routes: {
        '/registration': (_) => RegistrationPage(),
        '/login': (_) => LoginPage(),
        '/profile': (_) => ProfileSetupPage(),
        '/home': (_) => HomePage(),
        '/notification': (_) => EmergencyNotificationPage(),
        '/detail': (_) => DisasterDetailPage(),
        '/createEvent': (_) => AdminCreateEventPage(),
        '/role': (_) => RoleSelectionPage(),
        '/checkin': (_) => CheckinPage(),
        '/profileSkill': (_) => ProfileSkillPage(),
        '/editProfile': (_) => EditProfilePage(),
        '/allEvents': (_) => AllEventsPage(),
        '/history': (_) => VolunteerHistoryPage(),
      },
      debugShowCheckedModeBanner: false,
      // Global error handling
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            backgroundColor: Color(0xFFF5F5F0),
            body: Center(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Terjadi kesalahan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aplikasi mengalami masalah. Silakan restart aplikasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Restart app or navigate to home
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                      child: Text('Kembali ke Beranda'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return widget!;
      },
    );
  }
}