import 'package:flutter/material.dart';

/// 전역 네비게이션 키. 401 시 세션 만료 처리 후 로그인 화면으로 이동할 때 사용.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
