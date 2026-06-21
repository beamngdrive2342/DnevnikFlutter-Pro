import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/image_data.dart';

class NetworkPhoto extends StatefulWidget {
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
  State<NetworkPhoto> createState() => _NetworkPhotoState();
}

class _NetworkPhotoState extends State<NetworkPhoto> {
  late Future<Uint8List?> _futureBytes;

  @override
  void initState() {
    super.initState();
    _futureBytes = _NetworkPhotoStore.load(widget.url);
  }

  @override
  void didUpdateWidget(covariant NetworkPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _futureBytes = _NetworkPhotoStore.load(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _futureBytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loading ??
              _PhotoStateBox(
                width: widget.width,
                height: widget.height,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return widget.error ??
              _PhotoStateBox(
                width: widget.width,
                height: widget.height,
                child: const Icon(Icons.broken_image_rounded),
              );
        }

        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
        );
      },
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

class _NetworkPhotoStore {
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxEntries = 24;

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static final Map<String, Future<Uint8List?>> _pending =
      <String, Future<Uint8List?>>{};

  static Future<Uint8List?> load(String source) {
    final cached = _cache[source];
    if (cached != null) {
      return Future<Uint8List?>.value(cached);
    }

    final pending = _pending[source];
    if (pending != null) {
      return pending;
    }

    final future = _fetch(source);
    _pending[source] = future;
    future.whenComplete(() => _pending.remove(source));
    return future;
  }

  static Future<Uint8List?> _fetch(String source) async {
    try {
      final bytes = await loadImageBytes(
        source,
        client: _client,
        timeout: _timeout,
      );
      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      _cache[source] = bytes;

      while (_cache.length > _maxEntries) {
        _cache.remove(_cache.keys.first);
      }

      return bytes;
    } catch (_) {
      return null;
    }
  }
}
