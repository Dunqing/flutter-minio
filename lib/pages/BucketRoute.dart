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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minio/models.dart';
import 'package:path/path.dart' show basename, dirname, join;
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
  bool _showFloatingButton = true;
  ScrollController _listViewController = ScrollController();

  @override
  initState() {
    super.initState();
    this.initPrefixScroll();
    this.minioController =
        MinioController(bucketName: widget.bucketName, prefix: widget.prefix);
    this.downloadController =
        createDownloadInstance(minio: this.minioController);
    this.getBucketObjects();
  }

  /// 初始化prefix的滚动条
  initPrefixScroll() async {
    await Future.delayed(Duration.zero);
    try {
      if (this._listViewController?.position?.maxScrollExtent == null) {
        return;
      }
    } catch (err) {
      if (!this._listViewController.hasClients) {
        return;
      }
      return;
    }
    this._listViewController.animateTo(
        this._listViewController.position.maxScrollExtent,
        curve: Curves.linear,
        duration: Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    this._listViewController.dispose();
    super.dispose();
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
    }).catchError((err) {
      closeLoading();
      toastError(err.toString());
      print(err);
    });
  }

  _uploadFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result == null || result?.files == null || result?.files?.length == 0) {
      print('取消了上传');
      return Future.error('cancel');
    }
    List<PlatformFile> files = result.files;
    files.forEach((file) {
      final filename = join(widget.prefix, file.name);
      print('上传filename');
      print(filename);
      this.minioController.uploadFile(filename, file.path).then((string) {
        toast('上传成功');
        this.getBucketObjects(refresh: true);
      }).catchError((err) {
        toastError(err?.message ?? err.toString());
      });
    });
  }

  _jumpPrefix() async {
    showDialog(
        context: this.context,
        builder: (context) {
          close() {
            Navigator.of(context).pop(true);
          }

          String prefix = widget.prefix;
          final _controller = TextEditingController(text: prefix);
          return StatefulBuilder(
              builder: (BuildContext twoContext, StateSetter setState) {
            return AlertDialog(
                title: Title(
                  color: Color(0xff333333),
                  child: Text('跳转路径'),
                ),
                content: TextField(
                  controller: _controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    // 重复忽略
                    if (value == prefix) {
                      return;
                    }
                    setState(() {
                      prefix = value;
                    });
                  },
                ),
                actions: [
                  FlatButton(
                    onPressed: close,
                    child: Text('取消'),
                  ),
                  FlatButton(
                    onPressed: () async {
                      if (prefix == widget.prefix) {
                        toast('当前已在此路径上');
                        return;
                      }

                      /// 加入此判断是用户以这个功能往会跳
                      /// 比如 /123/234 到 /123 那应该替换路由
                      if (prefix.length < widget.prefix.length) {
                        print('往回跳');
                        Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                          return BucketRoute(
                            bucketName: widget.bucketName,

                            /// fix: 如果不补充此斜杠，上传文件后
                            /// 需要主动跳转到当前目录下的/路径下才能看见上传的文件
                            prefix:
                                prefix.endsWith('/') ? prefix : prefix + '/',
                          );
                        }));
                        return;
                      }
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return BucketRoute(
                          bucketName: widget.bucketName,

                          /// fix: 如果不补充此斜杠，上传文件后
                          /// 需要主动跳转到当前目录下的/路径下才能看见上传的文件
                          prefix: prefix.endsWith('/') ? prefix : prefix + '/',
                        );
                      }));
                    },
                    child: Text('跳转'),
                  )
                ]);
          });
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
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (_) => false);
              },
            ),
            TransferButton(downloadController: this.downloadController)
          ],
        ),
        body: _renderRoot(),
        floatingActionButton: FloatingActionExtendButton(
          visible: _showFloatingButton,
          animatedIcon: AnimatedIcons.menu_close,
          children: [
            FloatingActionExtendChild(
                onTap: _jumpPrefix,
                label: '跳转路径',
                child: Icon(Icons.exit_to_app)),
            FloatingActionExtendChild(
                onTap: _uploadFile,
                label: '上传文件',
                child: Icon(Icons.upload_file)),
          ],
        ));
  }

  Widget _renderBreadcrumbs() {
    final _prefix = widget.prefix.split('/');
    final style = TextStyle(fontSize: 20);
    final activeStyle = TextStyle(fontSize: 20, color: Colors.blue);
    List<Widget> _prefixs = [];
    for (var i = 0; i < _prefix.length; i++) {
      final item = _prefix[i];
      if (_prefix[i].isEmpty) {
        continue;
      }

      final index = _prefix[_prefix.length - 1].isEmpty ? 2 : 1;

      _prefixs.add(Center(
          child: Text(item,
              style: i == _prefix.length - index ? activeStyle : style)));
      if (i < _prefix.length - index) {
        _prefixs.add(Icon(Icons.navigate_next));
      }
    }
    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints.expand(height: 50),
      child: ListView(
        controller: _listViewController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        children: [
          Icon(
            Icons.alt_route,
            size: 20,
          ),
          SizedBox(
            width: 10,
            child: null,
          ),
          ..._prefixs
        ],
      ),
    );
  }

  Widget _renderRoot() {
    return Container(
        constraints: BoxConstraints.expand(),
        child: Column(
          children: [
            if (widget.prefix != '') ...[
              _renderBreadcrumbs(),
              Divider(
                height: 1,
              ),
            ],
            Expanded(
              child: this.bucketObjects.length == 0
                  ? _renderZeroContent()
                  : this._renderListObjects(),
            ),
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

  _setFloatingButtonValue(value) {
    if (value == this._showFloatingButton) {
      return;
    }
    setState(() {
      this._showFloatingButton = value;
    });
  }

  Widget _renderListObjects() {
    double _value = 0;
    double _maxValue = 0;
    return NotificationListener<ScrollNotification>(
      onNotification: (event) {
        if (event is ScrollStartNotification) {
          _value = event.metrics.pixels;
          _maxValue = event.metrics.maxScrollExtent;
        } else if (event is ScrollUpdateNotification) {
          _value = event.metrics.pixels;
          print(event.metrics.maxScrollExtent);
        } else if (event is ScrollEndNotification) {
          // 排除无法滚动的情况
          if (_value == 0.0 && _maxValue == 0.0) {
            return false;
          }
          if (_value > _maxValue - 20) {
            _setFloatingButtonValue(false);
          } else {
            _setFloatingButtonValue(true);
          }
        }
        return true;
      },
      child: ListView.builder(
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
      ),
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
    final filePath = '${DownloadController.downloadPath}/${obj.key}';
    this
        .downloadController
        .download(filePath, widget.bucketName, obj.key, now, now, obj.size, 0);
    // this.minioController.downloadFile(filename.key);
  }
}
