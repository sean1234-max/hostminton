import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:social_game_app/firebase_options.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final provider = AppProvider();
  await provider.load();

  runApp(
    ChangeNotifierProvider.value(value: provider, child: const BadmintonApp()),
  );

  // You may set the permission requests to "provisional" which allows the user to choose what type
  // of notifications they would like to receive once the user receives a notification.
  final notificationSettings =
      await FirebaseMessaging.instance.requestPermission(provisional: true);

  // For apple platforms, make sure the APNS token is available before making any FCM plugin API calls
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    // APNS token is available, make FCM plugin API requests...
    print("FCM Token: " + token);
  }
}

class BadmintonApp extends StatelessWidget {
  const BadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Badminton Host Finance',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
