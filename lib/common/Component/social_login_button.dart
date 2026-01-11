import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialLoginButton extends StatelessWidget {
  final String assetPath;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isBorder;
  const SocialLoginButton({
    required this.assetPath,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
    this.isBorder = false,
    super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            side: BorderSide(
              color: isBorder ? Colors.black : backgroundColor,
            ),
          ),
            onPressed: onPressed ?? (){},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(assetPath),
                ),
                SizedBox(width: 12.0),
                Text( text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500
                ),
                )
              ],
            )
        ),
        SizedBox(height: 15,)
      ],
    );
  }
}
