///
/// * author: hunghd
/// * email: hunghd.yb@gmail.com
///
/// A package provides an easy way to add shimmer effect to Flutter application
///

library shimmer;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

///
/// An enum defines all supported directions of shimmer effect
///
/// * [ShimmerDirection.ltr] left to right direction
/// * [ShimmerDirection.rtl] right to left direction
/// * [ShimmerDirection.ttb] top to bottom direction
/// * [ShimmerDirection.btt] bottom to top direction
///
enum ShimmerDirection { ltr, rtl, ttb, btt }

///
/// A widget renders shimmer effect over [child] widget tree.
///
/// [child] defines an area that shimmer effect blends on. You can build [child]
/// from whatever [Widget] you like but there're some notices in order to get
/// exact expected effect and get better rendering performance:
///
/// * Use static [Widget] (which is an instance of [StatelessWidget]).
/// * [Widget] should be a solid color element. Every colors you set on these
/// [Widget]s will be overridden by colors of [gradient].
/// * Shimmer effect only affects to opaque areas of [child], transparent areas
/// still stays transparent.
///
/// [period] controls the speed of shimmer effect. The default value is 1500
/// milliseconds.
/// This property is only used when [shimmerController] is null.
///
/// [direction] controls the direction of shimmer effect. The default value
/// is [ShimmerDirection.ltr].
///
/// [gradient] controls colors of shimmer effect.
///
/// [loop] the number of animation loop, set value of `0` to make animation run
/// forever.
/// This property is only used when [shimmerController] is null.
///
/// [enabled] controls if shimmer effect is active. When set to false the animation
/// is paused.
/// Should not be used with [shimmerController].
///
/// [shimmerController] AnimationController for Shimmer animation, use this when
/// you want to synchronise multiples Shimmer Widgets
///
/// [hideWhenDisabled] hide the shimmer effect when shimmer effect is paused
///
///
/// ## Pro tips:
///
/// * [child] should be made of basic and simple [Widget]s, such as [Container],
/// [Row] and [Column], to avoid side effect.
///
/// * use one [Shimmer] to wrap list of [Widget]s instead of a list of many [Shimmer]s
///
@immutable
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration? period;
  final ShimmerDirection direction;
  final Gradient gradient;
  final int? loop;
  final bool? enabled;
  final ShimmerController? shimmerController;
  final bool hideWhenDisabled;

  const Shimmer({
    Key? key,
    required this.child,
    required this.gradient,
    this.direction = ShimmerDirection.ltr,
    this.period,
    this.loop,
    this.enabled,
    this.shimmerController,
    this.hideWhenDisabled = false,
  })  : assert(
            shimmerController == null || (period == null && loop == null),
            '[ShimmerController] override values of [period],'
            ' [loop] and [enabled] parameters'),
        assert(
            shimmerController == null || enabled == null,
            'If you change value [enabled] of one [Shimmer],'
            ' this will stop all [Shimmer]s using this [ShimmerController],'
            ' prefer using [shimmerController.stop()] and [shimmerController.forward()] methods'),
        super(key: key);

  ///
  /// A convenient constructor provides an easy and convenient way to create a
  /// [Shimmer] which [gradient] is [LinearGradient] made up of `baseColor` and
  /// `highlightColor`.
  ///
  Shimmer.fromColors({
    Key? key,
    required this.child,
    required Color baseColor,
    required Color highlightColor,
    this.direction = ShimmerDirection.ltr,
    this.period,
    this.loop,
    this.enabled,
    this.shimmerController,
    this.hideWhenDisabled = false,
  })  : gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              baseColor,
              baseColor,
              highlightColor,
              baseColor,
              baseColor
            ],
            stops: const <double>[
              0.0,
              0.35,
              0.5,
              0.65,
              1.0
            ]),
        assert(
            shimmerController == null || (period == null && loop == null),
            '[ShimmerController] override values of [period],'
            ' [loop] and [enabled] parameters'),
        assert(
            shimmerController == null || enabled == null,
            'If you change value [enabled] of one [Shimmer],'
            ' this will stop all [Shimmer]s using this [ShimmerController],'
            ' prefer using [shimmerController.stop()] and [shimmerController.forward()] methods'),
        super(key: key);

  @override
  _ShimmerState createState() => _ShimmerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Gradient>('gradient', gradient,
        defaultValue: null));
    properties.add(EnumProperty<ShimmerDirection>('direction', direction));
    properties.add(
        DiagnosticsProperty<Duration>('period', period, defaultValue: null));
    properties
        .add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: null));
    properties.add(DiagnosticsProperty<int>('loop', loop, defaultValue: null));
    properties.add(DiagnosticsProperty<ShimmerController>(
        'shimmerController', shimmerController,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>(
        'hideWhenDisabled', hideWhenDisabled,
        defaultValue: false));
  }
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final int _loop = widget.shimmerController?.loop ?? widget.loop ?? 0;
  late final Duration _period =
      widget.period ?? const Duration(milliseconds: 1500);
  late bool _enabled = widget.enabled ?? true;
  late final AnimationController _controller = widget.shimmerController ??
      AnimationController(vsync: this, duration: _period);
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _count++;
        if (_loop <= 0) {
          _controller.repeat();
        } else if (_count < _loop) {
          _controller.forward(from: 0.0);
        }
      }
    });
    if (_enabled) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(Shimmer oldWidget) {
    if (widget.enabled != oldWidget.enabled) {
      _enabled = widget.enabled ?? true;
      if (_enabled) {
        _controller.forward();
      } else {
        _controller.stop();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.hideWhenDisabled && !_controller.isAnimating
        ? widget.child
        : AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (BuildContext context, Widget? child) => _Shimmer(
              child: child,
              direction: widget.direction,
              gradient: widget.gradient,
              percent: _controller.value,
            ),
          );
  }

  @override
  void dispose() {
    if (widget.shimmerController != null)
      widget.shimmerController!.disposeShimmer();
    else
      _controller.dispose();

    super.dispose();
  }
}

