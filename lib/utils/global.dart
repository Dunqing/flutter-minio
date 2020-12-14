final _map = Map();

class SignleInstance {
  static T getInstance<T>(String key) {
    return _map[key] as T;
  }

  static registerInstance(String key, value) {
    if (_map.containsKey(key)) {
      throw 'Error! Container key';
    }
    _map[key] = value;
  }

  static clear() {
    _map.clear();
  }
}
