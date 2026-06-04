import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app.dart';
import 'core/auth/auth_provider.dart';

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are shown automatically by FCM on Android
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await GoogleSignIn.instance.initialize(
    serverClientId:
        '690249877915-a70cee3ioodj4tv4nqm8ge0mnrs4mmh0.apps.googleusercontent.com',
  );

  final container = ProviderContainer();
  await container.read(fcmServiceProvider).init();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const OndaCertaApp(),
  ));
}
