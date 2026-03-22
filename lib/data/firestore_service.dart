import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'schedule_data.dart';

class FirestoreService {
  static const String projectId = "domashka-381cb";
  static const String databaseId = "(default)";
  static const String collectionId = "homework";
  
  static String get baseUrl => 
      "https://firestore.googleapis.com/v1/projects/$projectId/databases/$databaseId/documents/$collectionId";

  static Future<List<HomeworkItem>> getHomework() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List<dynamic>? ?? [];
        return documents.map((doc) => _fromFirestore(doc)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching homework: $e");
    }
    return [];
  }

  static Future<bool> addHomework(HomeworkItem hw) async {
    try {
      final docId = hw.id;
      final response = await http.post(
        Uri.parse("$baseUrl?documentId=$docId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_toFirestore(hw)),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error adding homework: $e");
      return false;
    }
  }

  static Future<bool> updateHomework(HomeworkItem hw) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/${hw.id}"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_toFirestore(hw)),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating homework: $e");
      return false;
    }
  }

  static Future<bool> deleteHomework(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/$id"));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting homework: $e");
      return false;
    }
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
              'values': hw.fullResolutionUrls!.map((u) => {'stringValue': u}).toList()
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
      id: parseString('id').isNotEmpty ? parseString('id') : doc['name']!.split('/').last,
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
