import 'dart:ui';

import 'package:flutter/material.dart';

typedef CopyLinkCallback = void Function(int day, int hours, int minutes);

class ShareDialog extends StatefulWidget {
  final String url;
  final CopyLinkCallback copyLink;
  final CopyLinkCallback shareLink;
  ShareDialog(
      {Key key, @required this.url, @required this.copyLink, this.shareLink})
      : super(key: key);

  @override
  _ShareDialogState createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  int day = 5;
  int hours = 0;
  int minutes = 0;

  _increment(String type) {
    if (type != 'day' && this.day == 7) {
      return;
    }

    switch (type) {
      case 'day':
        setState(() {
          this.day = this.day == 7 ? 1 : this.day + 1;
          if (this.day == 7) {
            this.hours = 0;
            this.minutes = 0;
          }
        });
        break;
      case 'hours':
        setState(() {
          this.hours = this.hours == 23 ? this.hours : this.hours + 1;
        });
        break;
      case 'minutes':
        setState(() {
          this.minutes = this.minutes == 59 ? this.minutes : this.minutes + 1;
        });
        break;
      default:
        throw '请检查要添加的类型';
    }
  }

  _decrement(String type) {
    switch (type) {
      case 'day':
        setState(() {
          this.day = this.day == 1 ? 7 : this.day - 1;
        });
        break;
      case 'hours':
        setState(() {
          this.hours = this.hours == 0 ? this.hours : this.hours - 1;
        });
        break;
      case 'minutes':
        setState(() {
          this.minutes = this.minutes == 0 ? this.minutes : this.minutes - 1;
        });
        break;
      default:
        throw '请检查要decrement的类型';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: BoxConstraints.expand(height: 430),
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '分享资源',
              style: TextStyle(
                  color: const Color(0xff333333),
                  fontSize: 16,
                  decoration: TextDecoration.none),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Row(
                children: [
                  Text(
                    '分享链接',
                    style: TextStyle(
                        color: const Color(0xFF8e8e8e),
                        fontSize: 14,
                        decoration: TextDecoration.none),
                  ),
                  GestureDetector(
                      onTap: () {
                        widget.copyLink(this.day, this.hours, this.minutes);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          '点击复制链接',
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              decoration: TextDecoration.none),
                        ),
                      )),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Scrollbar(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Color(0xffeeeeee))),
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: SelectableText(
                            widget.url,
                            style: TextStyle(
                                color: const Color(0xFF8e8e8e),
                                fontSize: 13,
                                decoration: TextDecoration.none),
                          )))),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Text(
                '过期时间（最长七天）',
                style: TextStyle(
                    color: const Color(0xFF8e8e8e),
                    fontSize: 14,
                    decoration: TextDecoration.none),
              ),
            ),
            Padding(
                padding: EdgeInsets.only(top: 10),
                child: SizedBox(
                    width: double.infinity,
                    height: 140,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 40,
                                child: IconButton(
                                  color: Color(0xFF8e8e8e),
                                  icon: Icon(Icons.expand_less),
                                  onPressed: () => _increment('day'),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  constraints: BoxConstraints.expand(),
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Color(0xffeeeeee))),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '天',
                                        style: TextStyle(
                                          color: const Color(0xFF8e8e8e),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 1.0),
                                        child: Text(
                                          '$day',
                                          style: TextStyle(
                                            color: const Color(0xff333333),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                child: IconButton(
                                  color: Color(0xFF8e8e8e),
                                  icon: Icon(Icons.expand_more),
                                  onPressed: () => _decrement('day'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 40,
                                child: IconButton(
                                  color: Color(0xFF8e8e8e),
                                  icon: Icon(Icons.expand_less),
                                  onPressed: () => _increment('hours'),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  constraints: BoxConstraints.expand(),
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Color(0xffeeeeee))),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '小时',
                                        style: TextStyle(
                                          color: const Color(0xFF8e8e8e),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 1.0),
                                        child: Text(
                                          '$hours',
                                          style: TextStyle(
                                            color: const Color(0xff333333),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                child: IconButton(
                                  color: Color(0xFF8e8e8e),
                                  icon: Icon(Icons.expand_more),
                                  onPressed: () => _decrement('hours'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 40,
                                child: IconButton(
                                  color: Color(0xFF8e8e8e),
                                  icon: Icon(Icons.expand_less),
                                  onPressed: () => _increment('minutes'),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  constraints: BoxConstraints.expand(),
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Color(0xffeeeeee))),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '分钟',
                                        style: TextStyle(
                                          color: const Color(0xFF8e8e8e),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 1.0),
                                        child: Text(
                                          '$minutes',
                                          style: TextStyle(
                                            color: const Color(0xff333333),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                child: IconButton(
                                  color: Color(0xFF8e8e8e),
                                  icon: Icon(Icons.expand_more),
                                  onPressed: () => _decrement('minutes'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ))),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                    onPressed: () {
                      widget.shareLink(this.day, this.hours, this.minutes);
                    },
                    color: Color(0xff33d46f),
                    child: Text(
                      '分享',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    child: null,
                    width: 20,
                  ),
                  RaisedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('取消'),
                  )
                ],
              ),
            )
          ]),
        ));
  }
}
