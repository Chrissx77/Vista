import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/const.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/models/profile.dart';
import 'package:vista/utility/logger.dart';

class BaseClient {
  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': anonKey,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<int> sendPointview(Pointview pointview) async {
    final url = Uri.parse('$baseUrl${functionsApiPath}sendPointview');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(pointview.toJson()),
    );

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final id = decoded['id'];
        if (id is num) return id.toInt();
        // Compat: alcune versioni della Edge Function rispondono con { ok: true }
        // senza id. In questo caso consideriamo la creazione riuscita.
        if (decoded['ok'] == true || decoded['success'] == true) {
          return -1;
        }
      } catch (_) {
        // Body non JSON ma HTTP 200: trattiamo comunque come successo.
      }
      return -1;
    }
    throw Exception(_errorMessageFromResponse(response));
  }

  String _errorMessageFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return 'Errore ${response.statusCode}';
  }

  Future<List<Pointview>> getPointview() async {
    List<Pointview> pointViews = [];
    final url = Uri.parse('$baseUrl${functionsApiPath}getPointview');
    try {
      final response = await http.get(url, headers: _headers());

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body) as Map<String, dynamic>;
        var listaDati = decodedData['data'] ?? [];

        for (var item in listaDati as List<dynamic>) {
          pointViews.add(Pointview.fromJson(item as Map<String, dynamic>));
        }

        return pointViews;
      } else {
        appLog('getPointview HTTP ${response.statusCode}');
        return [];
      }
    } catch (e) {
      appLog('getPointview network error: ${e.runtimeType}');
      return [];
    }
  }

  Future<Pointview?> getPointviewById(int id) async {
    final url = Uri.parse(
      '$baseUrl${functionsApiPath}getPointviewById',
    ).replace(queryParameters: {'id': id.toString()});
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          return Pointview.fromJson(data);
        }
        return null;
      }
      appLog('getPointviewById HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      appLog('getPointviewById network error: ${e.runtimeType}');
      return null;
    }
  }

  Future<Profile?> getProfile() async {
    final url = Uri.parse('$baseUrl${functionsApiPath}getProfile');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          return Profile.fromJson(data);
        }
        return null;
      }
      appLog('getProfile HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      appLog('getProfile network error: ${e.runtimeType}');
      return null;
    }
  }
}
