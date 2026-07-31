import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../network/api_client.dart';

/// Reusable interactive avatar.
///
/// - Shows network image if [avatarUrl] is set.
/// - Falls back to initials on [#1E293B] background.
/// - If [onUpload] is provided, tapping shows a camera/gallery picker and
///   calls [onUpload] with the chosen file (already validated ≤ 2 MB).
/// - Shows a loading overlay while [isUploading] is true.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final bool isUploading;
  final Future<void> Function(File file)? onUpload;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.radius = 40,
    this.isUploading = false,
    this.onUpload,
  });

  static const int _maxBytes = 2 * 1024 * 1024; // 2 MB

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (xfile == null) return;

    final file = File(xfile.path);
    final size = await file.length();
    if (size > _maxBytes && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto terlalu besar (maks. 2 MB)'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (context.mounted) await onUpload?.call(file);
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: const Text('Pilih dari Galeri', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _pick(context, ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
              title: const Text('Ambil Foto', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _pick(context, ImageSource.camera); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = avatarUrl != null && avatarUrl!.isNotEmpty
        ? ApiClient.resolveImageUrl(avatarUrl)
        : null;

    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    Widget avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E293B),
        border: Border.all(color: Colors.blue, width: 2),
        image: resolvedUrl != null
            ? DecorationImage(
                image: NetworkImage(resolvedUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: resolvedUrl == null
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.75,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );

    // Upload overlay
    if (isUploading) {
      avatar = Stack(
        alignment: Alignment.center,
        children: [
          avatar,
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black54,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    if (onUpload == null || isUploading) return avatar;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.65,
              height: radius * 0.65,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: radius * 0.38),
            ),
          ),
        ],
      ),
    );
  }
}
