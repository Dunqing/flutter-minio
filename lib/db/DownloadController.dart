import 'dart:async';

import 'package:MinioClient/minio/minio.dart';
// ignore: unused_import
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';

Database database;

enum DownloadState { PAUSE, DOWNLOAD, COMPLETED, STOP }

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
      this.updateAt, this.fileSize, this.downloadSize,
      {this.state});

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
      // await deleteDatabase(dbPath);
      this._database = await openDatabase(dbPath, version: 1,
          onCreate: (Database db, int version) {
        db.execute(
            'CREATE TABLE DownloadLog (id INTEGER PRIMARY KEY, bucketName TEXT, filename TEXT, createAt TEXT, updateAt TEXT, fileSize INTEGER, downloadSize INTEGER, state INTEGER)');
      });
      // this._database.execute('DROP TABLE DownloadLog');
      database = this._database;
      this.initData();
    });
  }

  initData() {
    this.finaAll().then((res) {
      final stateValues = DownloadState.values;
      final List<DownloadFileInstance> list = [];
      res.forEach((data) {
        list.add(DownloadFileInstance(
          data['id'],
          data['bucketName'],
          data['filename'],
          int.parse(data['createAt']),
          int.parse(data['updateAt']),
          data['fileSize'],
          data['downloadSize'],
          state: stateValues[data['state']],
        ));
      });
      this.downloadList = list.reversed.toList();
      this.downloadStream.add(list);
    });
  }

  Future<int> insert(
      bucketName, filename, createAt, updateAt, fileSize, downloadSize) async {
    final id = await this._database.rawInsert(
        'INSERT INTO DownloadLog (bucketName, filename, createAt, updateAt, fileSize, downloadSize, state) VALUES(?, ?, ?, ?, ?, ?, ?)',
        [
          bucketName,
          filename,
          createAt,
          updateAt,
          fileSize,
          downloadSize,
          DownloadState.DOWNLOAD.index
        ]);

    final instance = DownloadFileInstance(
        id, bucketName, filename, createAt, updateAt, fileSize, downloadSize,
        state: DownloadState.DOWNLOAD);

    this.downloadList.insert(0, instance);
    this.downloadStream.add(this.downloadList);
    this.dispatchDownload(instance);

    return id;
  }

  updateDownloadSize(DownloadFileInstance instance, int downloadSize) async {
    instance.downloadSize = downloadSize;
    await this._database.rawUpdate(
        'UPDATE DownloadLog SET downloadSize = ? WHERE id = ${instance.id}',
        [instance.downloadSize]);
    this.downloadStream.add(this.downloadList);
  }

  updateDownloadState(
      DownloadFileInstance instance, DownloadState state) async {
    instance.changeState(DownloadState.COMPLETED);
    await this._database.rawUpdate(
        'UPDATE DownloadLog SET state = ? WHERE id = ${instance.id}', [state]);
    this.downloadStream.add(this.downloadList);
  }

  Future<void> dispatchDownload(DownloadFileInstance instance) {
    _onListen(downloadSize, fileSize) {
      print('currentSize $downloadSize || fileSize $fileSize');
      instance.downloadSize = downloadSize;
      this.updateDownloadSize(instance, instance.downloadSize);
    }

    _onCompleted(downloadSize, fileSize) {
      print('completed currentSize $downloadSize || fileSize $fileSize');
      this.updateDownloadSize(instance, instance.downloadSize);
      this.updateDownloadState(instance, DownloadState.COMPLETED);
    }

    _onStart(subscription) {
      instance.setSubscription(subscription);
    }

    return this.minio.getPartialObject(instance.bucketName, instance.filename,
        onListen: _onListen, onCompleted: _onCompleted, onStart: _onStart);
  }

  Future<DownloadFileInstance> reDownload(DownloadFileInstance instance) async {
    this.downloadStream.add(this.downloadList);
    this.updateDownloadSize(instance, instance.downloadSize);
    this.dispatchDownload(instance);
    return instance;
  }

  Future<List<Map<String, dynamic>>> finaAll() async {
    final result = await this._database.rawQuery('SELECT * FROM "DownloadLog"');
    return result;
  }
}

/// 创建单例downloadController
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
