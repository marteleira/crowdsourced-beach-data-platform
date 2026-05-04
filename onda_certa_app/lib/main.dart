import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '690249877915-a70cee3ioodj4tv4nqm8ge0mnrs4mmh0.apps.googleusercontent.com',
  );
  runApp(const ProviderScope(child: OndaCertaApp()));
}
