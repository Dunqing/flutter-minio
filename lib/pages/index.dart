import 'BucketRoute.dart';
import 'FileOperationRoute.dart';
import 'HomePage.dart';
import 'SettingRoute.dart';

// ignore: non_constant_identifier_names
final Routes = {
  "/": (context) => MyHomePage(
        title: 'Buckets',
      ),
  "Bucket": (context) => BucketRoute(),
  "FileOperationLog": (context) => FileOperationRoute(),
  "Setting": (context) => SettingRoute(),
};
