import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const String apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

class ApiClient {
  final http.Client _c;
  ApiClient([http.Client? c]) : _c = c ?? http.Client();

  Future<dynamic> get(String path) async {
    final r = await _c.get(Uri.parse('$apiBase$path'));
    return _decode(r);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required Uint8List bytes,
    required String filename,
  }) async {
    final req =
        http.MultipartRequest('POST', Uri.parse('$apiBase$path'))
          ..fields.addAll(fields)
          ..files.add(
            http.MultipartFile.fromBytes('image', bytes, filename: filename),
          );
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    return _decode(r);
  }

  Future<dynamic> post(String path, {Map<String, String>? body}) async {
    final r = await _c.post(Uri.parse('$apiBase$path'), body: body);
    return _decode(r);
  }

  Future<dynamic> delete(String path) async {
    final r = await _c.delete(Uri.parse('$apiBase$path'));
    return _decode(r);
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body);
    }
    throw Exception('HTTP ${r.statusCode}: ${r.body}');
  }
}
