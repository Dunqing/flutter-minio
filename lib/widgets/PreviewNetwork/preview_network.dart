import 'package:MinioClient/widgets/loading/index.dart';
import 'package:flutter/material.dart';

class PreviewNetwork {
  BuildContext context;
  PreviewNetwork({@required this.context});

  static isPreview() {
    return false;
  }

  previewImage(url) {
    showDialog(
        context: this.context,
        builder: (BuildContext context) {
          return Stack(children: [
            Container(
              constraints: BoxConstraints.expand(),
              alignment: Alignment.center,
              child: Scrollbar(
                  child: SingleChildScrollView(
                child: Image.network(
                  url,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent event) {
                    return AnimatedSwitcher(
                        duration: Duration(milliseconds: 500),
                        child: child ?? Loading(child: LoopBoxLoading()));
                  },
                  alignment: Alignment.center,
                  fit: BoxFit.fitWidth,
                ),
              )),
            ),
            Positioned(
                right: 20,
                top: 20,
                child: GestureDetector(
                    onTap: () {
                      Navigator.of(this.context).pop();
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white)),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.white,
                      ),
                    )))
          ]);
        });
  }

  preview(url) {
    this.previewImage(url);
  }
}
