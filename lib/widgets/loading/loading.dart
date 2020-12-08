import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  final Widget child;
  final int milliseconds;
  Loading({Key key, @required this.child, this.milliseconds = 2000})
      : super(key: key);

  @override
  LoadingState createState() => LoadingState();
}

class LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  AnimationController controller;

  @override
  void initState() {
    this.controller = AnimationController(
        duration: Duration(milliseconds: widget.milliseconds), vsync: this);
    this.controller.repeat();
    super.initState();
  }

  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height,
      // child: TextLoading(text: '拼命加载中', animation: this.controller),
      child: widget.child,
    );
  }
}
