import 'dart:ui';

import 'package:flutter/material.dart';

class BeforeAfterTheme extends ThemeExtension<BeforeAfterTheme> {
  const BeforeAfterTheme({
    this.trackWidth,
    this.trackColor,
    this.thumbHeight,
    this.thumbWidth,
    this.overlayColor,
    this.thumbDecoration,
    this.mouseCursor,
  });

  final double? trackWidth;

  final Color? trackColor;

  final double? thumbHeight;

  final double? thumbWidth;

  final Color? overlayColor;

  final BoxDecoration? thumbDecoration;

  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  static BeforeAfterTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<BeforeAfterTheme>();
    return theme ?? const BeforeAfterTheme();
  }

  @override
  ThemeExtension<BeforeAfterTheme> copyWith({
    double? trackWidth,
    Color? trackColor,
    double? thumbHeight,
    double? thumbWidth,
    Color? overlayColor,
    BoxDecoration? thumbDecoration,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) {
    return BeforeAfterTheme(
      trackWidth: trackWidth ?? this.trackWidth,
      trackColor: trackColor ?? this.trackColor,
      thumbHeight: thumbHeight ?? this.thumbHeight,
      thumbWidth: thumbWidth ?? this.thumbWidth,
      overlayColor: overlayColor ?? this.overlayColor,
      thumbDecoration: thumbDecoration ?? this.thumbDecoration,
      mouseCursor: mouseCursor ?? this.mouseCursor,
    );
  }

  @override
  ThemeExtension<BeforeAfterTheme> lerp(
    covariant BeforeAfterTheme? other,
    double t,
  ) {
    return BeforeAfterTheme(
      trackWidth: lerpDouble(trackWidth, other?.trackWidth, t),
      trackColor: Color.lerp(trackColor, other?.trackColor, t),
      thumbHeight: lerpDouble(thumbHeight, other?.thumbHeight, t),
      thumbWidth: lerpDouble(thumbWidth, other?.thumbWidth, t),
      overlayColor: Color.lerp(overlayColor, other?.overlayColor, t),
      thumbDecoration: BoxDecoration.lerp(
        thumbDecoration,
        other?.thumbDecoration,
        t,
      ),
      mouseCursor: t < 0.5 ? mouseCursor : other?.mouseCursor,
    );
  }

  @override
  int get hashCode =>
      trackWidth.hashCode ^
      trackColor.hashCode ^
      thumbHeight.hashCode ^
      thumbWidth.hashCode ^
      overlayColor.hashCode ^
      thumbDecoration.hashCode ^
      mouseCursor.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeforeAfterTheme &&
          runtimeType == other.runtimeType &&
          trackWidth == other.trackWidth &&
          trackColor == other.trackColor &&
          thumbHeight == other.thumbHeight &&
          thumbWidth == other.thumbWidth &&
          overlayColor == other.overlayColor &&
          thumbDecoration == other.thumbDecoration &&
          mouseCursor == other.mouseCursor;
}
