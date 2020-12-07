import 'package:flutter/material.dart';

class NormalButton extends StatelessWidget {
  final Widget child;
  final bool visible;
  final VoidCallback callback;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final Curve curve;

  NormalButton(
    this.child, {
    this.visible = true,
    this.onLongPress,
    this.callback,
    this.onTap,
    this.curve = Curves.linear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onLongPress: onLongPress ?? () {}, onTap: onTap ?? () {}, child: null);
  }
}
