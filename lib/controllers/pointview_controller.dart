import 'package:vista/base_client.dart';
import 'package:vista/models/pointview.dart';

class PointviewController {
  final BaseClient _client;

  PointviewController(this._client);

  Future<List<Pointview>> getAll() => _client.getPointview();

  Future<void> create(Pointview pointview) => _client.sendPointview(pointview);

  Future<Pointview> getById(int id) async {
    final p = await _client.getPointviewById(id);
    if (p == null) {
      throw Exception('Punto non trovato o non accessibile.');
    }
    return p;
  }
}
