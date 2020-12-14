import 'package:MinioClient/utils/global.dart';
import 'package:MinioClient/widgets/loading/index.dart';
import 'package:flutter/material.dart';

final _loading = Map();
final _context =
    SignleInstance.getInstance<GlobalKey<NavigatorState>>('GlobalContext')
        .currentContext;

class DialogLoading {
  static Future<VoidCallback> showLoading() async {
    final key = UniqueKey();
    await Future.delayed(Duration.zero);
    showDialog(
        barrierDismissible: false,
        context: _context,
        builder: (context) {
          if (!_loading.containsKey(key)) {
            _loading[key] = context;
          }
          return Container(
              child: Loading(
                milliseconds: 1000,
                child: LoopBoxLoading(
                  text: '拼命加载中...',
                ),
              ),
              constraints: BoxConstraints.expand(),
              alignment: Alignment.center);
        });

    closeLoading() {
      final context = _loading[key];
      _loading.remove(key);
      Navigator.of(context).pop();
    }

    return closeLoading;
  }

  static closeLoading() {}
}
