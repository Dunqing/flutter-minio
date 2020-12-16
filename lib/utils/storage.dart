import 'package:shared_preferences/shared_preferences.dart';

Future<bool> hasMinioConfig() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('accessKey')?.isNotEmpty == true &&
      prefs.getString('secretKey')?.isNotEmpty == true &&
      prefs.getString('endPoint')?.isNotEmpty == true;
}

Future<T> getConfigForKey<T>(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.get(key) as T;
}

Future<void> setMinioConfig(
    {useSSL, endPoint, port, url, accessKey, secretKey}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('useSSL', useSSL);
  prefs.setString('endPoint', endPoint);
  prefs.setInt('port', port);
  prefs.setString('inputUrl', url);
  prefs.setString('accessKey', accessKey);
  prefs.setString('secretKey', secretKey);
}
