import 'dart:io';

import 'package:path_provider/path_provider.dart';

///文件是否存在
bool hasFileExists(url) {
  final file = File(url);
  return file.existsSync();
}

/// 删除文件
Future<FileSystemEntity> removeFile(url) {
  final file = File(url);

  final exists = file.existsSync();
  if (!exists) {
    return Future.value();
    // return Future.error('文件已不存在');
  }

  return file.delete();
}

Future<String> getDictionaryPath({String filename}) async {
  var path = await getExternalStorageDirectory();
  if (filename == null) {
    return path.path;
  }
  final filePath = '${path.path}/$filename';
  return filePath;
}
