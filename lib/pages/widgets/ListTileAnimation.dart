import 'package:MinioClient/minio/minio.dart';
import 'package:MinioClient/pages/bucket.dart';
import 'package:MinioClient/utils/time.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:flutter/material.dart';

typedef HandleSelectMenu = void Function(String value, Object current);

class ListTileAnimation extends StatefulWidget {
  final String prefix;
  final String bucketName;
  final dynamic current;
  final HandleSelectMenu handleSelectMenu;

  bool get isPrefix => current is Prefix;

  ListTileAnimation(
      {Key key,
      this.current,
      this.bucketName,
      this.handleSelectMenu,
      this.prefix})
      : super(key: key);

  @override
  _ListTileAnimationState createState() => _ListTileAnimationState();
}

class _ListTileAnimationState extends State<ListTileAnimation> {
  double bottom = 20.0;
  double left = 20.0;
  // 滑动距离
  double width;

  bool show = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (this.width == null) {
      this.width = MediaQuery.of(context).size.width - 50;
    }
    return Container(
        child: Stack(overflow: Overflow.visible, children: [
      ListTile(
          leading: _renderLeading(widget.current),
          title: Text(widget.current.key.replaceAll(widget.prefix, '')),
          subtitle: widget.isPrefix
              ? null
              : Row(
                  children: [
                    Text(formatTime(
                        'yyyy/MM/dd/ HH:mm', widget.current.lastModified)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text('-'),
                    ),
                    Text(byteToSize(widget.current.size))
                  ],
                ),
          trailing: widget.isPrefix
              ? IconButton(icon: Icon(Icons.navigate_next), onPressed: null)
              : _renderMoreMenu(widget.current),
          onTap: () async {
            if (widget.isPrefix) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => BucketRoute(
                        bucketName: widget.bucketName,
                        prefix: widget.current.prefix,
                      )));
            }
          }),
      AnimatedPositioned(
        duration: Duration(milliseconds: 300),
        child: IgnorePointer(
            child: Opacity(
                opacity: show ? 1 : 0, child: Icon(Icons.cloud_download))),
        bottom: bottom,
        left: left,
        onEnd: () {
          setState(() {
            this.show = false;
            this.bottom = 20.0;
            this.left = 20.0;
          });
        },
      ),
    ]));
  }

  _renderMoreMenu(currentObj) {
    return PopupMenuButton(
      tooltip: '菜单',
      onSelected: (value) async {
        if (value == 'download') {
          setState(() {
            this.show = true;
            this.bottom = 30;
            this.left = width;
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

  Widget _renderLeading(obj) {
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
}
