import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'schedule_data.dart';

class FirestoreService {
  static const String projectId = "domashka-381cb";
  static const String databaseId = "(default)";
  static const String collectionId = "homework";

  static final http.Client _client = http.Client();
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Duration _cacheTtl = Duration(seconds: 20);
  static const int _maxRetries = 2;
  static const Set<int> _retryableHttpStatus = {
    408,
    429,
    500,
    502,
    503,
    504,
  };

  static List<HomeworkItem>? _cachedHomework;
  static DateTime? _cacheExpiresAt;
  static Future<List<HomeworkItem>>? _pendingHomeworkRequest;

  static String get baseUrl =>
      "https://firestore.googleapis.com/v1/projects/$projectId/databases/$databaseId/documents/$collectionId";

  static Future<List<HomeworkItem>> getHomework(
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _getFreshCache();
      if (cached != null) {
        return cached;
      }
      if (_pendingHomeworkRequest != null) {
        return List<HomeworkItem>.from(await _pendingHomeworkRequest!);
      }
    }

    final request = _fetchHomework();
    _pendingHomeworkRequest = request;

    try {
      return List<HomeworkItem>.from(await request);
    } finally {
      if (identical(_pendingHomeworkRequest, request)) {
        _pendingHomeworkRequest = null;
      }
    }
  }

  static Future<List<HomeworkItem>> _fetchHomework() async {
    try {
      final response = await _requestWithRetry(
        () => _client.get(Uri.parse(baseUrl)),
      );
      if (response == null) {
        return _getFreshCache() ?? const [];
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final documents = data['documents'] as List<dynamic>? ?? const [];
        final homework = documents
            .map((doc) => _fromFirestore(doc as Map<String, dynamic>))
            .toList(growable: false);
        _updateCache(homework);
        return homework;
      }
      debugPrint("Error fetching homework: HTTP ${response.statusCode}");
    } catch (e) {
      debugPrint("Error fetching homework: $e");
    }
    return _getFreshCache() ?? const [];
  }

  static Future<bool> addHomework(HomeworkItem hw) async {
    try {
      final docId = hw.id;
      final response = await _requestWithRetry(
        () => _client.post(
          Uri.parse("$baseUrl?documentId=$docId"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_toFirestore(hw)),
        ),
      );
      if (response == null) {
        return false;
      }
      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        _updateCachedItem(hw);
      } else {
        debugPrint("Error adding homework: HTTP ${response.statusCode}");
      }
      return success;
    } catch (e) {
      debugPrint("Error adding homework: $e");
      return false;
    }
  }

  static Future<bool> updateHomework(HomeworkItem hw) async {
    try {
      final response = await _requestWithRetry(
        () => _client.patch(
          Uri.parse("$baseUrl/${hw.id}"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_toFirestore(hw)),
        ),
      );
      if (response == null) {
        return false;
      }
      final success = response.statusCode == 200;
      if (success) {
        _updateCachedItem(hw);
      } else {
        debugPrint("Error updating homework: HTTP ${response.statusCode}");
      }
      return success;
    } catch (e) {
      debugPrint("Error updating homework: $e");
      return false;
    }
  }

  static Future<bool> deleteHomework(String id) async {
    try {
      final response = await _requestWithRetry(
        () => _client.delete(Uri.parse("$baseUrl/$id")),
      );
      if (response == null) {
        return false;
      }
      final success = response.statusCode == 200;
      if (success) {
        _removeCachedItem(id);
      } else {
        debugPrint("Error deleting homework: HTTP ${response.statusCode}");
      }
      return success;
    } catch (e) {
      debugPrint("Error deleting homework: $e");
      return false;
    }
  }

  static List<HomeworkItem>? _getFreshCache() {
    final cache = _cachedHomework;
    final expiresAt = _cacheExpiresAt;
    if (cache == null || expiresAt == null) {
      return null;
    }
    if (DateTime.now().isAfter(expiresAt)) {
      _cachedHomework = null;
      _cacheExpiresAt = null;
      return null;
    }
    return List<HomeworkItem>.from(cache);
  }

  static void _updateCache(List<HomeworkItem> homework) {
    _cachedHomework = List<HomeworkItem>.unmodifiable(homework);
    _cacheExpiresAt = DateTime.now().add(_cacheTtl);
  }

  static void _updateCachedItem(HomeworkItem hw) {
    final current = _cachedHomework;
    if (current == null) {
      return;
    }
    final updated = current.where((item) => item.id != hw.id).toList();
    updated.add(hw);
    _updateCache(updated);
  }

  static void _removeCachedItem(String id) {
    final current = _cachedHomework;
    if (current == null) {
      return;
    }
    _updateCache(current.where((item) => item.id != id).toList());
  }

  static Future<http.Response?> _requestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    Object? lastError;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await request().timeout(_requestTimeout);
        final shouldRetry = _retryableHttpStatus.contains(response.statusCode);
        if (!shouldRetry || attempt == _maxRetries) {
          return response;
        }
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt == _maxRetries) {
          break;
        }
      } on SocketException catch (e) {
        lastError = e;
        if (attempt == _maxRetries) {
          break;
        }
      } on http.ClientException catch (e) {
        lastError = e;
        if (attempt == _maxRetries) {
          break;
        }
      } catch (e) {
        debugPrint("Request failed: $e");
        return null;
      }

      final delay = Duration(milliseconds: 400 * (attempt + 1));
      await Future<void>.delayed(delay);
    }

    if (lastError != null) {
      debugPrint("Request failed after retries: $lastError");
    }
    return null;
  }

  static Map<String, dynamic> _toFirestore(HomeworkItem hw) {
    return {
      'fields': {
        'id': {'stringValue': hw.id},
        'subject': {'stringValue': hw.subject},
        'task': {'stringValue': hw.task},
        'deadline': {'stringValue': hw.deadline},
        if (hw.imageUrl != null) 'imageUrl': {'stringValue': hw.imageUrl},
        if (hw.imageUrls != null && hw.imageUrls!.isNotEmpty)
          'imageUrls': {
            'arrayValue': {
              'values': hw.imageUrls!.map((u) => {'stringValue': u}).toList()
            }
          },
        if (hw.fullResolutionUrls != null && hw.fullResolutionUrls!.isNotEmpty)
          'fullResolutionUrls': {
            'arrayValue': {
              'values':
                  hw.fullResolutionUrls!.map((u) => {'stringValue': u}).toList()
            }
          },
        'done': {'booleanValue': hw.done},
        'fromSchedule': {'booleanValue': hw.fromSchedule},
      }
    };
  }

  static HomeworkItem _fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] ?? {};

    String parseString(String key) => fields[key]?['stringValue'] ?? '';
    bool parseBool(String key) => fields[key]?['booleanValue'] ?? false;

    List<String>? urls;
    if (fields['imageUrls']?['arrayValue']?['values'] != null) {
      urls = (fields['imageUrls']['arrayValue']['values'] as List)
          .map((e) => e['stringValue'] as String)
          .toList();
    }

    List<String>? fullUrls;
    if (fields['fullResolutionUrls']?['arrayValue']?['values'] != null) {
      fullUrls = (fields['fullResolutionUrls']['arrayValue']['values'] as List)
          .map((e) => e['stringValue'] as String)
          .toList();
    }

    return HomeworkItem(
      id: parseString('id').isNotEmpty
          ? parseString('id')
          : doc['name']!.split('/').last,
      subject: parseString('subject'),
      task: parseString('task'),
      deadline: parseString('deadline'),
      imageUrl: fields['imageUrl']?['stringValue'],
      imageUrls: urls,
      fullResolutionUrls: fullUrls,
      done: parseBool('done'),
      fromSchedule: parseBool('fromSchedule'),
    );
  }
}
