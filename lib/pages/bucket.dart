import 'package:MinioClient/minio/minio.dart';
import 'package:MinioClient/widgets/FloatingActionExtendButton/index.dart';
import 'package:MinioClient/widgets/PreviewNetwork/preview_network.dart';
import 'package:flutter/material.dart';
import 'package:minio/models.dart';

class BucketRoute extends StatefulWidget {
  BucketRoute({Key key, this.bucketName, this.prefix = ''}) : super(key: key);

  final String bucketName;
  final String prefix;

  @override
  _BucketRoute createState() => _BucketRoute();
}

class _BucketRoute extends State<BucketRoute> {
  List<Bucket> buckets = [];
  List<dynamic> bucketObjects = [];
  MinioController minioController;

  initState() {
    super.initState();
    this.minioController = MinioController(widget.bucketName, widget.prefix);
    if (widget != null && widget.bucketName != null) {
      this.getBucketObjects();
    } else {
      this.minioController.getListBuckets().then((value) {
        this.setState(() {
          this.buckets = value.toList();
        });
      });
    }
  }

  getBucketObjects({bool refresh = false}) async {
    this
        .minioController
        .getBucketObjects(widget.bucketName, widget.prefix)
        .then((res) {
      if (refresh) {
        this.bucketObjects.clear();
      }
      setState(() {
        print(res['prefixes']);
        this.bucketObjects.addAll(res['prefixes']);
        this.bucketObjects.addAll(res['objests']);
      });
    });
  }

  _uploadFile() {
    this.minioController.uploadFile().then((string) {
      this.getBucketObjects(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.bucketName ?? 'All Buckets'),
          actions: [],
        ),
        body: Container(child: this._renderListObjects()),
        floatingActionButton: FloatingActionExtendButton(
          animatedIcon: AnimatedIcons.menu_close,
          children: [
            if (widget.bucketName != null)
              FloatingActionExtendChild(
                  onTap: _uploadFile,
                  label: '上传文件',
                  child: Icon(Icons.upload_file)),
            FloatingActionExtendChild(
                label: '创建Bucket',
                child: Icon(Icons.create_new_folder_rounded)),
          ],
        ));
  }

  Widget _renderBucket(index) {
    return ListTile(
      leading: Icon(Icons.folder),
      title: Text(this.buckets[index].name),
      trailing: new Icon(Icons.navigate_next, color: Colors.blueGrey),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                BucketRoute(bucketName: this.buckets[index].name)));
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
        default:
          return Icon(Icons.text_snippet_rounded);
      }
    } else {
      return Icon(Icons.text_snippet_rounded);
    }
  }

  Widget _renderListObjects() {
    return ListView.builder(
      itemCount: widget.bucketName != null
          ? this.bucketObjects.length
          : this.buckets.length,
      itemBuilder: (context, index) {
        var element;
        if (widget.bucketName != null) {
          final currentObj = this.bucketObjects[index];
          // 是否为路径
          final isPrefix = currentObj is Prefix;

          element = ListTile(
            leading: _renderLeading(currentObj),
            title: Text(currentObj.key.replaceAll(widget.prefix, '')),
            subtitle: isPrefix
                ? null
                : Row(
                    children: [
                      // Text(currentObj.lastModified.toString()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text('-'),
                      ),
                      Text(currentObj.size.toString())
                    ],
                  ),
            trailing: isPrefix
                ? IconButton(icon: Icon(Icons.navigate_next), onPressed: null)
                : _renderMoreMenu(currentObj),
            onTap: () async {
              if (isPrefix) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => BucketRoute(
                          bucketName: widget.bucketName,
                          prefix: currentObj.prefix,
                        )));
              }
            },
          );
        } else {
          element = this._renderBucket(index);
        }
        return element;
      },
    );
  }

  _renderMoreMenu(currentObj) {
    return PopupMenuButton(
      onSelected: (value) async {
        print('value $value');
        switch (value) {
          case 'download':
            this.minioController.downloadFile(currentObj.key);
            break;
          case 'preview':
            this._preview(currentObj.key);
            break;
        }
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
              value: 'delete')
        ];
        return list;
      },
    );
  }

  void _preview(filename) {
    print(filename);
    this.minioController.getPreviewUrl(filename).then((url) {
      PreviewNetwork(context: this.context).preview(url);
    });
  }
}
