abstract class ShareService {
  Future<void> shareFile(String filePath, {String? subject, String? text});
}

abstract class FilePickerService {
  Future<String?> pickJsonFileContent();
}
