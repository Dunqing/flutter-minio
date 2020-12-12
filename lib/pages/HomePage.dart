import 'package:MinioClient/minio/DownloadController.dart';
import 'package:MinioClient/minio/minio.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:MinioClient/widgets/TransferButton/TransferButton.dart';
import 'package:MinioClient/widgets/drawer/drawer.dart';
import 'package:flutter/material.dart';
import 'package:minio/minio.dart';
import 'package:minio/models.dart';

import 'bucket.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Bucket> buckets = [];
  MinioController minioController;
  DownloadController downloadController;

  initState() {
    super.initState();
    this.minioController = MinioController();
    this.downloadController = createDownloadInstance();
    this.getBucketList();
  }

  getBucketList() {
    this.minioController.getListBuckets().then((value) {
      this.setState(() {
        this.buckets = value.toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [TransferButton(downloadController: this.downloadController)],
      ),
      drawer: DrawerWidget(),
      body: Container(
        child: _renderListView(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBucket,
        tooltip: '创建Bucket',
        child: Icon(Icons.create_new_folder_rounded),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _createBucket() {
    showDialog(
        context: this.context,
        builder: (context) {
          close() {
            Navigator.of(context).pop(true);
          }

          String bucketName = '';
          return StatefulBuilder(
              builder: (BuildContext twoContext, StateSetter setState) {
            return AlertDialog(
                title: Title(
                  color: Color(0xff333333),
                  child: Text('创建Bucket'),
                ),
                content: TextField(
                  autofocus: true,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    setState(() {
                      bucketName = value;
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
                      try {
                        MinioInvalidBucketNameError.check(bucketName);
                      } catch (e) {
                        toast('请正确填写bucket name！');
                        return;
                      }
                      final hasExists =
                          await this.minioController.buckerExists(bucketName);
                      if (hasExists) {
                        toast('bucket已存在');
                        return;
                      }
                      this.minioController.createBucket(bucketName).then((_) {
                        toast('创建成功');
                        close();
                        this.getBucketList();
                      });
                    },
                    child: Text('创建'),
                  )
                ]);
          });
        });
  }

  Widget _renderListView() {
    return ListView.builder(
      itemCount: this.buckets.length,
      itemBuilder: (context, index) {
        return this._renderBucket(index);
      },
    );
  }

  Widget _renderBucket(index) {
    final bucket = this.buckets[index];
    return GestureDetector(
        onLongPress: () {
          showDialog(
              context: this.context,
              builder: (context) {
                close() {
                  Navigator.of(context).pop();
                }

                return AlertDialog(
                  title: Text('删除'),
                  content: Text('是否删除${bucket.name}? bucket里面的所有文件都会被删除!'),
                  actions: [
                    FlatButton(
                      onPressed: close,
                      child: Text('取消'),
                    ),
                    FlatButton(
                      onPressed: () {
                        this
                            .minioController
                            .removeBucket(bucket.name)
                            .then((_) {
                          close();
                          this.getBucketList();
                          toast('删除成功');
                        });
                      },
                      child: Text('删除'),
                    )
                  ],
                );
              });
        },
        child: ListTile(
          leading: Icon(Icons.folder),
          title: Text(bucket.name),
          trailing: new Icon(Icons.navigate_next, color: Colors.blueGrey),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => BucketRoute(bucketName: bucket.name)));
          },
        ));
  }
}
