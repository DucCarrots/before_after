part of 'before_after.dart';

class TwoDirectionalSlider extends StatefulWidget {
  const TwoDirectionalSlider({
    super.key,
    required this.child,
    this.initialVerticalValue = 0.0,
    this.initialHorizontalValue = 0.0,
    this.onVerticalChangeStart,
    this.onVerticalChanged,
    this.onVerticalChangeEnd,
    this.verticalDivisions,
    this.onHorizontalChangeStart,
    this.onHorizontalChanged,
    this.onHorizontalChangeEnd,
    this.horizontalDivisions,
  });

  final Widget child;

  final double initialVerticalValue;

  final double initialHorizontalValue;

  final ValueChanged<double>? onVerticalChangeStart;

  final ValueChanged<double>? onVerticalChanged;

  final ValueChanged<double>? onVerticalChangeEnd;

  final int? verticalDivisions;

  final ValueChanged<double>? onHorizontalChangeStart;

  final ValueChanged<double>? onHorizontalChanged;

  final ValueChanged<double>? onHorizontalChangeEnd;

  final int? horizontalDivisions;

  @override
  State<TwoDirectionalSlider> createState() => _TwoDirectionalSliderState();
}

class _TwoDirectionalSliderState extends State<TwoDirectionalSlider> {
  late double _currentVerticalDragValue;
  late double _currentHorizontalDragValue;

  bool _active = false;

  double _convertVerticalValue(double value) {
    if (widget.verticalDivisions != null) {
      return _discretizeVertical(value);
    }
    return value;
  }

  double _convertHorizontalValue(double value) {
    if (widget.horizontalDivisions != null) {
      return _discretizeHorizontal(value);
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _currentVerticalDragValue =
        _convertVerticalValue(widget.initialVerticalValue);
    _currentHorizontalDragValue =
        _convertHorizontalValue(widget.initialHorizontalValue);
  }

  @override
  void didUpdateWidget(covariant TwoDirectionalSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVerticalValue != widget.initialVerticalValue) {
      _currentVerticalDragValue =
          _convertVerticalValue(widget.initialVerticalValue);
    }
    if (oldWidget.initialHorizontalValue != widget.initialHorizontalValue) {
      _currentHorizontalDragValue =
          _convertHorizontalValue(widget.initialHorizontalValue);
    }
  }

  bool get isVerticalInteractive => widget.onVerticalChanged != null;

  bool get isHorizontalInteractive => widget.onHorizontalChanged != null;

  bool get isInteractive => isVerticalInteractive || isHorizontalInteractive;

  double _getValueFromVisualPosition(double visualPosition) {
    final textDirection = Directionality.of(context);
    switch (textDirection) {
      case TextDirection.rtl:
        return 1.0 - visualPosition;
      case TextDirection.ltr:
        return visualPosition;
    }
  }

  double _getVerticalValueFromLocalPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    final visualPosition = localPosition.dy / box.size.height;
    return _getValueFromVisualPosition(visualPosition);
  }

  double _getHorizontalValueFromLocalPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    final visualPosition = localPosition.dx / box.size.width;
    return _getValueFromVisualPosition(visualPosition);
  }

  double _discretizeVertical(double value) {
    double result = clampDouble(value, 0.0, 1.0);
    if (widget.verticalDivisions != null) {
      final divisions = widget.verticalDivisions!;
      result = (result * divisions).round() / divisions;
    }
    return result;
  }

  double _discretizeHorizontal(double value) {
    double result = clampDouble(value, 0.0, 1.0);
    if (widget.horizontalDivisions != null) {
      final divisions = widget.horizontalDivisions!;
      result = (result * divisions).round() / divisions;
    }
    return result;
  }

  void _updateAndCallHorizontalChanged(double value) {
    _currentHorizontalDragValue = value;
    widget.onHorizontalChanged?.call(value);
  }

  void _updateAndCallVerticalChanged(double value) {
    _currentVerticalDragValue = value;
    widget.onVerticalChanged?.call(value);
  }

  void _startInteraction(Offset globalPosition) {
    if (!_active && isInteractive) {
      _active = true;
      final vValue = _discretizeVertical(_currentVerticalDragValue);
      widget.onVerticalChangeStart?.call(vValue);

      final hValue = _discretizeHorizontal(_currentHorizontalDragValue);
      widget.onHorizontalChangeStart?.call(hValue);

      return _handleGesture(globalPosition);
    }
  }

  void _endInteraction() {
    if (!mounted) return;

    if (_active && mounted) {
      final vValue = _discretizeVertical(_currentVerticalDragValue);
      widget.onVerticalChangeEnd?.call(vValue);

      final hValue = _discretizeHorizontal(_currentHorizontalDragValue);
      widget.onHorizontalChangeEnd?.call(hValue);

      _active = false;
    }
  }

  void _onTapDown(TapDownDetails details) =>
      _startInteraction(details.globalPosition);

  void _onTapUp(TapUpDetails details) => _endInteraction();

  void _onPanStart(DragStartDetails details) =>
      _startInteraction(details.globalPosition);

  void _onPanUpdate(DragUpdateDetails details) =>
      _handleGesture(details.globalPosition);

  void _onPanEnd(DragEndDetails details) => _endInteraction();

  void _handleGesture(Offset globalPosition) {
    if (!mounted) return;

    if (isVerticalInteractive) {
      final value = _getVerticalValueFromLocalPosition(globalPosition);
      _updateAndCallVerticalChanged(_discretizeVertical(value));
    }

    if (isHorizontalInteractive) {
      final value = _getHorizontalValueFromLocalPosition(globalPosition);
      _updateAndCallHorizontalChanged(_discretizeHorizontal(value));
    }
  }

  double get _adjustmentUnit {
    final platform = Theme.of(context).platform;
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 0.1;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 0.05;
    }
  }

  double get _semanticHorizontalActionUnit {
    final divisions = widget.horizontalDivisions;
    return divisions != null ? 1.0 / divisions : _adjustmentUnit;
  }

  double get _semanticVerticalActionUnit {
    final divisions = widget.verticalDivisions;
    return divisions != null ? 1.0 / divisions : _adjustmentUnit;
  }

  void _increaseHorizontalAction() {
    if (isHorizontalInteractive) {
      final value = _currentHorizontalDragValue;
      _updateAndCallHorizontalChanged(
        clampDouble(value + _semanticHorizontalActionUnit, 0.0, 1.0),
      );
    }
  }

  void _decreaseHorizontalAction() {
    if (isHorizontalInteractive) {
      final value = _currentHorizontalDragValue;
      _updateAndCallHorizontalChanged(
        clampDouble(value - _semanticHorizontalActionUnit, 0.0, 1.0),
      );
    }
  }

  void _increaseVerticalAction() {
    if (isVerticalInteractive) {
      final value = _currentVerticalDragValue;
      _updateAndCallVerticalChanged(
        clampDouble(value + _semanticVerticalActionUnit, 0.0, 1.0),
      );
    }
  }

  void _decreaseVerticalAction() {
    if (isVerticalInteractive) {
      final value = _currentVerticalDragValue;
      _updateAndCallVerticalChanged(
        clampDouble(value - _semanticVerticalActionUnit, 0.0, 1.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: widget.child,
    );
  }
}
