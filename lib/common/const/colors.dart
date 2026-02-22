import 'package:flutter/material.dart';

class AppColors {
  // --------------------------------------------------------------------------
  // 1. Brand Colors (메인 컬러)
  // --------------------------------------------------------------------------
  /// 메인 컬러 (Charcoal Navy) - 요청하신 변수명 유지
  /// 용도: 주요 버튼(CTA), 앱바 타이틀, 활성화된 탭 아이콘
  static const Color PRIMARYCOLOR = Color(0xFF2F343A);

  /// 포인트 컬러 (Soft Blue)
  /// 용도: 링크 텍스트, '선택됨' 상태 표시, 알림 뱃지
  static const Color ACCENT_COLOR = Color(0xFF4A90E2);

  // --------------------------------------------------------------------------
  // 2. Grayscale (무채색 계열 - Cool Grey Tone)
  // --------------------------------------------------------------------------
  /// 가장 어두운 회색 (Almost Black)
  /// 용도: 본문 제목(Title), 강한 강조 텍스트
  static const Color BLACK = Color(0xFF1C1E22);

  /// 짙은 회색 (기존 BODY_COLOR 대응)
  /// 용도: 본문 내용, 일반 텍스트
  static const Color BODY_COLOR = Color(0xFF565C66);

  /// 중간 회색
  /// 용도: 부가 설명, 날짜, 비활성화된 텍스트
  static const Color MEDIUM_GREY = Color(0xFF8D949E);

  /// 옅은 회색 (기존 BORDER_COLOR 대응)
  /// 용도: 텍스트 필드 테두리, 카드 테두리, 구분선(Divider)
  static const Color BORDER_COLOR = Color(0xFFE5E7EB);

  /// 아주 옅은 회색 (기존 INPUT_BG_COLOR 대응)
  /// 용도: 텍스트 필드 배경, 보조 배경색
  static const Color INPUT_BG_COLOR = Color(0xFFF8F9FA);

  /// 순수 흰색
  /// 용도: 메인 배경, 카드 배경
  static const Color white = Color(0xFFFFFFFF);

  // --------------------------------------------------------------------------
  // 3. Semantic Colors (상태 표시)
  // --------------------------------------------------------------------------
  static const Color ERROR_COLOR = Color(0xFFE57373);
  static const Color SUCCESS_COLOR = Color(0xFF81C784);
}