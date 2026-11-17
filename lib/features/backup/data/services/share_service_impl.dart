import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/services/share_service.dart';

class ShareServiceImpl implements ShareService {
  @override
  Future<void> shareFile(String filePath, {String? subject, String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: subject,
        text: text,
      ),
    );
  }
}

class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<String?> pickJsonFileContent() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      return await file.readAsString();
    }
    return null;
  }
}
