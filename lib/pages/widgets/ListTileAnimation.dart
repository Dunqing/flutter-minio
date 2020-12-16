import 'package:MinioClient/minio/minio.dart';
import 'package:MinioClient/utils/time.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:minio/models.dart';

import '../BucketRoute.dart';

typedef HandleSelectMenu = void Function(String value, Object current);
typedef ChecboxChanged<T, K> = void Function(T etag, K value);

class ListTileAnimation extends StatefulWidget {
  final String prefix;
  final String bucketName;
  final dynamic current;
  final VoidCallback onLongPress;
  final HandleSelectMenu handleSelectMenu;
  final bool selecting;
  final Map<String, bool> selectingValues;
  final ChecboxChanged checkboxChanged;

  bool get isPrefix => current is Prefix;

  ListTileAnimation(
      {Key key,
      @required this.current,
      @required this.bucketName,
      @required this.handleSelectMenu,
      @required this.prefix,
      @required this.onLongPress,
      @required this.selecting,
      @required this.selectingValues,
      @required this.checkboxChanged})
      : super(key: key);

  @override
  _ListTileAnimationState createState() => _ListTileAnimationState();
}

class _ListTileAnimationState extends State<ListTileAnimation> {
  /// 下载动画的偏移
  double bottom = 20.0;
  double left = 20.0;

  /// 滑动距离
  double _width;

  /// 下载动画的显隐
  bool _show = false;

  /// listTile 的leading
  Widget _leading;

  @override
  void initState() {
    // 初始化leading
    this._leading = widget.selecting ? _renderCheckbox() : _renderLeading();
    super.initState();
  }

  @override
  void didUpdateWidget(ListTileAnimation oldWidget) {
    // 更新leading
    setState(() {
      this._leading = widget.selecting ? _renderCheckbox() : _renderLeading();
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // 获取全局宽度
    if (this._width == null) {
      this._width = MediaQuery.of(context).size.width - 50;
    }
    return Container(
        child: Stack(overflow: Overflow.visible, children: [
      ListTile(
          leading: SizedBox(
              width: 30,
              height: 30,
              child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300), child: _leading)),
          title: Text(widget.current.key.replaceAll(widget.prefix, '')),
          subtitle: _renderSubtitle(),
          trailing: widget.isPrefix
              ? IconButton(icon: Icon(Icons.navigate_next), onPressed: null)
              : _renderMoreMenu(widget.current),
          onLongPress: _onLongPress,
          onTap: _onTap),
      _downloadAnimation(),
    ]));
  }

  // 渲染二级title
  Row _renderSubtitle() {
    if (widget.isPrefix) {
      return null;
    }
    return Row(
      children: [
        Text(formatTime('yyyy/MM/dd/ HH:mm', widget.current.lastModified)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('-'),
        ),
        Text(byteToSize(widget.current.size))
      ],
    );
  }

  /// 点击下载按钮的一个动画
  AnimatedPositioned _downloadAnimation() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      child: IgnorePointer(
          child: Opacity(
              opacity: _show ? 1 : 0, child: Icon(Icons.cloud_download))),
      bottom: bottom,
      left: left,
      onEnd: () {
        setState(() {
          this._show = false;
          this.bottom = bottom;
          this.left = left;
        });
      },
    );
  }

  /// 渲染右边的菜单按钮
  _renderMoreMenu(currentObj) {
    return PopupMenuButton(
      tooltip: '菜单',
      onSelected: (value) async {
        if (value == 'download') {
          setState(() {
            this._show = true;
            this.bottom = 30;
            this.left = _width;
          });
        }
        widget.handleSelectMenu(value, currentObj);
      },
      itemBuilder: (buildContext) {
        List<PopupMenuEntry<dynamic>> list = [
          PopupMenuItem(
            child: Row(children: [
              Icon(Icons.preview_sharp),
              Padding(
                child: Text('预览'),
                padding: EdgeInsets.symmetric(
                  horizontal: 5,
                ),
              ),
            ]),
            value: 'preview',
          ),
          PopupMenuItem(
            child: Row(children: [
              Icon(Icons.download_sharp),
              Padding(
                child: Text('下载'),
                padding: EdgeInsets.symmetric(
                  horizontal: 5,
                ),
              ),
            ]),
            value: 'download',
          ),
          PopupMenuItem(
              child: Row(children: [
                Icon(Icons.share_sharp),
                Padding(
                  child: Text('分享'),
                  padding: EdgeInsets.symmetric(
                    horizontal: 5,
                  ),
                ),
              ]),
              value: 'share'),
          PopupMenuItem(
              child: Row(children: [
                Icon(Icons.delete_sharp),
                Padding(
                  child: Text('删除'),
                  padding: EdgeInsets.symmetric(
                    horizontal: 5,
                  ),
                ),
              ]),
              value: 'remove')
        ];
        return list;
      },
    );
  }

  /// 渲染正常的leading
  Widget _renderLeading() {
    final obj = widget.current;
    final key = obj.key;
    if (obj is Prefix) {
      return Icon(Icons.folder);
    }
    if (key is String) {
      print(key.lastIndexOf('.'));
      final index = key.lastIndexOf('.');
      if (index == -1) {
        return Icon(Icons.text_snippet_rounded);
      }
      final ext = key.substring(key.lastIndexOf('.') + 1);
      switch (ext) {
        case 'mp4':
        case 'avi':
          return Icon(Icons.ondemand_video_rounded);
        case 'mp3':
          return Icon(Icons.audiotrack_rounded);
        case 'jpg':
        case 'png':
        case 'jpeg':
          return Icon(Icons.image_rounded);
        case 'pdf':
          return Icon(Icons.picture_as_pdf_rounded);
        case 'md':
          return Icon(Icons.article);
        default:
          return Icon(Icons.text_snippet_rounded);
      }
    } else {
      return Icon(Icons.text_snippet_rounded);
    }
  }

  /// 渲染多选框
  _renderCheckbox() {
    // 排除路径
    if (widget.isPrefix) {
      return this._renderLeading();
    }
    final Object current = widget.current;
    return AbsorbPointer(
      child: SizedBox(
        width: 25,
        height: 25,
        child: Checkbox(
          value: widget.selectingValues[current.eTag] ?? false,
          // onChanged: (value) => (widget.checkboxChanged(current.eTag, value)),
          onChanged: (value) => null,
        ),
      ),
    );
  }

  /// 点击
  void _onTap() async {
    // 开启多选后
    if (widget.selecting) {
      // 禁用路径跳转
      if (widget.isPrefix) {
        return;
      }
      widget.checkboxChanged(
          widget.current.eTag,
          widget.selectingValues[widget.current.eTag] is bool
              ? !widget.selectingValues[widget.current.eTag]
              : true);
    }

    if (widget.isPrefix) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => BucketRoute(
                bucketName: widget.bucketName,
                prefix: widget.current.prefix,
              )));
    }
  }

  /// 长按事件
  void _onLongPress() {
    // 长安排除跳转路径
    if (widget.isPrefix) {
      return;
    }
    widget.onLongPress();
    widget.checkboxChanged(
        widget.current.eTag,
        widget.selectingValues[widget.current.eTag] is bool
            ? !widget.selectingValues[widget.current.eTag]
            : true);
  }
}
