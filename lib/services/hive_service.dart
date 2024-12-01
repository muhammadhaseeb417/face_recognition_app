import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('userBox');
  }

  static void saveUser(String userName) {
    var box = Hive.box('userBox');
    box.put('userName', userName);
  }

  static String? getUser() {
    var box = Hive.box('userBox');
    return box.get('userName');
  }

  static void clearUser() {
    var box = Hive.box('userBox');
    box.delete('userName');
  }
}
