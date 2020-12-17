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
  final String bucketName;

  final String prefix;
  BucketRoute({Key key, this.bucketName, this.prefix = ''}) : super(key: key);

  @override
  _BucketRoute createState() => _BucketRoute();
}

enum SelectingAction { SelectAll, CancelAll, Download, Delete }

class _BucketRoute extends State<BucketRoute> {
  List<dynamic> bucketObjects = [];
  MinioController minioController;
  DownloadController downloadController;

  /// 展示右上角的悬浮按钮
  bool _showFloatingButton = true;

  /// 多选状态
  bool _selecting = false;

  /// 多选值
  Map<String, bool> _selectingValues = new Map();

  /// 面包屑滚动调
  ScrollController _listViewController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.bucketName ?? '所有bucket'),
          actions: _selecting
              ? _renderSelectingActions()
              : [
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

  @override
  void dispose() {
    this._listViewController.dispose();
    super.dispose();
  }

  getBucketObjects({bool refresh = false}) async {
    final closeLoading = DialogLoading.showLoading(this.context);
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
        // closeLoading();
      });
    }).catchError((err) {
      closeLoading();
      toastError(err.toString());
      print(err);
    });
  }

  handleSelectMenu(value, currentObj) {
    // 当是多选时应该关闭多选
    if (this._selecting == true) {
      setState(() {
        this._selecting = false;
      });
    }
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

  /// 初始化prefix的滚动条
  initPrefixScroll() async {
    // 排除没有面包屑的情况
    if (widget.prefix.isEmpty) {
      return;
    }
    await Future.delayed(Duration.zero);
    if (this._listViewController?.position?.maxScrollExtent == null) {
      return;
    }
    this._listViewController.animateTo(
        this._listViewController.position.maxScrollExtent,
        curve: Curves.linear,
        duration: Duration(milliseconds: 300));
  }

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

  void _checkboxChanged(key, value) {
    setState(() {
      this._selectingValues[key] = value;
    });
  }

  _closeSelecting() {
    setState(() {
      this._selectingValues.clear();
      this._selecting = false;
    });
  }

  void _download(Object obj) {
    final now = DateTime.now().millisecond;
    final filePath = '${DownloadController.downloadPath}/${obj.key}';
    this.downloadController.download(
        filePath, widget.bucketName, obj.key, obj.eTag, now, now, obj.size, 0);
    // this.minioController.downloadFile(filename.key);
  }

  /// 是否已勾选
  bool _hasSelected(item) {
    if (item is Prefix) {
      return false;
    }
    final key = '${item.key}-${item.eTag}';
    if (item is Prefix) {
      return false;
    }
    if (!this._selectingValues.containsKey(key)) {
      return false;
    }
    if (this._selectingValues[key] == false) {
      return false;
    }
    return true;
  }

  /// 跳转路径按钮
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
                      routeBuilder(context) {
                        return BucketRoute(
                          bucketName: widget.bucketName,

                          /// fix: 如果不补充此斜杠，上传文件后
                          /// 需要主动跳转到当前目录下的/路径下才能看见上传的文件
                          prefix: prefix.endsWith('/') ? prefix : prefix + '/',
                        );
                      }

                      Navigator.of(context).pop();

                      /// 加入此判断是用户以这个功能往会跳
                      /// 比如 /123/234 到 /123 那应该替换路由
                      if (prefix.length < widget.prefix.length) {
                        print('往回跳');
                        Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: routeBuilder));
                        return;
                      }
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: routeBuilder));
                    },
                    child: Text('跳转'),
                  )
                ]);
          });
        });
  }

  /// animationlisttile的长按
  void _onLongPress() {
    print('长按');
    setState(() {
      this._selecting = true;
    });
  }

  void _preview(filename) {
    this.minioController.getPreviewUrl(filename).then((url) {
      print('$filename $url');
      PreviewNetwork(context: this.context).preview(url);
    });
  }

  void _remove(filenames) {
    final text =
        filenames is String ? '是否删除${basename(filenames)}?' : '是否删除选中的文件';
    showConfirmDialog(this.context, title: '删除文件', content: Text(text),
        onConfirm: () async {
      final closeLoading = await DialogLoading.showLoading(this.context);
      return this.minioController.removeFile(filenames).then((_) {
        toast('删除成功');
        closeLoading();
        return this.getBucketObjects(refresh: true);
      }).catchError((err) {
        closeLoading();
        toastError(err.toString());
      });
    });
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
              checkboxChanged: _checkboxChanged,
              selectingValues: _selectingValues,
              selecting: _selecting,
              current: currentObj,
              prefix: widget.prefix,
              handleSelectMenu: this.handleSelectMenu,
              onLongPress: _onLongPress,
              bucketName: widget.bucketName);
        },
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

  List<Widget> _renderSelectingActions() {
    return [
      Tooltip(
        message: '取消多选',
        child: IconButton(
          icon: Icon(Icons.cancel),
          onPressed: () {
            setState(() {
              this._closeSelecting();
            });
          },
        ),
      ),
      PopupMenuButton(
        tooltip: '操作',
        onSelected: (value) {
          switch (value) {
            case SelectingAction.SelectAll:
              setState(() {
                this.bucketObjects.forEach((item) {
                  if (item is Prefix) {
                    return;
                  }
                  if (item is Object) {
                    this._selectingValues['${item.key}-${item.eTag}'] = true;
                  }
                });
              });
              break;
            case SelectingAction.CancelAll:
              setState(() {
                this._selectingValues.clear();
              });
              break;
            case SelectingAction.Download:
              this.bucketObjects.forEach((item) {
                if (this._hasSelected(item)) {
                  this._download(item);
                }
              });
              this._closeSelecting();
              break;
            case SelectingAction.Delete:
              List<String> filenames = [];
              this.bucketObjects.forEach((item) {
                if (this._hasSelected(item)) {
                  filenames.add(item.key);
                }
              });
              this._remove(filenames);
              this._closeSelecting();
              break;
          }
        },
        itemBuilder: (context) {
          List<PopupMenuEntry<dynamic>> list = [
            PopupMenuItem(
              child: Text('选择全部'),
              value: SelectingAction.SelectAll,
            ),
            PopupMenuItem(
              child: Text('取消选择'),
              value: SelectingAction.CancelAll,
            ),
            PopupMenuItem(
              child: Text('下载勾选'),
              value: SelectingAction.Download,
            ),
            PopupMenuItem(
              child: Text('删除勾选'),
              value: SelectingAction.Delete,
            ),
          ];
          return list;
        },
      )
    ];
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
}
