import 'package:flutter/material.dart';

enum PhotoAction { camera, gallery, remove }

Future<PhotoAction?> showPhotoSourceSheet(
  BuildContext context, {
  required bool hasPhoto,
}) {
  return showModalBottomSheet<PhotoAction>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(sheetContext, PhotoAction.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(sheetContext, PhotoAction.gallery),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove photo'),
              onTap: () => Navigator.pop(sheetContext, PhotoAction.remove),
            ),
        ],
      ),
    ),
  );
}
