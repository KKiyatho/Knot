import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'knot_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KnotFirebaseService.instance.initialize();
  runApp(const KnotApp());
}
