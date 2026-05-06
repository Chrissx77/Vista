// Genera assets/launcher/icon_source.png da images/iconaApp.png
// con zoom centrale (logo più grande nel quadrato). Esegui prima di
// `dart run flutter_launcher_icons`.
import 'dart:io';

import 'package:image/image.dart' as img;

/// Fattore >1 ingrandisce il contenuto rispetto al bordo (crop centrale).
const double _scale = 1.12;

void main() {
  final input = File('images/iconaApp.png');
  if (!input.existsSync()) {
    stderr.writeln('Manca images/iconaApp.png');
    exitCode = 1;
    return;
  }
  final raw = img.decodePng(input.readAsBytesSync());
  if (raw == null) {
    stderr.writeln('Impossibile decodificare il PNG');
    exitCode = 1;
    return;
  }
  final sw = (raw.width * _scale).round();
  final sh = (raw.height * _scale).round();
  final scaled = img.copyResize(
    raw,
    width: sw,
    height: sh,
    interpolation: img.Interpolation.cubic,
  );
  final left = (sw - raw.width) ~/ 2;
  final top = (sh - raw.height) ~/ 2;
  final out = img.copyCrop(
    scaled,
    x: left,
    y: top,
    width: raw.width,
    height: raw.height,
  );
  final dir = Directory('assets/launcher');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final outFile = File('assets/launcher/icon_source.png');
  outFile.writeAsBytesSync(img.encodePng(out));
  stdout.writeln('Scritto ${outFile.path} (zoom $_scale)');
}
