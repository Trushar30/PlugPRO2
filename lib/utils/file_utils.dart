import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getLocalFile(String filename) async {
    final path = await getLocalPath();
    return File('$path/$filename');
  }

  static Future<File> saveFile(String filename, List<int> bytes) async {
    final file = await getLocalFile(filename);
    return file.writeAsBytes(bytes);
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }
}
