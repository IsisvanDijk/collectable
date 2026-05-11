import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/photo_path.dart';

class LocalImage extends StatefulWidget {
  final String storedPath;
  final double? width, height;
  final BoxFit fit;
  final Widget Function(BuildContext) placeholder;

  const LocalImage({
    super.key,
    required this.storedPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.placeholder,
  });

  @override
  State<LocalImage> createState() => _LocalImageState();
}

class _LocalImageState extends State<LocalImage> {
  late Future<String> _pathFuture;

  @override
  void initState() {
    super.initState();
    _pathFuture = resolvePhotoPath(widget.storedPath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _pathFuture,
      builder: (context, snap) {
        if (!snap.hasData) return widget.placeholder(context);
        final path = snap.data!;
        if (path.startsWith('http')) {
          return Image.network(path,
              width: widget.width, height: widget.height, fit: widget.fit,
              errorBuilder: (_, __, ___) => widget.placeholder(context));
        }
        return Image.file(File(path),
            width: widget.width, height: widget.height, fit: widget.fit,
            errorBuilder: (_, __, ___) => widget.placeholder(context));
      },
    );
  }
}