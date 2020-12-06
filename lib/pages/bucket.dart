import 'package:MinioClient/minio/minio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:minio/io.dart';
import 'package:minio/models.dart';
import 'package:path_provider/path_provider.dart';

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

  initState() {
    super.initState();
    if (widget != null && widget.bucketName != null) {
      this.getBucketObjects();
    } else {
      minio.listBuckets().then((value) {
        setState(() {
          this.buckets = value.toList();
        });
      });
    }
  }

  getBucketObjects() async {
    print('${widget.bucketName}, ${widget.prefix}');
    final objects = minio.listObjectsV2(widget.bucketName,
        prefix: widget.prefix, recursive: false);
    await for (var obj in objects) {
      final prefixs = obj.prefixes.map((e) {
        final index = e.lastIndexOf('/') + 1;
        final prefix = e.substring(0, index);
        final key = e;
        return Prefix(key: key, prefix: prefix, isPrefix: true);
      }).toList();
      setState(() {
        this.bucketObjects.clear();
        this.bucketObjects.addAll(prefixs);
        obj.objects.forEach((element) {
          print('${element.key}， ${widget.prefix}');
          element.key = element.key.replaceAll(widget.prefix, '');
        });
        this.bucketObjects.addAll(obj.objects);
      });
      print('end');
    }
  }

  _uploadFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result == null || result?.files == null || result?.files?.length == 0) {
      print('取消了上传');
      return;
    }
    final file = result.files[0];
    minio.fPutObject(widget.bucketName, file.name, file.path).then((value) {
      this.getBucketObjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.bucketName ?? 'All Buckets'),
          actions: [
            FlatButton.icon(
              icon: Icon(Icons.home),
              onPressed: null,
              label: Text(''),
            ),
            FlatButton.icon(
              icon: Icon(Icons.add_box),
              onPressed: null,
              label: Text(''),
            ),
          ],
        ),
        body: Container(
          child: ListView.builder(
            itemCount: widget.bucketName != null
                ? this.bucketObjects.length
                : this.buckets.length,
            itemBuilder: (context, index) {
              var element;
              if (widget.bucketName != null) {
                final currentObj = this.bucketObjects[index];
                final isPrefix = currentObj is Prefix;
                element = ListTile(
                  title: Text(currentObj.key),
                  subtitle: isPrefix
                      ? null
                      : Row(
                          children: [
                            Text(currentObj.lastModified.toString()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text('-'),
                            ),
                            Text(currentObj.size.toString())
                          ],
                        ),
                  trailing: isPrefix
                      ? IconButton(
                          icon: Icon(Icons.navigate_next), onPressed: null)
                      : PopupMenuButton(
                          onSelected: (value) async {
                            switch (value) {
                              case 'download':
                                final dir = await getExternalStorageDirectory();
                                print(
                                    'dir, $dir ${widget.bucketName} ${widget.prefix + currentObj.key}');
                                minio
                                    .fGetObject(
                                        widget.bucketName,
                                        widget.prefix + currentObj.key,
                                        '${dir.path}/${widget.prefix + currentObj.key}')
                                    .then((value) {
                                  print('download ok');
                                });
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
                        ),
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
                element = ListTile(
                  title: Text(this.buckets[index].name),
                  trailing:
                      new Icon(Icons.navigate_next, color: Colors.blueGrey),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            BucketRoute(bucketName: this.buckets[index].name)));
                  },
                );
              }
              return element;
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: _uploadFile, child: Icon(Icons.file_upload)));
  }
}
