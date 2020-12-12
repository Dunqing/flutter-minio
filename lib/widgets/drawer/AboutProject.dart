import 'package:flutter/material.dart';

const textList = [
  '本项目基于https://pub.flutter-io.cn/packages/minio实现的，此项目是我的第一个Flutter项目。',
  '我是学前端的，对flutter感兴趣，并且想做一个开源项目，为自己之后找工作做准备。'
      '之前有部署过minio，知道有web端，了解到此项目还没有flutter的实现，但是已有sdk实现。所以选择做这个项目',
  '我没有系统的看过flutter和dart的文档。此项目在边看文档，边查资料下完成的。可能有很多功能实现的不好，并且可能有性能问题。'
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
