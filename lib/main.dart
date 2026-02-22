import 'dart:io';

import 'package:capstone_fe/common/app_router.dart';
import 'package:capstone_fe/user/view/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        platform: Platform.isIOS ? TargetPlatform.iOS : TargetPlatform.android,
      ),
      home: const SplashScreen(),
    );
  }
}
