import 'dart:async';

import 'package:MinioClient/db/DownloadDb.dart';
import 'package:MinioClient/minio/minio.dart';
import 'package:MinioClient/utils/file.dart';
import 'package:MinioClient/utils/storage.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:path/path.dart' show basename;
import 'package:rxdart/rxdart.dart';

import 'DownloadFileInstance.dart';
import 'DownloadScheduler.dart';

export 'DownloadFileInstance.dart';
export 'DownloadScheduler.dart';

class DownloadController {
  // ignore: close_sinks
  ReplaySubject<List<DownloadFileInstance>> downloadStream =
      ReplaySubject(maxSize: 1);
  List<DownloadFileInstance> downloadList = [];
  DownloadScheduler scheduler;
  MinioController minio;
  DownloadDb _db;
  static String downloadPath;

  DownloadController({this.minio}) {
    this._db = DownloadDb();
    this._db.initDb().then((_) {
      this.initData();
    });

    // 优先使用配置的路径
    getConfigForKey('downloadPath').then((path) {
      if (path != null) {
        DownloadController.downloadPath = path;
        return;
      }
      // 设置下载路径
      getDictionaryPath().then((dir) {
        DownloadController.downloadPath = dir;
      });
    });
  }

  // 因为是单例，提供改变minio实例
  setMinio(MinioController minio) {
    this.minio = minio;
  }

  // 重启app或删除数据后初始化下载数据
  initData([callback]) {
    this._db.findAll().then((res) {
      final stateValues = DownloadState.values;
      final List<DownloadFileInstance> list = [];
      res.forEach((data) {
        final instance = DownloadFileInstance(
          data['id'],
          data['bucketName'],
          data['filename'],
          int.parse(data['createAt']),
          int.parse(data['updateAt']),
          data['fileSize'],
          data['downloadSize'],
          state: stateValues[data['state']],
          stateText: data['stateText'],
          filePath: data['filePath'],
        );
        list.add(instance);
        if (instance.state == DownloadState.DOWNLOAD ||
            instance.state == DownloadState.PAUSE) {
          this.scheduler.add(instance);
        }
        if (callback is Function) {
          callback(instance);
        }
      });
      this.downloadList = list.reversed.toList();
      this.downloadStream.add(this.downloadList);
    });
  }

  // 插入一条下载数据
  Future<int> download(filePath, bucketName, filename, String eTag, createAt,
      updateAt, fileSize, downloadSize) async {
    await permissionStorage();
    final id = await this._db.insert(bucketName, filename, createAt, updateAt,
        fileSize, downloadSize, DownloadState.DOWNLOAD.index, filePath, eTag);

    final instance = DownloadFileInstance(
        id, bucketName, filename, createAt, updateAt, fileSize, downloadSize,
        state: DownloadState.STOP, filePath: filePath, eTag: eTag);

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
    await this._db.updateSize(instance.id, downloadSize);
    instance.downloadSize = downloadSize;
    this.refresh();
  }

  // 更新状态
  Future<void> updateDownloadState(
      DownloadFileInstance instance, DownloadState state,
      {String stateText = ''}) async {
    this._db.updateState(instance.id, state.index, stateText: stateText);
    instance.changeState(state);
    instance.setStateText(stateText);
    this.refresh();
  }

  Future<void> dispatchDownload(DownloadFileInstance instance) {
    _onListen(downloadSize, fileSize) {
      instance.downloadSize = downloadSize;
      this.updateDownloadSize(instance, instance.downloadSize);
    }

    _onCompleted(downloadSize, fileSize) {
      final filename = basename(instance.filename);
      this.updateDownloadSize(instance, instance.downloadSize);
      this.updateDownloadState(instance, DownloadState.COMPLETED);
      this.scheduler.notify(instance);
    }

    _onStart(subscription) {
      instance.setSubscription(subscription);
    }

    return this
        .minio
        .getPartialObject(
            instance.bucketName, instance.filename, instance.filePath,
            onListen: _onListen, onCompleted: _onCompleted, onStart: _onStart)
        .catchError((err) {
      this.scheduler.removeErrorDownload(instance, err.toString());
      this.refresh();
    });
  }

  // 重新下载
  Future<DownloadFileInstance> reDownload(DownloadFileInstance instance) async {
    this.downloadStream.add(this.downloadList);
    this.scheduler.add(instance);
    return instance;
  }

  // 抢先下载
  Future<DownloadFileInstance> advanceDownload(
      DownloadFileInstance instance) async {
    this.downloadStream.add(this.downloadList);
    await this.updateDownloadSize(instance, instance.downloadSize);
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

  /// 退出项目时执行
  close() {
    this.downloadStream.close();
    this.scheduler.scheduler.close();
    this._db.close();
  }

  Future<void> deleteDownload(List<DownloadFileInstance> item,
      {bool deleteFile}) async {
    final List<int> okids = item.map((item) => item.id).toList();
    await this.scheduler.addDelete(okids, deleteFile);
    this._db.delete(okids.join(',')).then((res) {
      // 还需要清理调度器的数据
      this.downloadList.forEach((instance) {
        instance.subscription?.cancel();
        this.scheduler.currentDownloadList.clear();
        this.scheduler.waitingDownloadList.clear();
      });
      this.initData();
    });
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
