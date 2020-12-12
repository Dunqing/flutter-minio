import 'FileOperationRoute.dart';
import 'HomePage.dart';
import 'bucket.dart';

// ignore: non_constant_identifier_names
final Routes = {
  "/": (context) => MyHomePage(
        title: 'Buckets',
      ),
  "Bucket": (context) => BucketRoute(),
  "FileOperationLog": (context) => FileOperationRoute(),
};
