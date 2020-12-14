import 'package:MinioClient/minio/minio.dart';
import 'package:MinioClient/utils/storage.dart';
import 'package:MinioClient/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSetting extends StatefulWidget {
  AccountSetting({Key key}) : super(key: key);

  @override
  _AccountSettingState createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  GlobalKey _formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    this.initData();
    super.initState();
  }

  // 设置默认值
  initData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      this._accessKey = prefs.getString('accessKey');
      this._secretKey = prefs.getString('secretKey');
      this._url = prefs.getString('inputUrl');
    });
    Future.delayed(Duration(milliseconds: 50)).then((_) {
      (this._formKey.currentState as FormState).reset();
    });
  }

  String _accessKey = '';
  String _secretKey = '';
  String _url = '';

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints.expand(),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: _accessKey,
                  onSaved: (value) {
                    setState(() {
                      this._accessKey = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Access Key',
                    hintText: '请输入accessKey',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value.trim().isEmpty) {
                      return 'Access Key不能为空';
                    }
                    return null;
                  },
                  textAlign: TextAlign.center,
                ),
                TextFormField(
                  initialValue: _secretKey,
                  onSaved: (value) {
                    setState(() {
                      this._secretKey = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Secret Key',
                    hintText: '请输入secretKey',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value.trim().isEmpty) {
                      return 'Secret Key不能为空';
                    }
                    return null;
                  },
                  textAlign: TextAlign.center,
                ),
                // 如https://play.min.io
                TextFormField(
                  initialValue: _url,
                  onSaved: (value) {
                    setState(() {
                      this._url = value;
                    });
                  },
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'URL地址',
                    hintText: '请输入部署的地址',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    if (value.trim().isEmpty) {
                      return 'url地址不能为空';
                    }
                    return null;
                  },
                  textAlign: TextAlign.center,
                ),
                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RaisedButton(
                        color: Colors.blue,
                        child:
                            Text('保存', style: TextStyle(color: Colors.white)),
                        onPressed: _onSave,
                      ),
                      SizedBox(width: 50),
                      RaisedButton(
                        child: Text('重置'),
                        onPressed: _reset,
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }

  Future<void> _onSave() async {
    final FormState currentState = (this._formKey.currentState as FormState);
    if (!currentState.validate()) {
      return;
    }
    currentState.save();
    final info = getUrlInfo(this._url);
    final protocol = info.namedGroup('protocol');
    final String domain = info.namedGroup('domain');
    final String port = info.namedGroup('port');

    await setMinioConfig(
        useSSL: protocol == 'http' ? false : protocol != null,
        endPoint: domain.replaceFirst(':$port', ''),
        port: port != null ? int.parse(port) : port,
        url: this._url,
        accessKey: this._accessKey,
        secretKey: this._secretKey);

    await MinioController.resetMinio();
    toast('保存成功');
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) {
      print(route);
      return true;
    });
    print('$protocol $domain $port');
  }

  void _reset() {
    final FormState currentState = (this._formKey.currentState as FormState);
    currentState.reset();
  }
}
