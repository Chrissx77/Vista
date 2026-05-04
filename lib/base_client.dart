import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/const.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/models/profile.dart';

class BaseClient {
  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final bearer = (token != null && token.isNotEmpty)
        ? 'Bearer $token'
        : 'Bearer $anonKey';
    return {
      'Content-Type': 'application/json',
      'Authorization': bearer,
      'apikey': anonKey,
    };
  }

  Future<void> sendPointview(Pointview pointview) async {
    final url = Uri.parse('$baseUrl${API}sendPointview');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(pointview.toJson()),
    );

    if (response.statusCode == 200) {
      return;
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
    return 'Errore ${response.statusCode}: ${response.body}';
  }

  Future<List<Pointview>> getPointview() async {
    List<Pointview> pointViews = [];
    final url = Uri.parse('$baseUrl${API}getPointview');
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
        print('Errore Server: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('Errore di rete: $e');
      return [];
    }
  }

  Future<Pointview?> getPointviewById(int id) async {
    final url = Uri.parse(
      '$baseUrl${API}getPointviewById',
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
      print('Errore Server getPointviewById: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Errore di rete getPointviewById: $e');
      return null;
    }
  }

  Future<Profile?> getProfile() async {
    final url = Uri.parse('$baseUrl${API}getProfile');
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
      print('Errore Server getProfile: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Errore di rete getProfile: $e');
      return null;
    }
  }
}
