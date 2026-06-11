import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final client = http.Client();
  const projectId = 'domashka-381cb';
  const base =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  print('--- Checking specific document read ---');
  try {
    final res =
        await client.get(Uri.parse('$base/classes/nonexistent_test_class_id'));
    print('GET Status: ${res.statusCode}');
    print('GET Body: ${res.body}');
  } catch (e) {
    print('GET Error: $e');
  }

  print('\n--- Checking document create ---');
  try {
    final classId = 'test_check_${DateTime.now().millisecondsSinceEpoch}';
    final body = {
      'fields': {
        'classId': {'stringValue': classId},
        'className': {'stringValue': 'Test Verification Class'},
      }
    };
    final res = await client.post(
      Uri.parse('$base/classes?documentId=$classId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('POST Status: ${res.statusCode}');
    print('POST Body: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      print('\n--- Success! Cleaning up test document ---');
      final delRes = await client.delete(Uri.parse('$base/classes/$classId'));
      print('DELETE Status: ${delRes.statusCode}');
    }
  } catch (e) {
    print('POST Error: $e');
  }

  client.close();
}
