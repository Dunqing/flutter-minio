import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'loading.dart';

class TextLoading extends StatefulWidget {
  final String text;
  final Animation<double> animation;
  TextLoading({
    Key key,
    this.text,
    this.animation,
  }) : super(key: key);

  @override
  _TextLoadingState createState() => _TextLoadingState();
}

class _TextLoadingState extends State<TextLoading> {
  Animation<double> _animation;

  @override
  void initState() {
    if (this._animation == null) {
      var parentState = this.context.findAncestorStateOfType<LoadingState>();
      parentState = parentState is LoadingState
          ? parentState
          : parentState.context.findAncestorStateOfType<LoadingState>();

      if ('LoadingState' != parentState.runtimeType.toString()) {
        throw '父Widget只能是Loading';
      }
      this._animation = Tween(begin: 1.0, end: 7.0)
          .animate(widget.animation ?? parentState.controller);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: this._animation,
        builder: (BuildContext context, Widget _) {
          var dot = '';
          for (var i = 1; i <= this._animation.value; i++) {
            dot += '.';
          }
          return Text(
            widget.text + dot,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                decoration: TextDecoration.none),
          );
        });
  }
}
