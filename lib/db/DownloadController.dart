import 'package:sqflite/sqflite.dart';

Database database;

class DownloadController {
  Database _database;
  DownloadController() {
    if (database != null) {
      this._database = database;
      return;
    }
    getDatabasesPath().then((path) async {
      final dbPath = path + '/minio.db';
      this._database = await openDatabase(dbPath, version: 1,
          onCreate: (Database db, int version) {
        db.execute(
            'CREATE TABLE DownloadLog (id INTEGER PRIMARY KEY, filename TEXT, size INTEGER, create_at TEXT, update_at TEXT, rate INTEGER)');
      });
      database = this._database;
    });
  }

  Future<int> insert(filename, size, createAt, updateAt, rate) async {
    final result = await this._database.rawInsert(
        'INSERT INTO DownloadLog (filename, size, create_at, update_at, rate) VALUES(?, ?, ?, ?, ?)',
        [filename, size, createAt, updateAt, rate]);
    return result;
  }

  Future<List<Map<String, dynamic>>> finaAll() async {
    print('test');
    print(this._database.rawQuery);
    final result = await this._database.rawQuery('SELECT * FROM "DownloadLog"');
    return result;
  }
}
