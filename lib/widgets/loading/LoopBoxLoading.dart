import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'loading.dart';

class LoopBoxLoading extends StatefulWidget {
  final String text;
  final Animation<double> animation;
  LoopBoxLoading({
    Key key,
    this.text,
    this.animation,
  }) : super(key: key);

  @override
  _LoopBoxLoadingState createState() => _LoopBoxLoadingState();
}

class _LoopBoxLoadingState extends State<LoopBoxLoading> {
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
  }

  List<Widget> _renderChildren() {
    return [1, 2, 3, 4, 5, 6]
        .map((index) => Container(
              width: 20,
              height: 20,
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: this._animation.value.toInt() == index
                    ? Colors.white
                    : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (this._animation == null) {
      final parentState = context.findAncestorStateOfType<LoadingState>();
      if ('LoadingState' != parentState.runtimeType.toString()) {
        throw '父Widget只能是Loading';
      }
      this._animation = Tween(begin: 1.0, end: 7.0)
          .animate(widget.animation ?? parentState.controller);
    }

    return AnimatedBuilder(
        animation: this._animation,
        builder: (BuildContext context, Widget _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: this._renderChildren(),
          );
        });
  }
}
