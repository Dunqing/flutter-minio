import 'dart:async';

import 'package:MinioClient/minio/minio.dart';
// ignore: unused_import
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';

Database database;

enum DownloadState { PAUSE, DOWNLOAD, COMPLETED }

class DownloadFileInstance {
  final int id;
  final String filename;
  final String bucketName;
  final int createAt;
  final int updateAt;
  final int fileSize;
  DownloadState state = DownloadState.DOWNLOAD;
  StreamSubscription<List<int>> subscription;
  int downloadSize;

  DownloadFileInstance(this.id, this.bucketName, this.filename, this.createAt,
      this.updateAt, this.fileSize, this.downloadSize);

  setSubscription(StreamSubscription<List<int>> sub) {
    this.subscription = sub;
  }

  changeState(DownloadState state) {
    this.state = state;
  }
}

class DownloadController {
  Database _database;
  // ignore: close_sinks
  ReplaySubject<List<DownloadFileInstance>> downloadStream =
      ReplaySubject(maxSize: 1);
  List<DownloadFileInstance> downloadList = [];
  final MinioController minio;

  DownloadController({this.minio}) {
    if (database != null) {
      this._database = database;
      return;
    }
    getDatabasesPath().then((path) async {
      final dbPath = path + '/minio.db';
      await deleteDatabase(dbPath);
      this._database = await openDatabase(dbPath, version: 1,
          onCreate: (Database db, int version) {
        db.execute(
            'CREATE TABLE DownloadLog (id INTEGER PRIMARY KEY, bucketName TEXT, filename TEXT, createAt TEXT, updateAt TEXT, fileSize INTEGER, downloadSize INTEGER)');
      });
      // this._database.execute('DROP TABLE DownloadLog');
      database = this._database;
      this.initData();
    });
  }

  initData() {
    this.finaAll().then((res) {
      final List<DownloadFileInstance> list = [];
      res.forEach((data) {
        list.add(DownloadFileInstance(
            data['id'],
            data['bucketName'],
            data['filename'],
            int.parse(data['createAt']),
            int.parse(data['updateAt']),
            data['maxSize'],
            data['downloadSize']));
      });
      this.downloadList = list.reversed.toList();
      this.downloadStream.add(list);
    });
  }

  Future<int> insert(
      bucketName, filename, createAt, updateAt, fileSize, downloadSize) async {
    final id = await this._database.rawInsert(
        'INSERT INTO DownloadLog (bucketName, filename, createAt, updateAt, fileSize, downloadSize) VALUES(?, ?, ?, ?, ?, ?)',
        [bucketName, filename, createAt, updateAt, fileSize, downloadSize]);

    final instance = DownloadFileInstance(
        id, bucketName, filename, createAt, updateAt, fileSize, downloadSize);

    this.downloadList.insert(0, instance);
    this.downloadStream.add(this.downloadList);

    this.minio.getPartialObject(bucketName, filename,
        onListen: (downloadSize, fileSize) {
      instance.downloadSize = downloadSize;
      print('downloadSize $downloadSize || $fileSize fileSize');
      this.downloadStream.add(this.downloadList);
    }, onStart: (subscription) {
      print('subscribtion');
      print(subscription);
      instance.setSubscription(subscription);
    });
    return id;
  }

  Future<DownloadFileInstance> reDownload(DownloadFileInstance instance) async {
    await this._database.rawUpdate(
        'UPDATE DownloadLog SET downloadSize = ? WHERE id = ${instance.id}',
        [instance.downloadSize]);

    this.downloadStream.add(this.downloadList);

    this.minio.getPartialObject(instance.bucketName, instance.filename,
        onListen: (downloadSize, fileSize) {
      instance.downloadSize = downloadSize;
      print('downloadSize $downloadSize || $fileSize fileSize');
      this.downloadStream.add(this.downloadList);
    }, onCompleted: (downloadSize, fileSize) {
      instance.downloadSize = downloadSize;
      print('completed downloadSize $downloadSize || $fileSize fileSize');
      this.downloadStream.add(this.downloadList);
      instance.changeState(DownloadState.COMPLETED);
    }, onStart: (subscription) {
      instance.setSubscription(subscription);
    });
    return instance;
  }

  Future<List<Map<String, dynamic>>> finaAll() async {
    final result = await this._database.rawQuery('SELECT * FROM "DownloadLog"');
    return result;
  }
}

final createDownloadInstance = () {
  DownloadController instance;
  return ({MinioController minio}) {
    if (instance != null) {
      return instance;
    }
    instance = DownloadController(minio: minio);

    Future.delayed(Duration(milliseconds: 300)).then((data) {
      instance.downloadStream.add([]);
    });
    print('hasListener ${instance.downloadStream.hasListener}');

    return instance;
  };
}();
