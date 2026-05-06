import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';

class RoutePlannerPage extends ConsumerStatefulWidget {
  const RoutePlannerPage({super.key});

  @override
  ConsumerState<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends ConsumerState<RoutePlannerPage> {
  final _startLat = TextEditingController();
  final _startLon = TextEditingController();
  final _endLat = TextEditingController();
  final _endLon = TextEditingController();
  double _minRating = 4.0;
  bool _loading = false;
  List<Pointview> _suggested = const [];

  Future<void> _compute() async {
    final sLat = double.tryParse(_startLat.text.trim());
    final sLon = double.tryParse(_startLon.text.trim());
    final eLat = double.tryParse(_endLat.text.trim());
    final eLon = double.tryParse(_endLon.text.trim());
    if (sLat == null || sLon == null || eLat == null || eLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci coordinate valide per A e B.')),
      );
      return;
    }
    final start = LatLng(sLat, sLon);
    final end = LatLng(eLat, eLon);
    setState(() => _loading = true);
    try {
      final controller = ref.read(pointExperienceControllerProvider);
      final route = await controller.computeRoute(start: start, end: end);
      final points = await controller.scenicAlongRoute(
        route: route,
        minRating: _minRating,
      );
      if (!mounted) return;
      setState(() => _suggested = points);
      if (points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nessun punto trovato lungo il percorso.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Percorso panoramico A→B')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _startLat,
            decoration: const InputDecoration(labelText: 'Start lat'),
          ),
          TextField(
            controller: _startLon,
            decoration: const InputDecoration(labelText: 'Start lon'),
          ),
          TextField(
            controller: _endLat,
            decoration: const InputDecoration(labelText: 'End lat'),
          ),
          TextField(
            controller: _endLon,
            decoration: const InputDecoration(labelText: 'End lon'),
          ),
          const SizedBox(height: 12),
          Text('Votazione minima: ${_minRating.toStringAsFixed(1)}'),
          Slider(
            value: _minRating,
            min: 1,
            max: 5,
            divisions: 8,
            onChanged: (v) => setState(() => _minRating = v),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _compute,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Calcola'),
          ),
          const SizedBox(height: 16),
          ..._suggested.map(
            (p) => ListTile(
              title: Text(p.name ?? ''),
              subtitle: Text(
                'Rating ${p.avgRating?.toStringAsFixed(1) ?? '-'}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
