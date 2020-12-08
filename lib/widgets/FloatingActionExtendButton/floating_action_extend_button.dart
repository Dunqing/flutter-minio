import 'package:MinioClient/widgets/FloatingActionExtendButton/animated_floating_button.dart';
import 'package:MinioClient/widgets/FloatingActionExtendButton/floating_action_extend_child.dart';
import 'package:flutter/material.dart';

import 'animated_child.dart';

class FloatingActionExtendButton extends StatefulWidget {
  /// Children buttons, from the lowest to the highest.
  final List<FloatingActionExtendChild> children;

  /// Used to get the button hidden on scroll. See examples for more info.
  final bool visible;

  /// The curve used to animate the button on scrolling.
  final Curve curve;

  final String tooltip;
  final String heroTag;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final ShapeBorder shape;

  final double marginRight;
  final double marginBottom;

  /// The color of the background overlay.
  final Color overlayColor;

  /// The opacity of the background overlay when the dial is open.
  final double overlayOpacity;

  /// The animated icon to show as the main button child. If this is provided the [child] is ignored.
  final AnimatedIconData animatedIcon;

  /// The theme for the animated icon.
  final IconThemeData animatedIconTheme;

  /// The child of the main button, ignored if [animatedIcon] is non [null].
  final Widget child;

  /// Executed when the dial is opened.
  final VoidCallback onOpen;

  /// Executed when the dial is closed.
  final VoidCallback onClose;

  /// Executed when the dial is pressed. If given, the dial only opens on long press!
  final VoidCallback onPress;

  /// If true user is forced to close dial manually by tapping main button. WARNING: If true, overlay is not rendered.
  final bool closeManually;

  /// The speed of the animation
  final int animationSpeed;
  // use animation icon?
  final bool normal;

  FloatingActionExtendButton(
      {this.children = const [],
      this.visible = true,
      this.backgroundColor,
      this.foregroundColor,
      this.elevation = 6.0,
      this.overlayOpacity = 0.8,
      this.overlayColor = Colors.white,
      this.tooltip,
      this.heroTag,
      this.animatedIcon,
      this.animatedIconTheme,
      this.child,
      this.marginBottom = 16,
      this.marginRight = 16,
      this.onOpen,
      this.onClose,
      this.closeManually = false,
      this.shape = const CircleBorder(),
      this.curve = Curves.linear,
      this.onPress,
      this.animationSpeed = 150,
      this.normal = false});

  @override
  _FloatingActionExtendButtonState createState() =>
      _FloatingActionExtendButtonState();
}

class _FloatingActionExtendButtonState extends State<FloatingActionExtendButton>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  AnimationController _controller;
  Duration _calculateMainControllerDuration() => Duration(
      milliseconds: widget.animationSpeed +
          widget.children.length * (widget.animationSpeed / 5).round());

  @override
  void initState() {
    super.initState();
    this._controller = AnimationController(
        duration: _calculateMainControllerDuration(), vsync: this);
  }

  @override
  void didUpdateWidget(FloatingActionExtendButton oldWidget) {
    if (oldWidget.children.length != widget.children.length) {
      this._controller.duration = this._calculateMainControllerDuration();
    }

    super.didUpdateWidget(oldWidget);
  }

  List<Widget> _getChildrenList() {
    final singleChildrenTween = 1.0 / widget.children.length;

    return widget.children.map((FloatingActionExtendChild child) {
      int index = widget.children.indexOf(child);

      var childAnimation = Tween(begin: 0.0, end: 62.0).animate(CurvedAnimation(
          parent: this._controller,
          curve: Interval(0, singleChildrenTween * (index + 1))));

      return AnimatedChild(
        animation: childAnimation,
        shape: widget.shape,
        child: child.child,
        elevation: child.elevation,
        backgroundColor: child.backgroundColor,
        onTap: child.onTap,
        label: child.label,
        labelWidget: child.labelWidget,
        labelStyle: child.labelStyle,
        labelBackgroundColor: child.labelBackgroundColor,
        heroTag:
            widget.heroTag != null ? '${widget.heroTag}-child-$index' : null,
        foregroundColor: child.foregroundColor,
      );
    }).toList();
  }

  Widget _renderButton() {
    var child = widget.animatedIcon != null
        ? AnimatedIcon(
            icon: widget.animatedIcon,
            color: widget.animatedIconTheme?.color,
            size: widget.animatedIconTheme?.size,
            progress: _controller)
        : widget.child;

    final animatedFloatingButton = AnimatedFloatingButton(
        elevation: widget.elevation,
        tooltip: widget.tooltip,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        callback: widget.onPress != null ? _toggleChildren : widget.onPress,
        heroTag: widget.heroTag,
        shape: widget.shape,
        curve: widget.curve,
        child: child,
        visible: widget.visible,
        onLongPress: _toggleChildren,
        onTap: _toggleChildren);

    return Positioned(
      bottom: widget.marginBottom - 16,
      right: widget.marginRight - 16,
      child: Container(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.from(this._getChildrenList())
              ..add(
                Container(
                  margin: EdgeInsets.only(top: 8.0, right: 2.0),
                  child: animatedFloatingButton,
                ),
              )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var children = [_renderButton()];
    return Container(
      child: Stack(
        alignment: Alignment.bottomRight,
        overflow: Overflow.visible,
        children: children,
      ),
    );
  }

  void _toggleChildren() {
    var newValue = !_open;
    setState(() {
      _open = newValue;
    });
    if (newValue && widget.onOpen != null) widget.onOpen();
    _performAnimation();
    if (!newValue && widget.onClose != null) widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performAnimation() {
    if (!mounted) return;
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }
}
