import 'package:flutter/material.dart';

import 'widgets/AccountSetting.dart';
import 'widgets/OtherSetting.dart';

class SettingRoute extends StatefulWidget {
  SettingRoute({Key key}) : super(key: key);

  @override
  _SettingRouteState createState() => _SettingRouteState();
}

class _SettingRouteState extends State<SettingRoute> {
  final List<Widget> _pages = [
    AccountSetting(),
    OtherSetting(),
  ];
  PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    this._controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
          appBar: AppBar(
            title: Text('设置'),
          ),
          body: PageView.builder(
            itemCount: _pages.length,
            controller: this._controller,
            onPageChanged: (index) {
              setState(() {
                if (index == this._currentIndex) {
                  return;
                }
                this._currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return this._pages[index];
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            items: [
              BottomNavigationBarItem(
                label: '账号设置',
                icon: Icon(Icons.account_circle),
              ),
              BottomNavigationBarItem(
                  label: '其他设置', icon: Icon(Icons.settings)),
            ],
            onTap: (selected) {
              setState(() {
                this._controller.jumpToPage(selected);
              });
            },
          )),
    );
  }
}
