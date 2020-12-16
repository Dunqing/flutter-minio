import 'package:MinioClient/pages/widgets/DownloadPage.dart';
import 'package:MinioClient/pages/widgets/SelectingHandler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'widgets/UploadPage.dart';

class FileOperationRoute extends StatefulWidget {
  FileOperationRoute({Key key}) : super(key: key);

  @override
  _FileOperationRouteState createState() => _FileOperationRouteState();
}

class _FileOperationRouteState extends State<FileOperationRoute> {
  TabController _controller;

  /// 多选状态
  bool _selecting = false;
  MenuButtonMethod _eventType;

  @override
  void initState() {
    this._controller = TabController(length: 2, vsync: ScrollableState());
    this._controller.addListener(() {
      if (this._controller.index != 0) {
        print('关闭');
        this._changeSelecting(false);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    this._controller.dispose();
    super.dispose();
  }

  /// 改变多选按钮
  void _changeSelecting([bool value]) {
    setState(() {
      this._selecting = value == null ? !this._selecting : value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('传输记录'),
        actions: [
          if (_selecting)
            SelectingHandler(
                changeSelecting: _changeSelecting, onSelected: _onSelected)
        ],
        bottom: TabBar(
          controller: _controller,
          isScrollable: true,
          labelPadding: EdgeInsets.symmetric(horizontal: 65),
          tabs: [
            Tab(child: Text('下载'), icon: Icon(Icons.download_sharp)),
            Tab(
              child: Text('上传'),
              icon: Icon(Icons.upload_sharp),
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          DownloadPage(
              eventType: _eventType,
              selecting: _selecting,
              changeSelecting: _changeSelecting),
          UploadPage(),
        ],
      ),
    );
  }

  void _onSelected(value) {
    setState(() {
      this._eventType = value;
    });
    Future.delayed(Duration(milliseconds: 50)).then((_) {
      setState(() {
        this._eventType = null;
      });
    });
  }
}
