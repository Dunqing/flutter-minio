import 'package:minio/minio.dart';

final minio = Minio(
  useSSL: false,
  endPoint: '49.232.194.85',
  port: 9001,
  accessKey: 'minio',
  secretKey: 'minio123',
  region: 'cn-north-1',
);
