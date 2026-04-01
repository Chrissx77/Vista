import 'dart:convert'; // Necessario per jsonEncode
import 'package:http/http.dart' as http;
import 'const.dart';
import 'models/Pointview.dart';

class BaseClient {
  Future sendPointview(Pointview pointview) async {
    final url = Uri.parse('$baseUrl${API}sendPointview');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $anonKey',
          'apikey': anonKey,
        },
        body: jsonEncode(pointview.toJson()),
      );

      if (response.statusCode == 200) {
        print('Dati inviati correttamente');
      } else {
        print('Errore Server: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore di rete: $e');
      return "";
    }
  }

  Future<List<Pointview>> getPointview() async {
    List<Pointview> pointViews = [];
    final url = Uri.parse('$baseUrl${API}getPointview');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $anonKey',
          'apikey': anonKey,
        },
      );

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        var listaDati = decodedData['data'] ?? [];

        for (var item in listaDati) {
          pointViews.add(Pointview.fromJson(item));
        }

        return pointViews;
      } else {
        print('Errore Server: ${response.statusCode}');
        return []; // Ritorna lista vuota in caso di errore
      }
    } catch (e) {
      print('Errore di rete: $e');
      return []; // Ritorna lista vuota in caso di eccezione
    }
  }
}
