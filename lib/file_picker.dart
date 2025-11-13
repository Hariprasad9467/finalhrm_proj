import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerHelper {
  /// Open file picker dialog and return selected file info
  static Future<PlatformFile?> pickFile({
    List<String> allowedExtensions = const ['jpg', 'jpeg', 'png', 'pdf'],
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
    } catch (e) {
      debugPrint("FilePicker Error: $e");
    }

    return null;
  }

  /// Optional: Show a preview dialog for uploaded file
  static void showFilePreview(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Uploaded File"),
        content: Text("You uploaded: $fileName"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
