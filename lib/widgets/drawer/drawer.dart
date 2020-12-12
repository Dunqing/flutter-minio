import 'package:MinioClient/utils/utils.dart';
import 'package:MinioClient/widgets/drawer/AboutProject.dart';
import 'package:flutter/material.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                    child: Image.asset(
                  'images/pic.gif',
                  width: 60,
                  height: 60,
                )),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Minio For Flutter',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Access Key: minio'),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          title: Text('Github地址'),
          onTap: () {
            launchURL('https://github.com/1247748612/flutter-minio');
          },
        ),
        ListTile(
            title: Text('Minio官网'),
            onTap: () {
              launchURL('https://min.io/');
            }),
        ListTile(
            title: Text('关于本项目'),
            onTap: () {
              aboutProject(context);
            }),
        ListTile(
          title: Text('设置'),
        ),
      ],
    ));
  }
}
