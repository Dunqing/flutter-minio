import 'dart:async';

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
