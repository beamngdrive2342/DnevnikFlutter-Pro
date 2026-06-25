import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/image_data.dart';

class NetworkPhoto extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? loading;
  final Widget? error;

  const NetworkPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _buildError();
    }

    if (isRemoteImageUrl(url)) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => loading ?? _PhotoStateBox(
          width: width,
          height: height,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, _, __) => _buildError(),
      );
    }
    
    if (isInlineImageData(url)) {
      final bytes = decodeInlineImageData(url);
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
          errorBuilder: (context, _, __) => _buildError(),
        );
      }
      return _buildError();
    }
    
    // Fallback for local files
    return Image.file(
      File(url),
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      errorBuilder: (context, _, __) => _buildError(),
    );
  }

  Widget _buildError() {
    return error ?? _PhotoStateBox(
      width: width,
      height: height,
      child: const Icon(Icons.broken_image_rounded),
    );
  }
}

class _PhotoStateBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;

  const _PhotoStateBox({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(child: child),
    );
  }
}
