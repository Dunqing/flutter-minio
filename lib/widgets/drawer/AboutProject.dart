import 'package:flutter/material.dart';

const textList = [
  '本项目基于https://pub.flutter-io.cn/packages/minio实现的，且该sdk不支持中文字符',
  '此项目的sdk无法完成上传进度监听，和取消下载请求，可能会造成性能损耗',
  '此项目写的并不好，很多好用的widget或者api未用上，采用状态库是rxdart',
  '此下载功能和进度动态更新是自己想出来的，不知道是否为标准的下载方法',
  '我没有系统的看过flutter和dart的文档。此项目在边看文档，边查资料下完成的',
];

aboutProject(context) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
            child: AlertDialog(
                title: Text('关于本项目'),
                actions: [
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('关闭'),
                  ),
                ],
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...textList.map((text) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 3.0),
                          child: Text(text),
                        ))
                  ],
                )));
      });
}
