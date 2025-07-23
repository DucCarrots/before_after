import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../before_after.dart';

class SliderPainter extends ChangeNotifier implements CustomPainter {
  SliderPainter({
    required Animation<double> overlayAnimation,
    ValueSetter<Rect>? onThumbRectChanged,
  })  : _overlayAnimation = overlayAnimation,
        _onThumbRectChanged = onThumbRectChanged {
    _overlayAnimation.addListener(notifyListeners);
  }

  final Animation<double> _overlayAnimation;

  final ValueSetter<Rect>? _onThumbRectChanged;

  SliderDirection get axis => _axis!;
  SliderDirection? _axis;

  set axis(SliderDirection value) {
    if (_axis != value) {
      _axis = value;
      notifyListeners();
    }
  }

  double get value => _value!;
  double? _value;

  set value(double value) {
    if (_value != value) {
      _value = value;
      notifyListeners();
    }
  }

  double get trackWidth => _trackWidth!;
  double? _trackWidth;

  set trackWidth(double value) {
    if (_trackWidth != value) {
      _trackWidth = value;
      notifyListeners();
    }
  }

  Color get trackColor => _trackColor!;
  Color? _trackColor;

  set trackColor(Color value) {
    if (_trackColor != value) {
      _trackColor = value;
      notifyListeners();
    }
  }

  double get thumbValue => _thumbValue!;
  double? _thumbValue;

  set thumbValue(double value) {
    if (_thumbValue != value) {
      _thumbValue = value;
      notifyListeners();
    }
  }

  double get thumbWidth => _thumbWidth!;
  double? _thumbWidth;

  set thumbWidth(double value) {
    if (_thumbWidth != value) {
      _thumbWidth = value;
      notifyListeners();
    }
  }

  double get thumbHeight => _thumbHeight!;
  double? _thumbHeight;

  set thumbHeight(double value) {
    if (_thumbHeight != value) {
      _thumbHeight = value;
      notifyListeners();
    }
  }

  Color get overlayColor => _overlayColor!;
  Color? _overlayColor;

  set overlayColor(Color value) {
    if (_overlayColor != value) {
      _overlayColor = value;
      notifyListeners();
    }
  }

  BoxDecoration get thumbDecoration => _thumbDecoration!;
  BoxDecoration? _thumbDecoration;

  set thumbDecoration(BoxDecoration? value) {
    if (_thumbDecoration != value) {
      _thumbDecoration = value;

      _thumbPainter?.dispose();
      _thumbPainter = null;

      notifyListeners();
    }
  }

  ImageConfiguration get configuration => _configuration!;
  ImageConfiguration? _configuration;

  set configuration(ImageConfiguration value) {
    if (_configuration != value) {
      _configuration = value;
      notifyListeners();
    }
  }

  bool get hideThumb => _hideThumb!;
  bool? _hideThumb;

  set hideThumb(bool value) {
    if (_hideThumb != value) {
      _hideThumb = value;
      notifyListeners();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final isHorizontal = axis == SliderDirection.horizontal;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = trackWidth;

    if (hideThumb) {
      return canvas.drawLine(
        Offset(
          isHorizontal ? size.width * value : 0.0,
          isHorizontal ? 0.0 : size.height * value,
        ),
        Offset(
          isHorizontal ? size.width * value : size.width,
          isHorizontal ? size.height : size.height * value,
        ),
        trackPaint,
      );
    }

    canvas
      ..drawLine(
        Offset(
          isHorizontal ? size.width * value : 0.0,
          isHorizontal ? 0.0 : size.height * value,
        ),
        Offset(
          isHorizontal
              ? size.width * value
              : size.width * thumbValue - (thumbHeight / 2),
          isHorizontal
              ? size.height * thumbValue - (thumbHeight / 2)
              : size.height * value,
        ),
        trackPaint,
      )
      ..drawLine(
        Offset(
          isHorizontal
              ? size.width * value
              : size.width * thumbValue + thumbHeight / 2,
          isHorizontal
              ? size.height * thumbValue + thumbHeight / 2
              : size.height * value,
        ),
        Offset(
          isHorizontal ? size.width * value : size.width,
          isHorizontal ? size.height : size.height * value,
        ),
        trackPaint,
      );

    final thumbRect = Rect.fromCenter(
      center: Offset(
        isHorizontal ? size.width * value : size.width * thumbValue,
        isHorizontal ? size.height * thumbValue : size.height * value,
      ),
      width: isHorizontal ? thumbWidth : thumbHeight,
      height: isHorizontal ? thumbHeight : thumbWidth,
    );

    _onThumbRectChanged?.call(thumbRect);

    if (!_overlayAnimation.isDismissed) {
      const lengthMultiplier = 2;

      final overlayRect = Rect.fromCenter(
        center: thumbRect.center,
        width: thumbRect.width * lengthMultiplier * _overlayAnimation.value,
        height: thumbRect.height * lengthMultiplier * _overlayAnimation.value,
      );

      _drawOverlay(canvas, overlayRect);
    }

    _drawThumb(canvas, thumbRect);
  }

  void _drawOverlay(Canvas canvas, Rect overlayRect) {
    Path? overlayPath;
    switch (thumbDecoration.shape) {
      case BoxShape.circle:
        final Offset center = overlayRect.center;
        final double radius = overlayRect.shortestSide / 2.0;
        final Rect square = Rect.fromCircle(center: center, radius: radius);
        overlayPath = Path()..addOval(square);
        break;
      case BoxShape.rectangle:
        if (thumbDecoration.borderRadius == null ||
            thumbDecoration.borderRadius == BorderRadius.zero) {
          overlayPath = Path()..addRect(overlayRect);
        } else {
          overlayPath = Path()
            ..addRRect(thumbDecoration.borderRadius!
                .resolve(configuration.textDirection)
                .toRRect(overlayRect));
        }
        break;
    }

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);
  }

  bool _isPainting = false;

  void _handleThumbChange() {
    if (!_isPainting) {
      notifyListeners();
    }
  }

  BoxPainter? _thumbPainter;

  void _drawThumb(Canvas canvas, Rect thumbRect) {
    try {
      _isPainting = true;
      if (_thumbPainter == null) {
        _thumbPainter?.dispose();
        _thumbPainter = thumbDecoration.createBoxPainter(_handleThumbChange);
      }
      final config = configuration.copyWith(size: thumbRect.size);
      _thumbPainter!.paint(canvas, thumbRect.topLeft, config);
    } finally {
      _isPainting = false;
    }
  }

  @override
  void dispose() {
    _thumbPainter?.dispose();
    _thumbPainter = null;
    _overlayAnimation.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  bool shouldRepaint(covariant SliderPainter oldDelegate) => false;

  @override
  bool? hitTest(Offset position) => null;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}
