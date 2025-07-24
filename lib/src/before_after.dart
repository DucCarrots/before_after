import 'dart:ui';

import 'package:before_after/src/before_after_theme.dart';
import 'package:before_after/src/rect_clipper.dart';
import 'package:before_after/src/slider_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'two_directional_slider.dart';

const _defaultThumbElevation = 1.0;

enum SliderDirection {
  horizontal,
  vertical,
}

class BeforeAfter extends StatefulWidget {
  const BeforeAfter({
    super.key,
    required this.before,
    required this.after,
    this.height,
    this.width,
    this.trackWidth,
    this.trackColor,
    this.hideThumb = false,
    this.thumbHeight,
    this.thumbWidth,
    this.thumbColor,
    this.overlayColor,
    this.thumbDecoration,
    this.direction = SliderDirection.horizontal,
    this.value = 0.5,
    this.divisions,
    this.onValueChanged,
    this.thumbPosition = 0.5,
    this.thumbDivisions,
    this.onThumbPositionChanged,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.ignorePointer = true,
  });

  final Widget before;

  final Widget after;

  final SliderDirection direction;

  /// The height of the before/after widget container.
  /// If provided, images will be sized to fill this height while maintaining aspect ratio.
  final double? height;

  /// The width of the before/after widget container.
  /// If provided, images will be sized to fill this width while maintaining aspect ratio.
  final double? width;

  final double? trackWidth;

  final Color? trackColor;

  final bool hideThumb;

  final double? thumbHeight;

  final double? thumbWidth;

  final Color? thumbColor;

  final WidgetStateProperty<Color?>? overlayColor;

  final BoxDecoration? thumbDecoration;

  final int? divisions;

  final double value;

  final ValueChanged<double>? onValueChanged;

  final int? thumbDivisions;

  final double thumbPosition;

  final ValueChanged<double>? onThumbPositionChanged;

  final FocusNode? focusNode;

  final bool autofocus;

  final MouseCursor? mouseCursor;

