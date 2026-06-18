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
  static const String firebaseWebApiKey = 'AIzaSyBUxrNWBGasZjWUvR6qtY0BuKr35iebUTQ';
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 15);

  static String? _idToken;
  static String? get idToken => _idToken;

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
    required List<String> subjects,
    required List<String> lessonTimes,
    required Map<int, List<Map<String, String>>> schedule,
  }) async {
    try {
      if (firebaseWebApiKey.contains('ВСТАВЬТЕ')) {
        debugPrint('ОШИБКА: Укажите firebaseWebApiKey в auth_service.dart!');
        return null;
      }

      // 1. Регистрируем админа в Firebase Auth
      final authRes = await _client.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseWebApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': adminEmail.trim().toLowerCase(),
          'password': adminPassword,
          'returnSecureToken': true
        }),
      );

      if (authRes.statusCode != 200) {
        debugPrint('Firebase Auth SignUp failed: ${authRes.body}');
        return null;
      }
      _idToken = jsonDecode(authRes.body)['idToken'];

      final classId = 'cls_${DateTime.now().millisecondsSinceEpoch}';
      final code = generateClassCode();

      final body = _buildClassDoc(
        classId: classId,
        code: code,
        adminEmail: adminEmail.trim().toLowerCase(),
        adminHash: hashPassword(adminPassword), // Оставляем для совместимости
        className: className,
        schoolName: schoolName,
        subjects: subjects,
        lessonTimes: lessonTimes,
        schedule: schedule,
      );

      final res = await _client
          .post(
            Uri.parse('$_base/classes?documentId=$classId'),
            headers: {
              'Content-Type': 'application/json',
              if (_idToken != null) 'Authorization': 'Bearer $_idToken'
            },
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
            headers: {
              'Content-Type': 'application/json',
              if (_idToken != null) 'Authorization': 'Bearer $_idToken'
            },
            body: jsonEncode({
              'fields': {
                'classId': {'stringValue': classId},
              }
            }),
          )
          .timeout(_timeout);

      if (codeRes.statusCode != 200 && codeRes.statusCode != 201) {
        debugPrint('Create code index failed: ${codeRes.statusCode}');
        await _client.delete(
          Uri.parse('$_base/classes/$classId'),
          headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
        );
        return null;
      }

      final refreshToken = jsonDecode(authRes.body)['refreshToken'];
      await _saveSession(classId, 'admin', adminEmail.trim().toLowerCase(), refreshToken);
      return {'classId': classId, 'code': code};
    } catch (e) {
      debugPrint('createClass error: $e');
      return null;
    }
  }

  // ── Join class (student) ────────────────────────────────────────────

  static Future<String?> joinClass(String code) async {
    try {
      if (firebaseWebApiKey.contains('ВСТАВЬТЕ')) return null;

      // 1. Анонимный логин для ученика
      final authRes = await _client.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseWebApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'returnSecureToken': true}),
      );
      String? refreshToken;
      if (authRes.statusCode == 200) {
        final data = jsonDecode(authRes.body);
        _idToken = data['idToken'];
        refreshToken = data['refreshToken'];
      }

      final upperCode = code.trim().toUpperCase();
      final codeRes = await _client
          .get(
            Uri.parse('$_base/class_codes/$upperCode'),
            headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
          )
          .timeout(_timeout);
      if (codeRes.statusCode != 200) return null;

      final codeDoc = jsonDecode(codeRes.body);
      final classId = codeDoc['fields']?['classId']?['stringValue'];
      if (classId == null) return null;

      final classRes = await _client
          .get(
            Uri.parse('$_base/classes/$classId'),
            headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
          )
          .timeout(_timeout);
      if (classRes.statusCode != 200) return null;

      final classDoc = jsonDecode(classRes.body) as Map<String, dynamic>;

      ClassSchedule.loadFromFirestoreDoc(classDoc);
      await _saveSession(classId, 'student', null, refreshToken);
      return classId;
    } catch (e) {
      debugPrint('joinClass error: $e');
      return null;
    }
  }

  // ── Admin login ─────────────────────────────────────────────────────

  static Future<String?> loginAdmin(String email, String password) async {
    try {
      if (firebaseWebApiKey.contains('ВСТАВЬТЕ')) return null;

      // 1. Логин через Firebase Auth
      final authRes = await _client.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseWebApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
          'returnSecureToken': true
        }),
      );

      if (authRes.statusCode != 200) {
        debugPrint('Firebase Auth Login failed: ${authRes.body}');
        return null;
      }
      final authData = jsonDecode(authRes.body);
      _idToken = authData['idToken'];
      final refreshToken = authData['refreshToken'];

      // 2. Ищем класс
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
            headers: {
              'Content-Type': 'application/json',
              if (_idToken != null) 'Authorization': 'Bearer $_idToken'
            },
            body: jsonEncode(queryBody),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) return null;

      final results = jsonDecode(res.body) as List;
      if (results.isEmpty || results.first['document'] == null) return null;

      final doc = results.first['document'] as Map<String, dynamic>;
      final classId = (doc['name'] as String).split('/').last;
      
      ClassSchedule.loadFromFirestoreDoc(doc);
      await _saveSession(classId, 'admin', email.trim().toLowerCase(), refreshToken);
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
          .get(
            Uri.parse('$_base/classes/$classId'),
            headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
          )
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
          .get(
            Uri.parse('$_base/classes/$classId'),
            headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;

      final doc = jsonDecode(res.body) as Map<String, dynamic>;
      final fields = (doc['fields'] ?? {}) as Map<String, dynamic>;
      return {
        'code': fields['code']?['stringValue'] ?? '',
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
              'values': lessonTimes.map((t) => {'stringValue': t}).toList(),
            }
          },
          'schedule': {
            'mapValue': {'fields': scheduleFields}
          },
        }
      };

      const mask =
          'updateMask.fieldPaths=subjects&updateMask.fieldPaths=lessonTimes&updateMask.fieldPaths=schedule';
      final res = await _client
          .patch(
            Uri.parse('$_base/classes/$classId?$mask'),
            headers: {
              'Content-Type': 'application/json',
              if (_idToken != null) 'Authorization': 'Bearer $_idToken'
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('updateClassSchedule error: $e');
      return false;
    }
  }

  static Future<bool> deleteClass({
    required String classId,
    required String adminPassword,
  }) async {
    try {
      final classRes = await _client
          .get(
            Uri.parse('$_base/classes/$classId'),
            headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
          )
          .timeout(_timeout);
      if (classRes.statusCode != 200) {
        return false;
      }

      final doc = jsonDecode(classRes.body) as Map<String, dynamic>;
      final fields = (doc['fields'] ?? {}) as Map<String, dynamic>;
      final storedHash = fields['adminPasswordHash']?['stringValue'] as String?;
      final classCode = fields['code']?['stringValue'] as String? ?? '';

      if (storedHash == null || hashPassword(adminPassword) != storedHash) {
        return false;
      }

      final homeworkDeleted = await _deleteHomeworkSubcollection(classId);
      if (!homeworkDeleted) {
        return false;
      }

      if (classCode.isNotEmpty) {
        final codeRes = await _client
            .delete(
              Uri.parse('$_base/class_codes/$classCode'),
              headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
            )
            .timeout(_timeout);
        if (codeRes.statusCode != 200 && codeRes.statusCode != 404) {
          debugPrint(
            'deleteClass code index failed: ${codeRes.statusCode} ${codeRes.body}',
          );
          return false;
        }
      }

      final deleteClassRes = await _client
          .delete(
            Uri.parse('$_base/classes/$classId'),
            headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
          )
          .timeout(_timeout);
      if (deleteClassRes.statusCode != 200) {
        debugPrint(
          'deleteClass class doc failed: ${deleteClassRes.statusCode} ${deleteClassRes.body}',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('deleteClass error: $e');
      return false;
    }
  }

  // ── Session ─────────────────────────────────────────────────────────

  static Future<void> _saveSession(
      String classId, String role, String? email, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dnevnik_class_id', classId);
    await prefs.setString('dnevnik_role', role);
    if (email != null) {
      await prefs.setString('dnevnik_admin_email', email);
    }
    if (refreshToken != null) {
      await prefs.setString('dnevnik_refresh_token', refreshToken);
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
    await prefs.remove('dnevnik_refresh_token');
    _idToken = null;
    ClassSchedule.reset();
  }

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('dnevnik_refresh_token');
    if (refreshToken == null) return false;

    try {
      final res = await _client.post(
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=$firebaseWebApiKey'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _idToken = data['id_token'];
        final newRefreshToken = data['refresh_token'];
        if (newRefreshToken != null) {
          await prefs.setString('dnevnik_refresh_token', newRefreshToken);
        }
        return true;
      }
    } catch (e) {
      debugPrint('restoreSession error: $e');
    }
    return false;
  }

  static Future<bool> _deleteHomeworkSubcollection(String classId) async {
    String? pageToken;

    do {
      final uri = Uri.parse(
        pageToken == null || pageToken.isEmpty
            ? '$_base/classes/$classId/homework'
            : '$_base/classes/$classId/homework?pageToken=$pageToken',
      );

      final listRes = await _client.get(
        uri,
        headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
      ).timeout(_timeout);
      if (listRes.statusCode != 200) {
        debugPrint(
          'deleteClass homework list failed: ${listRes.statusCode} ${listRes.body}',
        );
        return false;
      }

      final data = jsonDecode(listRes.body) as Map<String, dynamic>;
      final documents =
          (data['documents'] as List<dynamic>? ?? const <dynamic>[]);

      for (final rawDocument in documents) {
        final document = rawDocument as Map<String, dynamic>;
        final name = document['name'] as String?;
        if (name == null || name.isEmpty) {
          continue;
        }

        final deleteRes = await _client
            .delete(
              Uri.parse('https://firestore.googleapis.com/v1/$name'),
              headers: {if (_idToken != null) 'Authorization': 'Bearer $_idToken'},
            )
            .timeout(_timeout);
        if (deleteRes.statusCode != 200 && deleteRes.statusCode != 404) {
          debugPrint(
            'deleteClass homework delete failed: ${deleteRes.statusCode} ${deleteRes.body}',
          );
          return false;
        }
      }

      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);

    return true;
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
        'className': {'stringValue': className},
        'schoolName': {'stringValue': schoolName},
        'subjects': {
          'arrayValue': {
            'values': subjects.map((s) => {'stringValue': s}).toList(),
          }
        },
        'lessonTimes': {
          'arrayValue': {
            'values': lessonTimes.map((t) => {'stringValue': t}).toList(),
          }
        },
        'schedule': {
          'mapValue': {'fields': _buildScheduleMap(schedule)}
        },
      }
    };
  }
}
