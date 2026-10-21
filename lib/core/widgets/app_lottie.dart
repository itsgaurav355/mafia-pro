import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLottie extends StatelessWidget {
  final String assetName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final Widget? fallback;

  const AppLottie({
    super.key,
    required this.assetName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.fallback,
  });

  String get _fullPath => assetName.startsWith('assets/')
      ? assetName
      : 'assets/lottie/$assetName.json';

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      _fullPath,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      errorBuilder: (context, error, stackTrace) {
        return fallback ?? SizedBox(width: width, height: height);
      },
    );
  }
}
