import 'dart:io';
import 'package:capstone_fe/common/app_router.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/user/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (kakaoNativeAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.notoSansKrTextTheme(
      Theme.of(context).textTheme,
    );
    const emojiFallback = [
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Noto Color Emoji',
    ];

    return MaterialApp(
      title: '다이버바',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        platform: Platform.isIOS ? TargetPlatform.iOS : TargetPlatform.android,
        textTheme: baseTextTheme.apply(fontFamilyFallback: emojiFallback),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.PRIMARYCOLOR,
          circularTrackColor: AppColors.BORDER_COLOR,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
