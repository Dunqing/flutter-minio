import 'dart:async';

import 'package:MinioClient/minio/minio.dart';
import 'package:MinioClient/utils/utils.dart';
// ignore: unused_import
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';

Database database;

enum DownloadState { PAUSE, DOWNLOAD, COMPLETED, STOP, ERROR }

class DownloadFileInstance {
  final int id;
  final String filename;
  final String bucketName;
  final int createAt;
  final int updateAt;
  final int fileSize;
  final String filePath;
  String stateText;
  DownloadState state = DownloadState.DOWNLOAD;
  StreamSubscription<List<int>> subscription;
  int downloadSize;

  DownloadFileInstance(
    this.id,
    this.bucketName,
    this.filename,
    this.createAt,
    this.updateAt,
    this.fileSize,
    this.downloadSize, {
    this.state,
    this.stateText = '',
    this.filePath,
  });

  setSubscription(StreamSubscription<List<int>> sub) {
    this.subscription = sub;
  }

  setStateText(String text) {
    this.stateText = text;
  }

  changeState(DownloadState state) {
    this.state = state;
  }
}

/// 下载调度器
/// 控制下载个数，下载完毕后继续下载下个
class DownloadScheduler {
  final DownloadController downloadController;
  DownloadScheduler(this.downloadController);
  // ignore: close_sinks
  PublishSubject<DownloadFileInstance> scheduler = PublishSubject();
  List<DownloadFileInstance> currentDownloadList = [];
  List<DownloadFileInstance> waitingDownloadList = [];
  static const DOWNLODA_MAX_SIZE = 3;

  // 是否超过限制下载数
  bool get canDownload => this.currentDownloadList.length < DOWNLODA_MAX_SIZE;

  // 停止下载 并不是给挤下去
  stopDownload(int index) {
    final removeInstance = this.currentDownloadList.removeAt(index);
    if (removeInstance.subscription == null) {
      this.downloadController.updateDownloadState(
          removeInstance, DownloadState.ERROR,
          stateText: '文件错误，请重新下载');
      return;
    }
    removeInstance.changeState(DownloadState.STOP);
    removeInstance.subscription.cancel();
  }

  // 暂停下载 给挤下去了
  pauseDownload(int index) {
    final removeInstance = this.currentDownloadList.removeAt(index);
    if (removeInstance.subscription == null) {
      this.downloadController.updateDownloadState(
          removeInstance, DownloadState.ERROR,
          stateText: '文件错误，请重新下载');
      return;
    }
    // 删除在下载队列
    this.currentDownloadList.remove(removeInstance);
    removeInstance.changeState(DownloadState.PAUSE);
    removeInstance.subscription.cancel();
    // 只是暂停 加入到等待队列
    this.waitingDownloadList.add(removeInstance);
  }

  // 监听下载 处理事件
  onListen({void Function(DownloadFileInstance) onData}) {
    this.scheduler.stream
      ..listen((instance) {
        if (instance == null) {
          return;
        }
        // 能下载
        if (this.canDownload) {
          this.dispatchDownload(instance);
        } else {
          // 等待下载
          this
              .downloadController
              .updateDownloadState(instance, DownloadState.PAUSE);
          this.waitingDownloadList.add(instance);
        }
      });
  }

  // 删除下载
  removeDownload(instance) {
    this.currentDownloadList.remove(instance);
    instance.changeState(DownloadState.COMPLETED);
  }

  // 下载完毕后通知调度下载
  notify(DownloadFileInstance instance) {
    this.removeDownload(instance);
    this._refresh();

    print('当前还有几个要下载的 ${this.waitingDownloadList.length}');
    // 如果等待下载的已下完则结束运行
    if (this.waitingDownloadList.length == 0) {
      return;
    }

    final runInstance = this.waitingDownloadList.last;
    this.waitingDownloadList.remove(runInstance);
    this.dispatchDownload(runInstance);
  }

  // 触发下载
  dispatchDownload(DownloadFileInstance instance) {
    this.currentDownloadList.add(instance);
    instance.changeState(DownloadState.DOWNLOAD);
    this.downloadController.dispatchDownload(instance);
  }

  // 获取下载实例的索引
  getIndex(DownloadFileInstance instance) {
    return this.currentDownloadList.indexWhere((data) {
      return data.id == instance.id;
    });
  }

  // 正常下载
  void add(DownloadFileInstance instance) {
    print('listen where $instance');
    this.scheduler.add(instance);
  }

  // 触发更新，让数量变化
  _refresh() {
    this.scheduler.add(null);
  }

  // 如果状态已经在下载了则暂停 不加到等待队列
  void addStop(DownloadFileInstance instance) {
    final index = this.getIndex(instance);
    if (index != -1) {
      this.stopDownload(index);
    }

    // 如果还有在等待运行的则取出最后一个然后下载
    final waitingIndex = this.waitingDownloadList.length;
    if (this.canDownload && waitingIndex != 0) {
      final runInstance = this.waitingDownloadList.removeAt(waitingIndex - 1);
      this.scheduler.add(runInstance);
    }
  }

  // 插队下载 把第一个暂停，提供给正在等待下载的
  void addAdvance(DownloadFileInstance instance) {
    if (!this.canDownload) {
      this.pauseDownload(0);
    }

    this.waitingDownloadList.remove(instance);
    this.scheduler.add(instance);
  }
}

class DownloadController {
  Database _database;
  // ignore: close_sinks
  ReplaySubject<List<DownloadFileInstance>> downloadStream =
      ReplaySubject(maxSize: 1);
  List<DownloadFileInstance> downloadList = [];
  DownloadScheduler scheduler;
  MinioController minio;
  String dirPath;

