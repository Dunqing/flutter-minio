import 'package:flutter/material.dart';

typedef OnConfirm = Future<dynamic> Function();

showConfirmDialog(
  context, {
  String title = '确认弹窗',
  Widget titleWidget,
  TextStyle titleStyle,
  Widget content,

  /// 确认弹窗是否关闭
  bool confirmClose = true,
  Function onConfirm,
  VoidCallback onCancel,
}) {
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: titleWidget ??
              Text(
                title,
                style: titleStyle ?? TextStyle(color: Colors.red),
              ),
          content: content,
          actions: [
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop('cacnel');
                if (onCancel is Function) {
                  onCancel();
                }
              },
              child: Text('取消'),
            ),
            FlatButton(
              onPressed: () async {
                if (onConfirm != null) {
                  await onConfirm();
                }
                if (confirmClose) {
                  Navigator.of(context).pop('confirm');
                }
              },
              child: Text('确定'),
            ),
          ],
        );
      });
}
