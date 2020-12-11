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

  _changeDownloadState(DownloadFileInstance instance, DownloadState state) {
    this.downloadController.updateDownloadState(instance, state);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: this._stream,
        builder: (context, AsyncSnapshot<List<DownloadFileInstance>> builder) {
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

                return ListTile(
                    title: Text(current.filename),
                    subtitle: Text('下载大小 ${current.fileSize}'),
                    trailing: _renderTrailing(current));
              },
            ),
          );
        });
  }

  _renderTrailing(DownloadFileInstance current) {
    final progress = (100 * (current.downloadSize / current.fileSize)).toInt();
    switch (current.state) {
      case DownloadState.DOWNLOAD:
        return FlatButton.icon(
          label: Text('下载中 $progress%'),
          icon: Icon(Icons.stop_circle),
          onPressed: () {
            toast('暂停成功');
            current.subscription.cancel();
            this._changeDownloadState(current, DownloadState.STOP);
          },
        );
        break;
      case DownloadState.STOP:
        return FlatButton.icon(
            label: Text('已暂停 $progress'),
            icon: Icon(Icons.play_circle_outline),
            onPressed: () {
              this.downloadController.reDownload(current);
              this._changeDownloadState(current, DownloadState.DOWNLOAD);
              toast('继续下载');
            });
        break;
      case DownloadState.COMPLETED:
        return Text('下载完成');
        break;
      case DownloadState.PAUSE:
        return FlatButton.icon(
            label: Text('等待下载 $progress'),
            icon: Icon(Icons.play_circle_outline),
            onPressed: () {
              this.downloadController.reDownload(current);
              current.changeState(DownloadState.DOWNLOAD);
              this._changeDownloadState(current, DownloadState.DOWNLOAD);
              toast('继续下载');
            });
      default:
        Text('下载错误，请重新下载');
    }
  }
}
