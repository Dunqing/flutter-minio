import 'package:MinioClient/eunm/common.dart';
import 'package:MinioClient/utils/file.dart';
import 'package:MinioClient/utils/storage.dart';
import 'package:rxdart/rxdart.dart';

import 'DownloadController.dart';
import 'DownloadFileInstance.dart';

/// 下载调度器
/// 控制下载个数，下载完毕后继续下载下个
class DownloadScheduler {
  final DownloadController downloadController;
  DownloadScheduler(this.downloadController) {
    getConfigForKey<int>('downloadCount').then((count) {
      print(count);
      if (count == null) {
        DownloadScheduler.downloadMaxSize = 3;
      } else {
        DownloadScheduler.downloadMaxSize =
            getMaxDownloadValue(MaxDownloadCount.values[count]);
      }
      print('限制个数');
      print(DownloadScheduler.downloadMaxSize);
    });
  }
  // ignore: close_sinks
  PublishSubject<DownloadFileInstance> scheduler = PublishSubject();
  List<DownloadFileInstance> currentDownloadList = [];
  List<DownloadFileInstance> waitingDownloadList = [];
  static int downloadMaxSize = 3;

  // 是否超过限制下载数
  bool get canDownload =>
      this.currentDownloadList.length < DownloadScheduler.downloadMaxSize;

  // 停止下载 并不是给挤下去
  stopDownload(int index) {
    final removeInstance = this.currentDownloadList.removeAt(index);
    if (removeInstance.subscription == null) {
      this.downloadController.updateDownloadState(
          removeInstance, DownloadState.ERROR,
          stateText: '文件错误，请重新下载');
      return;
    }
    this
        .downloadController
        .updateDownloadState(removeInstance, DownloadState.STOP);
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
    this
        .downloadController
        .updateDownloadState(removeInstance, DownloadState.PAUSE);
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

  // 删除错误下载
  removeErrorDownload(instance, err) {
    this.currentDownloadList.remove(instance);
    this.downloadController.updateDownloadState(instance, DownloadState.ERROR,
        stateText: err.toString());
  }

  // 删除下载
  removeDownload(instance) {
    this.currentDownloadList.remove(instance);
  }

  // 下载完毕后通知调度下载
  notify(DownloadFileInstance instance) {
    this.removeDownload(instance);

    print('当前还有几个要下载的 ${this.waitingDownloadList.length}');
    // 如果等待下载的已下完则结束运行

    if (this.waitingDownloadList.length == 0) {
      return;
    }
    final runInstance = this.waitingDownloadList.last;
    this.waitingDownloadList.remove(runInstance);
    this.scheduler.add(runInstance);
  }

  // 触发下载
  dispatchDownload(DownloadFileInstance instance) {
    this.currentDownloadList.add(instance);
    this
        .downloadController
        .updateDownloadState(instance, DownloadState.DOWNLOAD);
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

  Future<dynamic> addDelete(List<int> ids) async {
    final removeList = [];
    delete(DownloadFileInstance item) async {
      if (ids.indexOf(item.id) == -1) return;
      removeList.add(item);
      if (item.subscription != null) {
        item.subscription.cancel();
      }
      await removeFile('${item.filePath}.${item.eTag}.part.minio');
    }

    this.waitingDownloadList.forEach((item) {
      delete(item);
    });

    this.currentDownloadList.forEach((item) {
      delete(item);
    });

    removeList.forEach((item) {
      if (this.waitingDownloadList.indexOf(item) != -1) {
        this.waitingDownloadList.remove(item);
        return;
      }
      if (this.currentDownloadList.indexOf(item) != -1)
        this.currentDownloadList.remove(item);
      return;
    });
    print('还剩多少');
    print(this.currentDownloadList.length);
    print(this.waitingDownloadList.length);
  }
}
