import 'package:MinioClient/minio/DownloadController.dart';
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
                    subtitle: _renderSubtitle(current),
                    trailing: _renderTrailing(current));
              },
            ),
          );
        });
  }

  _renderSubtitle(DownloadFileInstance current) {
    String text;

    switch (current.state) {
      case DownloadState.DOWNLOAD:
        text =
            '已下载 ${byteToSize(current.downloadSize)} | 需下载 ${byteToSize(current.fileSize)}';
        break;
      case DownloadState.COMPLETED:
        text = '下载完成，可单击预览';
        break;
      case DownloadState.ERROR:
        text = 'Error: ${current.stateText}';
        break;
      case DownloadState.PAUSE:
        text = '正在等待下载，可单击插队';
        break;
      case DownloadState.STOP:
        text = '已停止下载，需重新下载请单击';
        break;
    }
    return Text(text);
  }

  _renderTrailing(DownloadFileInstance current) {
    final progress = (100 * (current.downloadSize / current.fileSize)).toInt();
    switch (current.state) {
      case DownloadState.DOWNLOAD:
        return FlatButton.icon(
          label: Text('暂停'),
          icon: Icon(Icons.stop_circle),
          onPressed: () {
            toast('暂停成功');
            this.downloadController.stopDownload(current);
          },
        );
        break;
      case DownloadState.STOP:
        return FlatButton.icon(
            label: Text('下载'),
            icon: Icon(Icons.play_circle_outline),
            onPressed: () {
              this.downloadController.reDownload(current);
              toast('继续下载');
            });
        break;
      case DownloadState.COMPLETED:
        return FlatButton.icon(
            label: Text('预览'),
            icon: Icon(Icons.play_circle_outline),
            onPressed: () {
              this.downloadController.advanceDownload(current);
              toast('继续下载');
            });
        break;
      case DownloadState.PAUSE:
        return FlatButton.icon(
            label: Text('等待'),
            icon: Icon(Icons.play_circle_outline),
            onPressed: () {
              this.downloadController.advanceDownload(current);
              toast('继续下载');
            });
      default:
        Text('下载错误，请重新下载');
    }
  }
}
