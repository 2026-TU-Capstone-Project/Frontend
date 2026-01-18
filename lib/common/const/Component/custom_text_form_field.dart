
import 'package:flutter/material.dart';

import '../colors.dart';

class CustomTextFormField extends StatelessWidget {
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool autoFocus;
  final ValueChanged<String>? onChanged;
  const CustomTextFormField({
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.autoFocus = false,
    required this.onChanged,
    super.key});

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.grey,
      width: 2.5,
    ),
    );
    return TextFormField(
      cursorColor: Colors.grey,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(20),

        hintText: hintText,
        hintStyle: TextStyle(
          color:  BODY_COLOR,
          fontSize: 14.0,
        ),
        fillColor: INPUT_BG_COLOR,
        filled: true,
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(borderSide: baseBorder.borderSide.copyWith(color: PRIMARYCOLOR))
      ),
    );
  }
}
