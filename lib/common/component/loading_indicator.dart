import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  const LoadingIndicator({
    super.key,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'asset/json/default_Loading.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
