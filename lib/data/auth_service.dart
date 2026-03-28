import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'schedule_data.dart';

class AuthService {
  static const String _projectId = 'domashka-381cb';
  static const String _databaseId = '(default)';
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 15);

  static String get _base =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/$_databaseId/documents';

  // ── Hashing ──────────────────────────────────────────────────────────

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static String generateClassCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Create class ────────────────────────────────────────────────────

  static Future<Map<String, String>?> createClass({
    required String adminEmail,
    required String adminPassword,
    required String className,
    required String schoolName,
    required String classPassword,
    required List<String> subjects,
    required List<String> lessonTimes,
    required Map<int, List<Map<String, String>>> schedule,
  }) async {
    try {
      final classId = 'cls_${DateTime.now().millisecondsSinceEpoch}';
      final code = generateClassCode();

      final body = _buildClassDoc(
        classId: classId,
        code: code,
        adminEmail: adminEmail.trim().toLowerCase(),
        adminHash: hashPassword(adminPassword),
        classHash: hashPassword(classPassword),
        classPasswordPlain: classPassword,
        className: className,
        schoolName: schoolName,
        subjects: subjects,
        lessonTimes: lessonTimes,
        schedule: schedule,
      );

      final res = await _client
          .post(
            Uri.parse('$_base/classes?documentId=$classId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint('Create class failed: ${res.statusCode} ${res.body}');
        return null;
      }

      // Index code → classId
      final codeRes = await _client
          .post(
            Uri.parse('$_base/class_codes?documentId=$code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fields': {
                'classId': {'stringValue': classId},
              }
            }),
          )
          .timeout(_timeout);

      if (codeRes.statusCode != 200 && codeRes.statusCode != 201) {
        debugPrint('Create code index failed: ${codeRes.statusCode}');
        await _client.delete(Uri.parse('$_base/classes/$classId'));
        return null;
      }

      await _saveSession(classId, 'admin', adminEmail.trim().toLowerCase());
      return {'classId': classId, 'code': code};
    } catch (e) {
      debugPrint('createClass error: $e');
      return null;
    }
  }

  // ── Join class (student) ────────────────────────────────────────────

  static Future<String?> joinClass(String code, String password) async {
    try {
      final upperCode = code.trim().toUpperCase();
      final codeRes = await _client
          .get(Uri.parse('$_base/class_codes/$upperCode'))
          .timeout(_timeout);
      if (codeRes.statusCode != 200) return null;

      final codeDoc = jsonDecode(codeRes.body);
      final classId = codeDoc['fields']?['classId']?['stringValue'];
      if (classId == null) return null;

      final classRes = await _client
          .get(Uri.parse('$_base/classes/$classId'))
          .timeout(_timeout);
      if (classRes.statusCode != 200) return null;

      final classDoc = jsonDecode(classRes.body) as Map<String, dynamic>;
      final storedHash =
          classDoc['fields']?['classPasswordHash']?['stringValue'];
      if (storedHash == null || hashPassword(password) != storedHash) {
        return null;
      }

      ClassSchedule.loadFromFirestoreDoc(classDoc);
      await _saveSession(classId, 'student', null);
      return classId;
    } catch (e) {
      debugPrint('joinClass error: $e');
      return null;
    }
  }

  // ── Admin login ─────────────────────────────────────────────────────

  static Future<String?> loginAdmin(String email, String password) async {
    try {
      final queryBody = {
        'structuredQuery': {
          'from': [
            {'collectionId': 'classes'}
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'adminEmail'},
              'op': 'EQUAL',
              'value': {'stringValue': email.trim().toLowerCase()},
            }
          },
          'limit': 1,
        }
      };

      final res = await _client
          .post(
            Uri.parse('$_base:runQuery'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(queryBody),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) return null;

      final results = jsonDecode(res.body) as List;
      if (results.isEmpty) return null;

      final doc = results.first['document'] as Map<String, dynamic>?;
      if (doc == null) return null;

      final storedHash =
          doc['fields']?['adminPasswordHash']?['stringValue'];
      if (storedHash == null || hashPassword(password) != storedHash) {
        return null;
      }

      final classId = (doc['name'] as String).split('/').last;
      ClassSchedule.loadFromFirestoreDoc(doc);
      await _saveSession(classId, 'admin', email.trim().toLowerCase());
      return classId;
    } catch (e) {
      debugPrint('loginAdmin error: $e');
      return null;
    }
  }

  // ── Load class into ClassSchedule ───────────────────────────────────

  static Future<bool> loadClassData(String classId) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/classes/$classId'))
          .timeout(_timeout);
      if (res.statusCode != 200) return false;

      final doc = jsonDecode(res.body) as Map<String, dynamic>;
      ClassSchedule.loadFromFirestoreDoc(doc);
      return true;
    } catch (e) {
      debugPrint('loadClassData error: $e');
      return false;
    }
  }

  // ── Get class info (code, password) ────────────────────────────────

  static Future<Map<String, dynamic>?> getClassInfo(String classId) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/classes/$classId'))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;

      final doc = jsonDecode(res.body) as Map<String, dynamic>;
      final fields = (doc['fields'] ?? {}) as Map<String, dynamic>;
      return {
        'code': fields['code']?['stringValue'] ?? '',
        'classPasswordHash': fields['classPasswordHash']?['stringValue'] ?? '',
        'classPasswordPlain': fields['classPasswordPlain']?['stringValue'] ?? '',
        'className': fields['className']?['stringValue'] ?? '',
        'schoolName': fields['schoolName']?['stringValue'] ?? '',
        'adminEmail': fields['adminEmail']?['stringValue'] ?? '',
      };
    } catch (e) {
      debugPrint('getClassInfo error: $e');
      return null;
    }
  }

  // ── Update schedule ─────────────────────────────────────────────────

  static Future<bool> updateClassSchedule(
    String classId, {
    required List<String> subjects,
    required List<String> lessonTimes,
    required Map<int, List<Map<String, String>>> schedule,
  }) async {
    try {
      final scheduleFields = _buildScheduleMap(schedule);
      final body = {
        'fields': {
          'subjects': {
            'arrayValue': {
              'values': subjects.map((s) => {'stringValue': s}).toList(),
            }
          },
          'lessonTimes': {
            'arrayValue': {
              'values':
                  lessonTimes.map((t) => {'stringValue': t}).toList(),
            }
          },
          'schedule': {
            'mapValue': {'fields': scheduleFields}
          },
        }
      };

      final mask =
          'updateMask.fieldPaths=subjects&updateMask.fieldPaths=lessonTimes&updateMask.fieldPaths=schedule';
      final res = await _client
          .patch(
            Uri.parse('$_base/classes/$classId?$mask'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('updateClassSchedule error: $e');
      return false;
    }
  }

  // ── Session ─────────────────────────────────────────────────────────

  static Future<void> _saveSession(
      String classId, String role, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dnevnik_class_id', classId);
    await prefs.setString('dnevnik_role', role);
    if (email != null) {
      await prefs.setString('dnevnik_admin_email', email);
    }
  }

  static Future<String?> getSavedClassId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dnevnik_class_id');
  }

  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dnevnik_role');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dnevnik_class_id');
    await prefs.remove('dnevnik_role');
    await prefs.remove('dnevnik_admin_email');
    ClassSchedule.reset();
  }

  // ── Firestore doc builders ──────────────────────────────────────────

  static Map<String, dynamic> _buildScheduleMap(
      Map<int, List<Map<String, String>>> schedule) {
    final fields = <String, dynamic>{};
    for (final entry in schedule.entries) {
      final lessons = entry.value
          .map((l) => {
                'mapValue': {
                  'fields': {
                    'subject': {'stringValue': l['subject'] ?? ''},
                    'room': {'stringValue': l['room'] ?? ''},
                  }
                }
              })
          .toList();
      fields[entry.key.toString()] = {
        'arrayValue': {'values': lessons}
      };
    }
    return fields;
  }

  static Map<String, dynamic> _buildClassDoc({
    required String classId,
    required String code,
    required String adminEmail,
    required String adminHash,
    required String classHash,
    required String classPasswordPlain,
    required String className,
    required String schoolName,
    required List<String> subjects,
    required List<String> lessonTimes,
    required Map<int, List<Map<String, String>>> schedule,
  }) {
    return {
      'fields': {
        'classId': {'stringValue': classId},
        'code': {'stringValue': code},
        'adminEmail': {'stringValue': adminEmail},
        'adminPasswordHash': {'stringValue': adminHash},
        'classPasswordHash': {'stringValue': classHash},
        'classPasswordPlain': {'stringValue': classPasswordPlain},
        'className': {'stringValue': className},
        'schoolName': {'stringValue': schoolName},
        'subjects': {
          'arrayValue': {
            'values': subjects.map((s) => {'stringValue': s}).toList(),
          }
        },
        'lessonTimes': {
          'arrayValue': {
            'values':
                lessonTimes.map((t) => {'stringValue': t}).toList(),
          }
        },
        'schedule': {
          'mapValue': {'fields': _buildScheduleMap(schedule)}
        },
      }
    };
  }
}
