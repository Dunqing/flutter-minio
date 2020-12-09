import 'package:MinioClient/db/DownloadController.dart';
import 'package:flutter/material.dart';

class DownloadPage extends StatefulWidget {
  DownloadPage({Key key}) : super(key: key);

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  DownloadController downloadController;
  List<Map<String, dynamic>> downloadList = [];
  _DownloadPageState() {
    this.downloadController = DownloadController();
  }

  @override
  void initState() {
    this.getDownloadList();
    super.initState();
  }

  getDownloadList() {
    this.downloadController.finaAll().then((res) {
      setState(() {
        this.downloadList = res;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
        itemCount: downloadList.length,
        itemBuilder: (context, index) {
          final current = this.downloadList[index];
          return ListTile(
            title: Text(current['filename']),
            subtitle: Text('下载总量 ${current['size']}'),
            trailing: Text('${current['rate']}%'),
          );
        },
      ),
    );
  }
}
