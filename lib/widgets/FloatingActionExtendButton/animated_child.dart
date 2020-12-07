import 'package:flutter/material.dart';

class AnimatedChild extends AnimatedWidget {
  final Widget child;
  final String heroTag;
  final double elevation;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final ShapeBorder shape;
  final String label;
  final Widget labelWidget;
  final TextStyle labelStyle;
  final Color labelBackgroundColor;

  AnimatedChild({
    Animation<double> animation,
    this.heroTag,
    this.onTap,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.labelBackgroundColor,
    this.label,
    this.labelWidget,
    this.labelStyle,
    this.elevation,
    this.shape,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;

    final Widget buttonChild = animation.value > 50.0
        ? Container(
            width: animation.value,
            height: animation.value,
            child: child ?? Container(),
          )
        : Container(
            width: 0.0,
            height: 0.0,
          );

    return Container(
        child: Row(children: [
      if (this.label != null && animation.value > 50) _renderLabel(),
      Container(
          width: 62.0,
          height: animation.value,
          padding: EdgeInsets.only(bottom: 62.0 - animation.value),
          child: Container(
            height: 62.0,
            width: animation.value,
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: FloatingActionButton(
              heroTag: heroTag,
              onPressed: _performAction,
              child: buttonChild,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: elevation ?? 6.0,
              shape: shape,
            ),
          ))
    ]));
  }

  void _performAction() {
    if (onTap != null) {
      onTap();
    }
  }

  Widget _renderLabel() {
    if (this.labelWidget != null) {
      return labelWidget;
    }
    return GestureDetector(
        onTap: _performAction,
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Text(this.label,
                style: this.labelStyle ?? TextStyle(color: Colors.white)),
            decoration: BoxDecoration(
                color: labelBackgroundColor ?? Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(6.0)),
                boxShadow: [
                  BoxShadow(
                      blurRadius: 2.4,
                      color: Colors.white,
                      offset: Offset(0.8, 0.8))
                ])));
  }
}
