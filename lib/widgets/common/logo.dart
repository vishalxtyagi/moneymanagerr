import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/enums.dart';

class AppLogo extends StatelessWidget {
  final LogoType type;
  final double size;

  const AppLogo({
    super.key,
    this.type = LogoType.light,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final logoType = type == LogoType.light ? 'light' : 'dark';
    return Image.asset(
      'assets/images/logo_$logoType.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
