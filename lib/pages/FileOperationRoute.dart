import 'package:MinioClient/pages/widgets/DownloadPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'widgets/UploadPage.dart';

class FileOperationRoute extends StatefulWidget {
  FileOperationRoute({Key key}) : super(key: key);

  @override
  _FileOperationRouteState createState() => _FileOperationRouteState();
}

class _FileOperationRouteState extends State<FileOperationRoute> {
  TabController _controller;

  @override
  void initState() {
    this._controller = TabController(length: 2, vsync: ScrollableState());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('传输记录'),
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
          DownloadPage(),
          UploadPage(),
        ],
      ),
    );
  }
}
