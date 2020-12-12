import 'package:MinioClient/minio/minio.dart';
import 'package:flutter/material.dart';
import 'package:minio/models.dart';

class UploadPage extends StatefulWidget {
  UploadPage({Key key}) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  MinioController minio;
  List<IncompleteUpload> uploadList = [];
  List<Bucket> bucketList = [];

  @override
  void initState() {
    // this.minio = MinioController();
    // this.getBucketList().then((_) {
    //   this.getListObjects(this.bucketList[0].name);
    // });
    super.initState();
  }

  Future<List<Bucket>> getBucketList() {
    return this.minio.getListBuckets().then((res) {
      this.bucketList = res;
      return res;
    });
  }

  getListObjects(String bucketName) {
    this.minio.listIncompleteUploads(bucketName: bucketName).then((res) {
      print(res);
      // this.uploadList = res;
    });
    // listIncompleteUploads
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: 20);
    return Container(
      padding: EdgeInsets.all(20),
      constraints: BoxConstraints.expand(),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('因为dart的"minio"的sdk不是官方实现的，有诸多问题，无法完成此功能。', style: textStyle),
          Text(''),
          Text('上传接口可以使用，但不能知道上传进度。请尽量不要上传大文件！', style: textStyle)
        ],
      ),
    );
    //  ListView.builder(
    //     itemCount: this.uploadList.length,
    //     itemBuilder: (BuildContext context, int index) {
    //       final current = this.uploadList[index];
    //       return ListTile(
    //         title: Text('${current.upload.key}'),
    //         subtitle: Text('已上传 ${byteToSize(current.size)}'),
    //       );
    //     });
  }
}
