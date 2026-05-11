import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> resolvePhotoPath(String stored) async {
  // Remote URL — pass through
  if (stored.startsWith('http')) return stored;
  // Already a valid absolute path (shouldn't happen with new code, but safe)
  if (stored.startsWith('/') && await File(stored).exists()) return stored;
  // Legacy absolute path that no longer works — extract just the filename
  if (stored.startsWith('/')) {
    final fileName = stored.split('/').last;
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'book_photos', fileName);
  }
  // New relative path format
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, stored);
}