@immutable
class _Shimmer extends SingleChildRenderObjectWidget {
  final double percent;
  final ShimmerDirection direction;
  final Gradient gradient;

  const _Shimmer({
    Widget? child,
    required this.percent,
    required this.direction,
    required this.gradient,
  }) : super(child: child);

  @override
  _ShimmerFilter createRenderObject(BuildContext context) {
    return _ShimmerFilter(percent, direction, gradient);
  }

  @override
  void updateRenderObject(BuildContext context, _ShimmerFilter shimmer) {
    shimmer.percent = percent;
    shimmer.gradient = gradient;
    shimmer.direction = direction;
  }
}

///
/// [loop] the number of animation loop, set value of `0` to make animation run
/// forever.
///
/// [period] controls the speed of shimmer effect. The default value is 1500
/// milliseconds.
///
class ShimmerController extends AnimationController {
  ShimmerController({
    required TickerProvider vsync,
    this.loop = 0,
    this.period = const Duration(milliseconds: 1500),
  }) : super(vsync: vsync, duration: period);

  final int loop;
  final Duration period;

  bool _isDisposed = false;
  void disposeShimmer() {
    if(!_isDisposed){
      _isDisposed = true;
      dispose();
    }
  }
}

class _ShimmerFilter extends RenderProxyBox {
  ShimmerDirection _direction;
  Gradient _gradient;
  double _percent;

  _ShimmerFilter(this._percent, this._direction, this._gradient);

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  set percent(double newValue) {
    if (newValue == _percent) {
      return;
    }
    _percent = newValue;
    markNeedsPaint();
  }

  set gradient(Gradient newValue) {
    if (newValue == _gradient) {
      return;
    }
    _gradient = newValue;
    markNeedsPaint();
  }

  set direction(ShimmerDirection newDirection) {
    if (newDirection == _direction) {
      return;
    }
    _direction = newDirection;
    markNeedsLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);

      final double width = child!.size.width;
      final double height = child!.size.height;
      Rect rect;
      double dx, dy;
      if (_direction == ShimmerDirection.rtl) {
        dx = _offset(width, -width, _percent);
        dy = 0.0;
        rect = Rect.fromLTWH(dx - width, dy, 3 * width, height);
      } else if (_direction == ShimmerDirection.ttb) {
        dx = 0.0;
        dy = _offset(-height, height, _percent);
        rect = Rect.fromLTWH(dx, dy - height, width, 3 * height);
      } else if (_direction == ShimmerDirection.btt) {
        dx = 0.0;
        dy = _offset(height, -height, _percent);
        rect = Rect.fromLTWH(dx, dy - height, width, 3 * height);
      } else {
        dx = _offset(-width, width, _percent);
        dy = 0.0;
        rect = Rect.fromLTWH(dx - width, dy, 3 * width, height);
      }
      layer ??= ShaderMaskLayer();
      layer!
        ..shader = _gradient.createShader(rect)
        ..maskRect = offset & size
        ..blendMode = BlendMode.srcIn;
      context.pushLayer(layer!, super.paint, offset);
    } else {
      layer = null;
    }
  }

  double _offset(double start, double end, double percent) {
    return start + (end - start) * percent;
  }
}
