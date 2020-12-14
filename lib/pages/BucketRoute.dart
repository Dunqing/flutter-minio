import 'package:MinioClient/minio/DownloadController.dart';
import 'package:MinioClient/minio/minio.dart';
import 'package:MinioClient/pages/widgets/ConfirmDialog.dart';
import 'package:MinioClient/pages/widgets/ShareDialog.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:MinioClient/widgets/CenterContent/CenterContent.dart';
import 'package:MinioClient/widgets/DialogLoading/DialogLoading.dart';
import 'package:MinioClient/widgets/FloatingActionExtendButton/index.dart';
import 'package:MinioClient/widgets/PreviewNetwork/preview_network.dart';
import 'package:MinioClient/widgets/TransferButton/TransferButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minio/models.dart';
import 'package:share/share.dart';

import 'widgets/ListTileAnimation.dart';

class BucketRoute extends StatefulWidget {
  BucketRoute({Key key, this.bucketName, this.prefix = ''}) : super(key: key);

  final String bucketName;
  final String prefix;

  @override
  _BucketRoute createState() => _BucketRoute();
}

class _BucketRoute extends State<BucketRoute> {
  List<dynamic> bucketObjects = [];
  MinioController minioController;
  DownloadController downloadController;

  initState() {
    super.initState();
    this.minioController =
        MinioController(bucketName: widget.bucketName, prefix: widget.prefix);
    this.downloadController =
        createDownloadInstance(minio: this.minioController);
    this.getBucketObjects();
  }

  getBucketObjects({bool refresh = false}) async {
    final closeLoading = await DialogLoading.showLoading();
    this
        .minioController
        .getBucketObjects(widget.bucketName, widget.prefix)
        .then((res) {
      if (refresh) {
        this.bucketObjects.clear();
      }
      setState(() {
        this.bucketObjects.addAll(res['prefixes']);
        this.bucketObjects.addAll(res['objests']);
        closeLoading();
      });
    });
  }

  _uploadFile() {
    this.minioController.uploadFile().then((string) {
      toast('上传成功');
      this.getBucketObjects(refresh: true);
    }).catchError((err) {
      toastError(err?.message ?? err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.bucketName ?? '所有bucket'),
          actions: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => true);
              },
            ),
            TransferButton(downloadController: this.downloadController)
          ],
        ),
        body: this.bucketObjects.length == 0
            ? _renderZeroContent()
            : Container(child: this._renderListObjects()),
        floatingActionButton: FloatingActionExtendButton(
          animatedIcon: AnimatedIcons.menu_close,
          children: [
            FloatingActionExtendChild(
                onTap: _uploadFile,
                label: '上传文件',
                child: Icon(Icons.upload_file)),
          ],
        ));
  }

  Widget _renderZeroContent() {
    return CenterContent(
      children: [
        Text(
          '还没有上传数据，赶紧来上传吧！',
          style: TextStyle(fontSize: 16),
        ),
        RaisedButton(
          onPressed: _uploadFile,
          color: Colors.blue,
          textColor: Colors.white,
          child: Text('文件上传'),
        )
      ],
    );
  }

  Widget _renderListObjects() {
    return ListView.builder(
      itemCount: this.bucketObjects.length,
      itemBuilder: (context, index) {
        final currentObj = this.bucketObjects[index];
        // 是否为路径
        return ListTileAnimation(
            current: currentObj,
            prefix: widget.prefix,
            handleSelectMenu: this.handleSelectMenu,
            bucketName: widget.bucketName);
      },
    );
  }

  handleSelectMenu(value, currentObj) {
    switch (value) {
      case 'download':
        this._download(currentObj);
        break;
      case 'preview':
        this._preview(currentObj.key);
        break;
      case 'remove':
        this._remove(currentObj.key);
        break;
      case 'share':
        this._share(currentObj.key);
        break;
    }
  }

  void _preview(filename) {
    this.minioController.getPreviewUrl(filename).then((url) {
      print('$filename $url');
      PreviewNetwork(context: this.context).preview(url);
    });
  }

  void _remove(filename) {
    showConfirmDialog(this.context,
        title: '删除文件', content: Text('是否删除$filename?'), onConfirm: () {
      this.minioController.removeFile(filename).then((_) {
        toast('删除成功');
        return this.getBucketObjects(refresh: true);
      });
    });
  }

  void _share(filename) async {
    Future<String> getUrl({int day = 5, hours = 0, minutes = 0}) {
      final expires = day * 60 * 24 * 60 + hours * 60 * 60 + minutes * 60;
      return this
          .minioController
          .presignedGetObject(filename, expires: expires);
    }

    final String url = await getUrl();

    showDialog(
        context: this.context,
        builder: (BuildContext context) {
          return Dialog(
              child: ShareDialog(
                  url: url,
                  copyLink: (int day, int hours, int minutes) {
                    getUrl(day: day, hours: hours, minutes: minutes)
                        .then((url) {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.of(context).pop();
                      toast('复制成功');
                    });
                  },
                  shareLink: (int day, int hours, int minutes) {
                    getUrl(day: day, hours: hours, minutes: minutes)
                        .then((url) {
                      Share.share('Click $url download',
                          subject: 'Share you $filename');
                    });
                  }));
        });
  }

  void _download(Object obj) {
    final now = DateTime.now().millisecond;
    this
        .downloadController
        .insert(widget.bucketName, obj.key, now, now, obj.size, 0);
    // this.minioController.downloadFile(filename.key);
  }
}
