import 'package:MinioClient/db/DownloadController.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class DownloadPage extends StatefulWidget {
  DownloadPage({Key key}) : super(key: key);

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  DownloadController downloadController;
  List<DownloadFileInstance> downloadList = [];
  // ignore: close_sinks
  ReplaySubject<List<DownloadFileInstance>> _stream;
  _DownloadPageState() {
    this.downloadController = createDownloadInstance();
    this._stream = this.downloadController.downloadStream;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('stream');
    return StreamBuilder(
        stream: this._stream,
        builder: (context, AsyncSnapshot<List<DownloadFileInstance>> builder) {
          _refresh() {
            this._stream.add(builder.data);
          }

          print('data {$builder.data.length}');
          print(builder.data);
          print(ConnectionState.waiting);
          final data = builder.data ?? [];
          if (!builder.hasData) {
            return FlatButton(
                child: Text('没有数据我添加试试看'),
                onPressed: () {
                  this._stream.add([
                    DownloadFileInstance(
                        1, 'image', '123', 10000, 1000000, 1000, 100)
                  ]);
                });
          }
          return Container(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final current = data[index];
                final progress =
                    (100 * (current.downloadSize / current.fileSize)).toInt();
                return ListTile(
                  title: Text(current.filename),
                  subtitle: Text('下载大小 ${current.fileSize}'),
                  trailing: current.state == DownloadState.COMPLETED
                      ? Text('下载完成')
                      : FlatButton.icon(
                          label: Text('下载中 $progress%'),
                          icon: current.state == DownloadState.PAUSE
                              ? Icon(Icons.play_arrow)
                              : Icon(Icons.stop),
                          onPressed: () {
                            if (current.subscription != null) {
                              if (current.state == DownloadState.PAUSE) {
                                this.downloadController.reDownload(current);
                                current.changeState(DownloadState.DOWNLOAD);
                                _refresh();
                                toast('继续下载');
                              } else if (current.state ==
                                  DownloadState.DOWNLOAD) {
                                current.changeState(DownloadState.PAUSE);
                                current.subscription.cancel();
                                toast('暂停成功');
                                _refresh();
                              }
                            }
                          },
                        ),
                );
              },
            ),
          );
        });
  }
}
