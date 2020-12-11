import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

byteToSize(int byte) {
  var size = '';
  if (byte < 0.1 * 1024) {
    // 小于0.1KB 则转化成B
    size = byte.toStringAsFixed(2) + 'B';
  } else if (byte < 0.1 * 1024 * 1024) {
    // 小于0.1MB 则转换成KB
    size = (byte / 1024).toStringAsFixed(2) + 'KB';
  } else if (byte < 0.1 * 1024 * 1024 * 1024) {
    // 小于0.1GB 则转换成MB
    size = (byte / (1024 * 1024)).toStringAsFixed(2) + 'MB';
  } else if (byte < 0.1 * 1024 * 1024 * 1024 * 1024) {
    // 小于0.1TB 则转换成GB
    size = (byte / (1024 * 1024 * 1024)).toStringAsFixed(2) + 'GB';
  } else if (byte < 0.1 * 1024 * 1024 * 1024 * 1024 * 1024) {
    // 小于0.1PB 则转换成TB
    size = (byte / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2) + 'TB';
  } else if (byte < 0.1 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024) {
    // 小于0.1EB 则转换成PB
    size =
        (byte / (1024 * 1024 * 1024 * 1024 * 1024)).toStringAsFixed(2) + 'PB';
  } else if (byte < 0.1 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024) {
    // 小于0.1ZB 则转换成EB
    size =
        (byte / (1024 * 1024 * 1024 * 1024 * 1024 * 1024)).toStringAsFixed(2) +
            'EB';
  } else if (byte <
      0.1 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024) {
    // 小于0.1YB 则转换成ZB
    size = (byte / (1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024))
            .toStringAsFixed(2) +
        'ZB';
  }
  return size;
}

toast(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0);
}

Future<String> getDictionaryPath({String filename}) async {
  var path = await getExternalStorageDirectory();
  if (filename == null) {
    return path.path;
  }
  final filePath = '${path.path}/$filename';
  return filePath;
}

launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

permissionStorage() async {
  await Permission.storage.request().isGranted;
}
