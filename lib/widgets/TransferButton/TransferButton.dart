import 'package:MinioClient/minio/DownloadController.dart';
import 'package:flutter/material.dart';

class TransferButton extends StatelessWidget {
  const TransferButton({
    Key key,
    @required this.downloadController,
  }) : super(key: key);

  final DownloadController downloadController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      margin: EdgeInsets.only(right: 5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.swap_vert),
            onPressed: () {
              Navigator.of(context).pushNamed('FileOperationLog');
            },
          ),
          StreamBuilder(
            stream: this.downloadController.downloadStream.stream,
            builder: (BuildContext context,
                AsyncSnapshot<List<DownloadFileInstance>> snapshot) {
              final downloadList = snapshot.data;
              int downloadCount = 0;
              downloadList?.forEach((item) =>
                  item.state == DownloadState.DOWNLOAD
                      ? downloadCount++
                      : null);
              if (downloadCount == 0) {
                return SizedBox.shrink();
              }
              return Positioned(
                  right: 0,
                  top: 5,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: 20,
                    height: 20,
                    child: Text(
                      downloadCount.toString(),
                      style: TextStyle(fontSize: 12),
                    ),
                  ));
            },
          ),
        ],
      ),
    );
  }
}
