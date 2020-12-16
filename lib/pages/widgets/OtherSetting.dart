import 'package:MinioClient/eunm/common.dart';
import 'package:MinioClient/minio/DownloadController.dart';
import 'package:MinioClient/utils/file.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtherSetting extends StatefulWidget {
  OtherSetting({Key key}) : super(key: key);

  @override
  _OtherSettingState createState() => _OtherSettingState();
}

class _OtherSettingState extends State<OtherSetting> {
  MaxDownloadCount _count = MaxDownloadCount.Three;
  String _downloadPath = '';
  SharedPreferences prefs;

  @override
  void initState() {
    this.initSharedPreferences();
    super.initState();
  }

  initSharedPreferences() async {
    this.prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('downloadCount')) {
      this._count = MaxDownloadCount.values[prefs.getInt('downloadCount')];
    }
    print('获取下载地址');
    if (prefs.containsKey('downloadPath')) {
      setState(() {
        this._downloadPath = prefs.getString('downloadPath');
      });
      return;
    } else {
      getDictionaryPath().then((path) {
        print(path);
        setState(() {
          this._downloadPath = path;
        });
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      constraints: BoxConstraints.expand(),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ..._renderDownloadCount(),
          SizedBox(
            height: 40,
            child: null,
          ),
          ..._renderSelectDictionary()
        ],
      ),
    );
  }

  List<Widget> _renderDownloadCount() {
    return [
      Text('同时最多下载数量'),
      Column(children: [
        RadioListTile<MaxDownloadCount>(
          title: Text(
            '1个',
            textAlign: TextAlign.right,
          ),
          value: MaxDownloadCount.One,
          onChanged: _radioChanged,
          groupValue: _count,
        ),
        RadioListTile<MaxDownloadCount>(
          title: Text('3个', textAlign: TextAlign.right),
          value: MaxDownloadCount.Three,
          onChanged: _radioChanged,
          groupValue: _count,
        ),
        RadioListTile(
          title: Text('5个', textAlign: TextAlign.right),
          value: MaxDownloadCount.Five,
          onChanged: _radioChanged,
          groupValue: _count,
        ),
      ])
    ];
  }

  List<Widget> _renderSelectDictionary() {
    return [
      Text('更换下载目录地址'),
      Text(
        '注意: 更改路径不会影响到更改之前下载的文件',
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
      Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText('$_downloadPath'),
                ),
              ),
            ),
          ),
          FlatButton(
            onPressed: _changeDownloadPath,
            textColor: Colors.blue,
            child: Text('更换地址'),
          )
        ],
      )
    ];
  }

  void _changeDownloadPath() async {
    await permissionStorage();
    final path = await FilePicker.platform.getDirectoryPath();
    prefs.setString('downloadPath', path);
    // 更改下载地址的同时要修改正在运行的controller地址
    DownloadController.downloadPath = path;

    print(DownloadController.downloadPath);
    setState(() {
      _downloadPath = path;
    });
  }

  _radioChanged(MaxDownloadCount value) {
    if (_count == value) {
      return;
    }
    // 更改下载地址的同时要修改正在运行的scheduler的最大数量
    DownloadScheduler.downloadMaxSize = getMaxDownloadValue(value);
    prefs.setInt('downloadCount', value.index);
    setState(() {
      _count = value;
    });
  }
}
