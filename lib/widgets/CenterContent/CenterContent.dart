import 'package:flutter/material.dart';

class CenterContent extends StatelessWidget {
  final List<Widget> children;
  const CenterContent({Key key, this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints.expand(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}
