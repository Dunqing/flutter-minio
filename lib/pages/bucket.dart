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
  List<Object> bucketObjects = [];

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
    final objects =
        minio.listObjectsV2(widget.bucketName, prefix: widget.prefix);
    await for (var obj in objects) {
      setState(() {
        this.bucketObjects.clear();
        this.bucketObjects.addAll(obj.objects);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bucketName ?? 'All Buckets'),
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
              element = ListTile(
                title: Text(currentObj.key),
                subtitle: Row(
                  children: [
                    Text(currentObj.lastModified.toString()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('-'),
                    ),
                    Text(currentObj.size.toString())
                  ],
                ),
                trailing:
                    new Icon(Icons.download_sharp, color: Colors.blueGrey),
                onTap: () async {
                  final dir = await getExternalStorageDirectory();
                  print('dir, $dir');
                  minio
                      .fGetObject(widget.bucketName, currentObj.key,
                          '${dir.path}/${currentObj.key}')
                      .then((value) {
                    print('download ok');
                  });
                  // Navigator.of(context).push(MaterialPageRoute(
                  //     builder: (context) => BucketRoute(
                  //         bucketName: this.bucketObjects[index].key)));
                },
              );
            } else {
              element = ListTile(
                title: Text(this.buckets[index].name),
                trailing: new Icon(Icons.navigate_next, color: Colors.blueGrey),
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
        onPressed: () async {
          FilePickerResult result = await FilePicker.platform.pickFiles();
          if (result == null ||
              result?.files == null ||
              result?.files?.length == 0) {
            print('取消了上传');
            return;
          }
          final file = result.files[0];
          minio
              .fPutObject(widget.bucketName, file.name, file.path)
              .then((value) {
            this.getBucketObjects();
          });
        },
        tooltip: '上传文件',
        child: Icon(Icons.upload_rounded),
      ),
    );
  }
}
