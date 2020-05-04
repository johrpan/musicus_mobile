import 'package:musicus_common/musicus_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage extends MusicusSettingsStorage {
  SharedPreferences _pref;

  Future<void> load() async {
    _pref = await SharedPreferences.getInstance();
  }

  @override
  Future<int> getInt(String key) {
    return Future.value(_pref.getInt(key));
  }

  @override
  Future<String> getString(String key) {
    return Future.value(_pref.getString(key));
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _pref.setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _pref.setString(key, value);
  }
}
