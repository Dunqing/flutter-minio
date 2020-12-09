import '../main.dart';
import 'FileOperationRoute.dart';
import 'bucket.dart';

// ignore: non_constant_identifier_names
final Routes = {
  "/": (context) => MyHomePage(
        title: 'Home',
      ),
  "Bucket": (context) => BucketRoute(),
  "FileOperationLog": (context) => FileOperationRoute(),
};