  DownloadController({this.minio}) {
    if (database != null) {
      this._database = database;
      return;
    }
    // 设置下载路径
    getDictionaryPath().then((dir) {
      this.dirPath = dir;
    });
    getDatabasesPath().then((path) async {
      final dbPath = path + '/minio.db';
      await deleteDatabase(dbPath);
      this._database = await openDatabase(dbPath, version: 1,
          onCreate: (Database db, int version) {
        db.execute(
            'CREATE TABLE DownloadLog (id INTEGER PRIMARY KEY, bucketName TEXT, filename TEXT, createAt TEXT, updateAt TEXT, fileSize INTEGER, downloadSize INTEGER, state INTEGER, stateText TEXT, filePath TEXT)');
      });
      // this._database.execute('DROP TABLE DownloadLog');
      database = this._database;
      this.initData();
    });
  }

  // 因为是单例，提供改变minio实例
  setMinio(MinioController minio) {
    this.minio = minio;
  }

  // 重启app初始化下载数据
  initData() {
    this.finaAll().then((res) {
      final stateValues = DownloadState.values;
      final List<DownloadFileInstance> list = [];
      res.reversed.forEach((data) {
        final instance = DownloadFileInstance(
          data['id'],
          data['bucketName'],
          data['filename'],
          int.parse(data['createAt']),
          int.parse(data['updateAt']),
          data['fileSize'],
          data['downloadSize'],
          state: stateValues[data['state']],
          stateText: data['Text'],
          filePath: data['filePath'],
        );
        list.add(instance);
        if (instance.state == DownloadState.DOWNLOAD ||
            instance.state == DownloadState.PAUSE) {
          this.scheduler.add(instance);
        }
      });
      this.downloadList = list;
      this.downloadStream.add(list);
    });
  }

  // 插入一条下载数据
  Future<int> insert(
      bucketName, filename, createAt, updateAt, fileSize, downloadSize) async {
    final filePath = '${this.dirPath}/$filename';
    final id = await this._database.rawInsert(
        'INSERT INTO DownloadLog (bucketName, filename, createAt, updateAt, fileSize, downloadSize, state, stateText, filePath) VALUES(?, ?, ?, ?, ?, ?, ?, "", ?)',
        [
          bucketName,
          filename,
          createAt,
          updateAt,
          fileSize,
          downloadSize,
          DownloadState.DOWNLOAD.index,
          filePath
        ]);

    final instance = DownloadFileInstance(
        id, bucketName, filename, createAt, updateAt, fileSize, downloadSize,
        state: DownloadState.STOP, filePath: filePath);

    this.downloadList.insert(0, instance);
    this.scheduler.add(instance);
    this.refresh();

    return id;
  }

  // 刷新数据
  refresh() {
    return this.downloadStream.add(this.downloadList);
  }

  // 更新下载大小
  Future<void> updateDownloadSize(
      DownloadFileInstance instance, int downloadSize) async {
    await this._database.rawUpdate(
        'UPDATE DownloadLog SET downloadSize = ? WHERE id = ${instance.id}',
        [instance.downloadSize]);
    instance.downloadSize = downloadSize;
    this.refresh();
  }

  // 更新状态
  Future<void> updateDownloadState(
      DownloadFileInstance instance, DownloadState state,
      {String stateText = ''}) async {
    await this._database.rawUpdate(
        'UPDATE DownloadLog SET state = ?, stateText = ?  WHERE id = ${instance.id}',
        [state.index, stateText]);
    instance.changeState(state);
    instance.setStateText(stateText);
    this.refresh();
  }

  Future<void> dispatchDownload(DownloadFileInstance instance) {
    _onListen(downloadSize, fileSize) {
      // print('currentSize $downloadSize || fileSize $fileSize');
      instance.downloadSize = downloadSize;
      this.updateDownloadSize(instance, instance.downloadSize);
    }

    _onCompleted(downloadSize, fileSize) {
      print('completed currentSize $downloadSize || fileSize $fileSize');
      this.updateDownloadSize(instance, instance.downloadSize);
      this.updateDownloadState(instance, DownloadState.COMPLETED);
      this.scheduler.notify(instance);
    }

    _onStart(subscription) {
      instance.setSubscription(subscription);
    }

    return this
        .minio
        .getPartialObject(instance.bucketName, instance.filename,
            onListen: _onListen, onCompleted: _onCompleted, onStart: _onStart)
        .catchError((err) {
      print(err);
      this.updateDownloadState(instance, DownloadState.ERROR,
          stateText: err.toString());
    });
  }

  // 重新下载
  Future<DownloadFileInstance> reDownload(DownloadFileInstance instance) async {
    this.downloadStream.add(this.downloadList);
    await this.updateDownloadSize(instance, instance.downloadSize);
    this.scheduler.add(instance);
    return instance;
  }

  // 抢先下载
  Future<DownloadFileInstance> advanceDownload(
      DownloadFileInstance instance) async {
    this.downloadStream.add(this.downloadList);
    print('advance');
    await this.updateDownloadSize(instance, instance.downloadSize);
    print('advance');
    this.scheduler.addAdvance(instance);
    return instance;
  }

  // 停止下载
  Future<DownloadFileInstance> stopDownload(
      DownloadFileInstance instance) async {
    this.scheduler.addStop(instance);
    this.refresh();
    return instance;
  }

  // 查询所有下载数据 后续可能改成分页
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
      if (minio != null) {
        instance.setMinio(minio);
      }
      return instance;
    }
    instance = DownloadController(minio: minio);
    instance.scheduler = DownloadScheduler(instance);
    instance.scheduler.onListen();
    return instance;
  };
}();
