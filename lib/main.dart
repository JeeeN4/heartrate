import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ble_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INIT FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // INIT HIVE
  await Hive.initFlutter();
  await Hive.openBox('hr_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BlePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}