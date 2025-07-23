import 'package:flutter/material.dart';

import '../before_after.dart';

class RectClipper extends CustomClipper<Rect> {
  const RectClipper({
    required this.direction,
    required this.clipFactor,
  });

  final SliderDirection direction;

  final double clipFactor;

  @override
  Rect getClip(Size size) {
    final rect = Rect.fromLTWH(
      0.0,
      0.0,
      direction == SliderDirection.horizontal
          ? size.width * clipFactor
          : size.width,
      direction == SliderDirection.vertical
          ? size.height * clipFactor
          : size.height,
    );

    return rect;
  }

  @override
  bool shouldReclip(RectClipper oldClipper) =>
      oldClipper.clipFactor != clipFactor || oldClipper.direction != direction;
}
