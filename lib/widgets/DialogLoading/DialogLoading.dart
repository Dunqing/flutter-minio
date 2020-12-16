import 'package:MinioClient/utils/global.dart';
import 'package:MinioClient/widgets/loading/index.dart';
import 'package:flutter/material.dart';

final _loading = Map();
final _context =
    SignleInstance.getInstance<GlobalKey<NavigatorState>>('GlobalContext')
        .currentContext;

class DialogLoading {
  static Future<VoidCallback> showLoadingBk() async {
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
      Navigator.of(context ?? _context).pop();
    }

    return closeLoading;
  }

  static dynamic showLoading(BuildContext context) {
    final OverlayEntry _entry = OverlayEntry(builder: (context) {
      return Container(
          decoration: BoxDecoration(color: Color.fromARGB(88, 0, 0, 0)),
          child: Loading(
            milliseconds: 1000,
            child: LoopBoxLoading(
              text: '拼命加载中...',
            ),
          ),
          constraints: BoxConstraints.expand(),
          alignment: Alignment.center);
    });

    /// fix 渲染bug
    Future.delayed(Duration.zero).then((_) {
      Overlay.of(context, rootOverlay: true).insert(_entry);
    });

    return () {
      _entry.remove();
    };
  }

  static closeLoading() {}
}
