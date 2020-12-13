import 'package:MinioClient/minio/DownloadController.dart';
import 'package:MinioClient/pages/widgets/ConfirmDialog.dart';
import 'package:MinioClient/utils/file.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
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
          return data.length == 0
              ? Container(
                  alignment: Alignment.center,
                  child: Text(
                    '你还没下载过东西！',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : Container(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final current = data[index];
                      final filename = current.filename.split('/').last;
                      return Column(
                        children: [
                          ListTile(
                              title: Text(filename),
                              subtitle: _renderSubtitle(current),
                              trailing: _renderTrailing(current)),
                          if (current.state == DownloadState.DOWNLOAD)
                            LinearProgressIndicator(
                              value: current.downloadSize / current.fileSize,
                            )
                        ],
                      );
                    },
                  ),
                );
        });
  }

  _renderSubtitle(DownloadFileInstance current) {
    final progress = (100 * (current.downloadSize / current.fileSize)).toInt();
    String text;

    TextStyle textStyle;
    switch (current.state) {
      case DownloadState.DOWNLOAD:
        text =
            '${byteToSize(current.downloadSize)}/${byteToSize(current.fileSize)} 已完成$progress%';
        break;
      case DownloadState.COMPLETED:
        text = '下载完成，可进行预览';
        break;
      case DownloadState.ERROR:
        text = 'Error: ${current.stateText}';
        textStyle = TextStyle(color: Colors.red);
        break;
      case DownloadState.PAUSE:
        text = '正在等待下载';
        break;
      case DownloadState.STOP:
        text = '已停止下载 已完成$progress%';
        break;
    }
    return Text(
      text,
      style: textStyle,
    );
  }

  _renderTrailing(DownloadFileInstance current) {
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
            icon: Icon(Icons.preview_outlined),
            onPressed: () {
              OpenFile.open(current.filePath);
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
      case DownloadState.ERROR:
        return FlatButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('重新下载'),
            onPressed: () {
              showConfirmDialog(this.context,
                  title: '重新下载', content: Text('是否要重新下载此文件？'), onConfirm: () {
                removeFile(current.filePath).then((res) {
                  this.downloadController.reDownload(current);
                });
              });
            });
      default:
        Text('下载错误，请重新下载');
    }
  }
}
