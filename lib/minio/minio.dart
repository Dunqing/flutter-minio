import 'package:file_picker/file_picker.dart';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';
import 'package:minio/models.dart';
import 'package:path_provider/path_provider.dart';

class Prefix {
  bool isPrefix;
  String key;
  String prefix;

  Prefix({this.key, this.prefix, this.isPrefix});
}

var minio;

class MinioController {
  Minio minio;
  String bucketName;
  String prefix;

  MinioController(this.bucketName, this.prefix) {
    if (minio is Minio) {
      this.minio = minio;
    } else {
      minio = Minio(
        useSSL: false,
        endPoint: '49.232.194.85',
        port: 9001,
        accessKey: 'minio',
        secretKey: 'minio123',
        region: 'cn-north-1',
      );
      this.minio = minio;
    }
  }

  Future<Map<dynamic, dynamic>> getBucketObjects(
      String bucketName, String prefix) async {
    final objects = minio.listObjectsV2(this.bucketName,
        prefix: this.prefix, recursive: false);
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
    return this.minio.listBuckets();
  }

  Future<void> downloadFile(filename) async {
    final dir = await getExternalStorageDirectory();
    minio
        .fGetObject(
            bucketName, prefix + filename, '${dir.path}/${prefix + filename}')
        .then((value) {});
  }

  Future<String> uploadFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result == null || result?.files == null || result?.files?.length == 0) {
      print('取消了上传');
      return 'cancel';
    }
    final file = result.files[0];
    return minio.fPutObject(this.bucketName, file.name, file.path);
  }

  Future<String> presignedGetObject(filename, {int expires}) {
    return this
        .minio
        .presignedGetObject(this.bucketName, filename, expires: expires);
  }

  Future<String> getPreviewUrl(filename) {
    return this.presignedGetObject(filename, expires: 60 * 60 * 24);
  }
}
