import 'package:flutter/material.dart';

enum LogoSize { sm, md, lg }

class SpeedLogo extends StatelessWidget {
  final LogoSize size;

  const SpeedLogo({super.key, this.size = LogoSize.md});

  double getDimension() {
    switch (size) {
      case LogoSize.sm:
        return 32; // w-8 h-8 -> 32px
      case LogoSize.md:
        return 48; // w-12 h-12 -> 48px
      case LogoSize.lg:
        return 64; // w-16 h-16 -> 64px
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimension = getDimension();

    return Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/icon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class SpeedLogoWithText extends StatelessWidget {
  final LogoSize size;

  const SpeedLogoWithText({super.key, this.size = LogoSize.md});

  double getFontSize() {
    switch (size) {
      case LogoSize.sm:
        return 14; // text-base
      case LogoSize.md:
        return 18; // text-lg
      case LogoSize.lg:
        return 24; // text-2xl
    }
  }

  double getImageSize() {
    switch (size) {
      case LogoSize.sm:
        return 32;
      case LogoSize.md:
        return 48;
      case LogoSize.lg:
        return 64;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = getImageSize();

    return Image.asset(
      'assets/images/icon.png',
      height: imageSize * 1.5,
      fit: BoxFit.contain,
    );
  }
}
