import 'package:MinioClient/widgets/loading/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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

  List<Widget> _renderChildren() {
    return [1, 2, 3, 4, 5, 6]
        .map((index) => Container(
              width: 20,
              height: 20,
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: this._animation.value.toInt() == index
                    ? Colors.blue
                    : Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: this._animation,
        builder: (BuildContext context, Widget _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.text != null)
                Text(widget.text,
                    style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        fontSize: 16)),
              SizedBox(
                child: null,
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: this._renderChildren(),
              ),
            ],
          );
        });
  }
}
