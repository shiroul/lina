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
      title: 'Disaster Volunteer App',
      theme: ThemeData(fontFamily: 'Courier', primarySwatch: Colors.blue),
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
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