  final bool ignorePointer;

  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter>
    with SingleTickerProviderStateMixin {
  final GlobalKey _sliderKey = GlobalKey();

  late Map<Type, Action<Intent>> _actionMap;

  static const Map<ShortcutActivator, Intent> _traditionalNavShortcutMap = {
    SingleActivator(LogicalKeyboardKey.arrowUp): _AdjustSliderIntent.up(),
    SingleActivator(LogicalKeyboardKey.arrowDown): _AdjustSliderIntent.down(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustSliderIntent.left(),
    SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustSliderIntent.right(),
  };

  static const Map<ShortcutActivator, Intent> _directionalNavShortcutMap = {
    SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustSliderIntent.left(),
    SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustSliderIntent.right(),
  };

  late FocusNode _focusNode;

  void _updateFocusNode(FocusNode? old, FocusNode? current) {
    if ((old == null && current == null) || old == current) {
      return;
    }
    if (old == null) {
      _focusNode.dispose();
      _focusNode = current!;
    } else if (current == null) {
      _focusNode = FocusNode();
    } else {
      _focusNode = current;
    }
  }

  late AnimationController _overlayController;

  late final SliderPainter _painter;

  bool get _enabled =>
      widget.onValueChanged != null || widget.onThumbPositionChanged != null;

  Rect? _thumbRect;

  void _onHover(PointerHoverEvent event) {
    final isThumbHovered = _thumbRect?.contains(event.localPosition);
    if (isThumbHovered == null) return;

    if (_enabled && isThumbHovered) {
      _overlayController.forward();
    } else {
      if (!_focused) {
        _overlayController.reverse();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: this,
    );
    _painter = SliderPainter(
      overlayAnimation: CurvedAnimation(
        parent: _overlayController,
        curve: Curves.fastOutSlowIn,
      ),
      onThumbRectChanged: (thumbRect) {
        _thumbRect = thumbRect;
      },
    );
    _actionMap = <Type, Action<Intent>>{
      _AdjustSliderIntent: CallbackAction<_AdjustSliderIntent>(
        onInvoke: _actionHandler,
      ),
    };
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(covariant BeforeAfter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFocusNode(oldWidget.focusNode, widget.focusNode);
  }

  @override
  void dispose() {
    _painter.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  void _handleValueChanged(double value) {
    if (value != widget.value) {
      widget.onValueChanged!(value);
      _focusNode.requestFocus();
    }
  }

  void _handleThumbPositionChanged(double value) {
    if (value != widget.thumbPosition) {
      widget.onThumbPositionChanged!(value);
      _focusNode.requestFocus();
    }
  }

  void _actionHandler(_AdjustSliderIntent intent) {
    final slider = _sliderKey.currentState as _TwoDirectionalSliderState;
    final TextDirection textDirection = Directionality.of(context);
    switch (intent.type) {
      case _SliderAdjustmentType.right:
        switch (textDirection) {
          case TextDirection.rtl:
            return slider._decreaseHorizontalAction();
          case TextDirection.ltr:
            return slider._increaseHorizontalAction();
        }
      case _SliderAdjustmentType.left:
        switch (textDirection) {
          case TextDirection.rtl:
            return slider._increaseHorizontalAction();
          case TextDirection.ltr:
            return slider._decreaseHorizontalAction();
        }

      case _SliderAdjustmentType.up:
        return slider._decreaseVerticalAction();
      case _SliderAdjustmentType.down:
        return slider._increaseVerticalAction();
    }
  }

  bool _hovering = false;

  void _handleHoverChanged(bool hovering) {
    if (hovering != _hovering) {
      setState(() => _hovering = hovering);
    }
  }

  bool _focused = false;

  void _handleFocusHighlightChanged(bool focused) {
    if (focused != _focused) {
      setState(() => _focused = focused);
      if (focused) {
        _overlayController.forward();
      } else {
        _overlayController.reverse();
      }
    }
  }

  bool _dragging = false;

  void _handleDragStart(double _) {
    if (_dragging) return;
    setState(() => _dragging = true);
  }

  void _handleDragEnd(double _) {
    if (!_dragging) return;
    setState(() => _dragging = false);
  }

  Widget _wrapWithSizing(Widget child) {
    if (widget.width == null && widget.height == null) {
      return child;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child is Image
          ? ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: child,
              ),
            )
          : child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final beforeAfterTheme = BeforeAfterTheme.of(context);
    final defaults = theme.useMaterial3
        ? _BeforeAfterDefaultsM3(context)
        : _BeforeAfterDefaultsM2(context);

    final effectiveTrackWidth = widget.trackWidth ??
        beforeAfterTheme.trackWidth ??
        defaults.trackWidth!;

    final effectiveTrackColor = widget.trackColor ??
        beforeAfterTheme.trackColor ??
        defaults.trackColor!;

    final effectiveThumbHeight = widget.thumbHeight ??
        beforeAfterTheme.thumbHeight ??
        defaults.thumbHeight!;

    final effectiveThumbWidth = widget.thumbWidth ??
        beforeAfterTheme.thumbWidth ??
        defaults.thumbWidth!;

    final effectiveThumbDecoration = (widget.thumbDecoration ??
            beforeAfterTheme.thumbDecoration ??
            defaults.thumbDecoration!)
        .copyWith(color: widget.thumbColor);

    final isXAxis = widget.direction == SliderDirection.horizontal;

    final onHorizontalChanged =
        widget.onValueChanged != null ? _handleValueChanged : null;

    final onVerticalChanged = widget.onThumbPositionChanged != null
        ? _handleThumbPositionChanged
        : null;

    final before = _wrapWithSizing(widget.before);

    final after = _wrapWithSizing(widget.after);

    final Map<ShortcutActivator, Intent> shortcutMap;
    switch (MediaQuery.navigationModeOf(context)) {
      case NavigationMode.directional:
        shortcutMap = _directionalNavShortcutMap;
        break;
      case NavigationMode.traditional:
        shortcutMap = _traditionalNavShortcutMap;
        break;
    }

    final states = {
      if (!_enabled) WidgetState.disabled,
      if (_focused) WidgetState.focused,
      if (_hovering) WidgetState.hovered,
      if (_dragging) WidgetState.dragged,
    };

    final effectiveOverlayColor = widget.overlayColor?.resolve(states) ??
        widget.trackColor?.withValues(alpha: 0.12) ??
        WidgetStateProperty.resolveAs<Color?>(
            beforeAfterTheme.overlayColor, states) ??
        WidgetStateProperty.resolveAs<Color>(defaults.overlayColor!, states);

    final effectiveMouseCursor =
        WidgetStateProperty.resolveAs(widget.mouseCursor, states) ??
            beforeAfterTheme.mouseCursor?.resolve(states) ??
            WidgetStateMouseCursor.clickable.resolve(states);

    VoidCallback? handleDidGainAccessibilityFocus;
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        break;
      case TargetPlatform.windows:
        handleDidGainAccessibilityFocus = () {
          if (!_focusNode.hasFocus && _focusNode.canRequestFocus) {
            _focusNode.requestFocus();
          }
        };
    }

    return Semantics(
      container: true,
      slider: true,
      onDidGainAccessibilityFocus: handleDidGainAccessibilityFocus,
      child: MouseRegion(
        onHover: _onHover,
        child: FocusableActionDetector(
          actions: _actionMap,
          shortcuts: shortcutMap,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onShowFocusHighlight: _handleFocusHighlightChanged,
          onShowHoverHighlight: _handleHoverChanged,
          mouseCursor: effectiveMouseCursor,
          child: widget.ignorePointer
              ? Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    before,
                    ClipRect(
                      clipper: RectClipper(
                        direction: widget.direction,
                        clipFactor: widget.value,
                      ),
                      child: after,
                    ),
                    CustomPaint(
                      painter: _painter
                        ..axis = widget.direction
                        ..value = widget.value
                        ..trackWidth = effectiveTrackWidth
                        ..trackColor = effectiveTrackColor
                        ..hideThumb = widget.hideThumb
                        ..thumbValue = widget.thumbPosition
                        ..thumbHeight = effectiveThumbHeight
                        ..thumbWidth = effectiveThumbWidth
                        ..overlayColor = effectiveOverlayColor
                        ..configuration = createLocalImageConfiguration(context)
                        ..thumbDecoration = effectiveThumbDecoration,
                      child: Hide(child: after),
                    ),
                  ],
                )
              : TwoDirectionalSlider(
                  key: _sliderKey,
                  initialHorizontalValue: widget.value,
                  initialVerticalValue: widget.thumbPosition,
                  verticalDivisions:
                      isXAxis ? widget.thumbDivisions : widget.divisions,
                  horizontalDivisions:
                      isXAxis ? widget.divisions : widget.thumbDivisions,
                  onVerticalChangeStart: _handleDragStart,
                  onVerticalChanged:
                      isXAxis ? onVerticalChanged : onHorizontalChanged,
                  onVerticalChangeEnd: _handleDragEnd,
                  onHorizontalChangeStart: _handleDragStart,
                  onHorizontalChanged:
                      isXAxis ? onHorizontalChanged : onVerticalChanged,
                  onHorizontalChangeEnd: _handleDragEnd,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      before,
                      ClipRect(
                        clipper: RectClipper(
                          direction: widget.direction,
                          clipFactor: widget.value,
                        ),
                        child: after,
                      ),
                      CustomPaint(
                        painter: _painter
                          ..axis = widget.direction
                          ..value = widget.value
                          ..trackWidth = effectiveTrackWidth
                          ..trackColor = effectiveTrackColor
                          ..hideThumb = widget.hideThumb
                          ..thumbValue = widget.thumbPosition
                          ..thumbHeight = effectiveThumbHeight
                          ..thumbWidth = effectiveThumbWidth
                          ..overlayColor = effectiveOverlayColor
                          ..configuration =
                              createLocalImageConfiguration(context)
                          ..thumbDecoration = effectiveThumbDecoration,
                        child: Hide(child: after),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class Hide extends StatelessWidget {
  const Hide({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: false,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: child,
    );
  }
}

class AutoScrollBeforeAfter extends StatefulWidget {
  const AutoScrollBeforeAfter({
    super.key,
    this.before,
    this.after,
    this.images,
    this.height,
    this.width,
    this.trackWidth,
    this.trackColor,
    this.hideThumb = true,
    this.thumbHeight,
    this.thumbWidth,
    this.thumbColor,
    this.overlayColor,
    this.thumbDecoration,
    this.direction = SliderDirection.horizontal,
    this.initialValue = 0.0,
    this.waitDuration = const Duration(seconds: 2),
    this.speedDuration = const Duration(seconds: 3),
    this.loop = true,
    this.maintainFinalState = false,
    this.onValueChanged,
  }) : assert(
          (after != null) || images != null,
          'Either provide both before and after widgets, or provide a list of images',
        );

  final Widget? before;
  final Widget? after;
  final List<String>? images;
  final SliderDirection direction;
  final double? height;
  final double? width;
  final double? trackWidth;
  final Color? trackColor;
  final bool hideThumb;
  final double? thumbHeight;
  final double? thumbWidth;
  final Color? thumbColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final BoxDecoration? thumbDecoration;
  final double initialValue;
  final Duration waitDuration;
  final Duration speedDuration;
  final bool loop;
  final bool maintainFinalState;
  final ValueChanged<double>? onValueChanged;

  @override
  State<AutoScrollBeforeAfter> createState() => _AutoScrollBeforeAfterState();
}

class _AutoScrollBeforeAfterState extends State<AutoScrollBeforeAfter>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  late Animation<double> _scrollAnimation;
  double _currentValue = 0.0;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _scrollController = AnimationController(
      duration: widget.speedDuration,
      vsync: this,
    );
    _scrollAnimation = Tween<double>(
      begin: widget.initialValue,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scrollController,
      curve: Curves.easeInOut,
    ));

    _scrollAnimation.addListener(() {
      setState(() {
        _currentValue = _scrollAnimation.value;
      });
      widget.onValueChanged?.call(_currentValue);
    });

    _startAutoScroll();
  }

  void _startAutoScroll() async {
    if (!mounted) return;

    await Future.delayed(widget.waitDuration);
    if (!mounted) return;

    _scrollController.forward().then((_) {
      if (mounted && widget.loop && !widget.maintainFinalState) {
        _scrollController.reset();
        _startAutoScroll();
      } else if (mounted && widget.images != null && widget.loop) {
        // Move to next image
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % widget.images!.length;
        });
        _scrollController.reset();
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Resets the animation to the initial state and restarts the auto-scroll
  void reset() {
    if (mounted) {
      _scrollController.reset();
      setState(() {
        _currentValue = widget.initialValue;
        _currentImageIndex = 0;
      });
      _startAutoScroll();
    }
  }

  Widget _getCurrentImage() {
    if (widget.images != null && widget.images!.isNotEmpty) {
      return Image.network(widget.images![_currentImageIndex]);
    }
    return Container(); // Fallback
  }

  Widget _getNextImage() {
    if (widget.images != null && widget.images!.isNotEmpty) {
      final nextIndex = (_currentImageIndex + 1) % widget.images!.length;
      return Image.network(widget.images![nextIndex]);
    }
    return Container(); // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final beforeWidget = widget.before ?? _getCurrentImage();
    final afterWidget = widget.after ?? _getNextImage();

    return BeforeAfter(
      before: beforeWidget,
      after: afterWidget,
      height: widget.height,
      width: widget.width,
      trackWidth: widget.trackWidth,
      trackColor: widget.trackColor,
      hideThumb: widget.hideThumb,
      thumbHeight: widget.thumbHeight,
      thumbWidth: widget.thumbWidth,
      thumbColor: widget.thumbColor,
      overlayColor: widget.overlayColor,
      thumbDecoration: widget.thumbDecoration,
      direction: widget.direction,
      value: _currentValue,
      onValueChanged: widget.onValueChanged,
    );
  }
}

class _AdjustSliderIntent extends Intent {
  const _AdjustSliderIntent({required this.type});

  const _AdjustSliderIntent.right() : type = _SliderAdjustmentType.right;

  const _AdjustSliderIntent.left() : type = _SliderAdjustmentType.left;

  const _AdjustSliderIntent.up() : type = _SliderAdjustmentType.up;

  const _AdjustSliderIntent.down() : type = _SliderAdjustmentType.down;

  final _SliderAdjustmentType type;
}

enum _SliderAdjustmentType { right, left, up, down }

class _BeforeAfterDefaultsM2 extends BeforeAfterTheme {
  _BeforeAfterDefaultsM2(BuildContext context)
      : _colors = Theme.of(context).colorScheme,
        super(trackWidth: 6.0, thumbWidth: 24.0, thumbHeight: 24.0);

  final ColorScheme _colors;

  @override
  Color get trackColor => _colors.primary;

  @override
  Color get overlayColor => _colors.primary.withValues(alpha: 0.12);

  @override
  BoxDecoration get thumbDecoration {
    return BoxDecoration(
      color: trackColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: _defaultThumbElevation,
          spreadRadius: _defaultThumbElevation / 2,
          offset: const Offset(0, _defaultThumbElevation / 2),
        ),
      ],
    );
  }
}

class _BeforeAfterDefaultsM3 extends BeforeAfterTheme {
  _BeforeAfterDefaultsM3(BuildContext context)
      : _colors = Theme.of(context).colorScheme,
        super(trackWidth: 6.0, thumbWidth: 24.0, thumbHeight: 24.0);

  final ColorScheme _colors;

  @override
  Color get trackColor => _colors.primary;

  @override
  Color get overlayColor {
    return WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) {
        return _colors.primary.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.primary.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.dragged)) {
        return _colors.primary.withValues(alpha: 0.12);
      }

      return Colors.transparent;
    });
  }

  @override
  BoxDecoration get thumbDecoration {
    return BoxDecoration(
      color: trackColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: _defaultThumbElevation,
          spreadRadius: _defaultThumbElevation / 2,
          offset: const Offset(0, _defaultThumbElevation / 2),
        ),
      ],
    );
  }
}
