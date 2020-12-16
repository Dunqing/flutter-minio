import 'dart:async';
import 'dart:io';

import 'package:MinioClient/utils/utils.dart';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';
import 'package:minio/models.dart';
import 'package:path/path.dart' show dirname;
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefix {
  bool isPrefix;
  String key;
  String prefix;

  Prefix({this.key, this.prefix, this.isPrefix});
}

var _minio;

Future<Minio> _resetMinio() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool useSSl = prefs.getBool('useSSL') ?? true;
  String endPoint = prefs.getString('endPoint');
  int port = prefs.getInt('port');
  String accessKey = prefs.getString('accessKey');
  String secretKey = prefs.getString('secretKey');

  // 是否存在配置
  if (accessKey?.isEmpty != false || secretKey?.isEmpty != false) {
    return Future.error('no has config');
  }

  try {
    _minio = Minio(
      useSSL: useSSl,
      endPoint: endPoint,
      port: port,
      accessKey: accessKey,
      secretKey: secretKey,
      region: 'cn-north-1',
    );
  } catch (err) {
    toastError(err.toString());
    return Future.error(err);
  }
  return _minio;
}

class MinioController {
  Minio minio;
  String bucketName;
  String prefix;

  static resetMinio() async {
    await _resetMinio();
  }

  /// maximum object size (5TB)
  final maxObjectSize = 5 * 1024 * 1024 * 1024 * 1024;

  MinioController({this.bucketName, this.prefix}) {
    print('111');
    print(_minio);
    if (_minio is Minio) {
      this.minio = _minio;
    } else {
      _resetMinio().then((_) {
        print('222');
        print(_);
        this.minio = _;
      });
    }
  }

  Future<List<IncompleteUpload>> listIncompleteUploads(
      {String bucketName}) async {
    print(bucketName ?? this.bucketName);
    final list = this
        .minio
        .listIncompleteUploads(bucketName ?? this.bucketName, '')
        .toList();
    return list;
  }

  Future<Map<dynamic, dynamic>> getBucketObjects(
      String bucketName, String prefix) async {
    final objects = this
        .minio
        .listObjectsV2(this.bucketName, prefix: this.prefix, recursive: false);
    final map = new Map();
    await for (var obj in objects) {
      final prefixs = obj.prefixes.map((e) {
        final index = e.lastIndexOf('/') + 1;
        final prefix = e.substring(0, index);
        final key = e;
        return Prefix(key: key, prefix: prefix, isPrefix: true);
      }).toList();

      map['prefixes'] = prefixs;
      map['objests'] = obj.objects;
    }
    return map;
  }

  Future<List<Bucket>> getListBuckets() async {
    print('bucket');
    print(this.minio);
    return this.minio.listBuckets();
  }

  Future<bool> buckerExists(String bucket) async {
    return this.minio.bucketExists(bucket);
  }

  Future<void> downloadFile(filename) async {
    final dir = await getExternalStorageDirectory();
    minio
        .fGetObject(
            bucketName, prefix + filename, '${dir.path}/${prefix + filename}')
        .then((value) {});
  }

  Future<String> uploadFile(String filename, String filePath) async {
    return minio.fPutObject(this.bucketName, filename, filePath);
  }

  Future<String> presignedGetObject(String filename, {int expires}) {
    return this
        .minio
        .presignedGetObject(this.bucketName, filename, expires: expires);
  }

  Future<String> getPreviewUrl(String filename) {
    return this.presignedGetObject(filename, expires: 60 * 60 * 24);
  }

  /// 可多删除和单删除
  Future<void> removeFile<T>(T filenames) {
    final List<String> objects = filenames is String ? [filenames] : filenames;
    print(objects);
    return this.minio.removeObjects(this.bucketName, objects);
  }

  Future<void> createBucket(String bucketName) {
    print(bucketName);
    return this.minio.makeBucket(bucketName);
  }

  Future<void> removeBucket(String bucketName) {
    return this.minio.removeBucket(bucketName);
  }

  Future<dynamic> getPartialObject(
      String bucketName, String filename, String filePath,
      {void onListen(int downloadSize, int fileSize),
      void onCompleted(int downloadSize, int fileSize),
      void onStart(StreamSubscription<List<int>> subscription)}) async {
    final stat = await this.minio.statObject(bucketName, filename);

    final dir = dirname(filePath);
    await Directory(dir).create(recursive: true);

    final partFileName = '$filePath.${stat.etag}.part.minio';
    final partFile = File(partFileName);
    IOSink partFileStream;
    var offset = 0;

    final rename = () => partFile.rename(filePath);

    if (await partFile.exists()) {
      final localStat = await partFile.stat();
      if (stat.size == localStat.size) return rename();
      offset = localStat.size;
      partFileStream = partFile.openWrite(mode: FileMode.append);
    } else {
      partFileStream = partFile.openWrite(mode: FileMode.write);
    }

    final dataStream =
        (await this.minio.getPartialObject(bucketName, filename, offset))
            .asBroadcastStream(onListen: (sub) {
      if (onStart != null) {
        onStart(sub);
      }
    });

    Future.delayed(Duration.zero).then((_) {
      final listen = dataStream.listen((data) {
        if (onListen != null) {
          onListen(partFile.statSync().size, stat.size);
        }
      });
      listen.onDone(() {
        if (onListen != null) {
          onListen(partFile.statSync().size, stat.size);
        }
        listen.cancel();
      });
    });

    await dataStream.pipe(partFileStream);

    if (onCompleted != null) {
      onCompleted(partFile.statSync().size, stat.size);
    }
    // print('${partFile.statSync().size}, ${stat.size}');

    final localStat = await partFile.stat();
    if (localStat.size != stat.size) {
      throw MinioError('Size mismatch between downloaded file and the object');
    }
    return rename();
  }
}
