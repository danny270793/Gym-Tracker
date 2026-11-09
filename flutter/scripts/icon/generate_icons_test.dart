// Draws the app icon and writes the PNGs used by flutter_launcher_icons and
// flutter_native_splash. Run from flutter/:
//
//   asdf exec flutter test scripts/icon/generate_icons_test.dart
//   asdf exec dart run flutter_launcher_icons
//   asdf exec dart run flutter_native_splash:create
//
// Design: a dumbbell under a rising trend arrow, on the app's deep orange.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const background = Color(0xFFF4511E); // deep orange 600
const backgroundDeep = Color(0xFFBF360C); // deep orange 900
const darkSplash = Color(0xFF3E1A0C);
const plate = Color(0xFFFFFFFF);
const plateShade = Color(0xFFFFE3D6);
const bar = Color(0xFFFFD0BC);
const arrow = Color(0xFFFFC94D);

/// Paints the glyph centered in a [size] square, scaled to [scale] of it.
void paintGlyph(
  Canvas canvas,
  double size, {
  double scale = 1,
  bool mono = false,
}) {
  canvas.save();
  canvas.translate(size / 2, size / 2);
  canvas.scale(size / 1024 * scale);
  canvas.translate(-512, -512);
  Paint fill(Color c) => Paint()
    ..color = mono ? const Color(0xFFFFFFFF) : c
    ..isAntiAlias = true;
  RRect r(double l, double t, double w, double h, double radius) =>
      RRect.fromLTRBR(l, t, l + w, t + h, Radius.circular(radius));

  // Dumbbell (lower half): bar, then plates from inside out, then end caps.
  const cy = 640.0;
  canvas.drawRRect(r(232, cy - 26, 560, 52, 26), fill(bar));
  for (final mirror in [false, true]) {
    double x(double v, double w) => mirror ? 1024 - v - w : v;
    canvas.drawRRect(r(x(300, 84), cy - 150, 84, 300, 30), fill(plate));
    canvas.drawRRect(r(x(222, 70), cy - 110, 70, 220, 26), fill(plateShade));
    canvas.drawRRect(r(x(176, 40), cy - 34, 40, 68, 16), fill(plate));
  }

  // Rising trend arrow (upper half).
  final line = Paint()
    ..color = mono ? const Color(0xFFFFFFFF) : arrow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 56
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
  final points = [
    const Offset(250, 400),
    const Offset(420, 290),
    const Offset(530, 360),
    const Offset(736, 210),
  ];
  // Arrow head aligned with the last segment; the line stops inside it so
  // its round cap doesn't poke out past the tip.
  final tip = points.last;
  final dir = tip - points[2];
  final angle = math.atan2(dir.dy, dir.dx);
  final unit = dir / dir.distance;
  canvas.drawPath(
    Path()..addPolygon([...points.take(3), tip - unit * 60], false),
    line,
  );
  canvas.save();
  canvas.translate(tip.dx, tip.dy);
  canvas.rotate(angle);
  canvas.drawPath(
    Path()
      ..moveTo(48, 0)
      ..lineTo(-62, -70)
      ..lineTo(-62, 70)
      ..close(),
    Paint()
      ..color = mono ? const Color(0xFFFFFFFF) : arrow
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true,
  );
  canvas.restore();
  canvas.restore();
}

void paintBackground(Canvas canvas, double size) {
  final rect = Rect.fromLTWH(0, 0, size, size);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [background, backgroundDeep],
      ).createShader(rect),
  );
}

Future<void> writePng(
  String path,
  int size,
  void Function(Canvas canvas, double size) paint,
) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder), size.toDouble());
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  test('generate app icons', () async {
    await Directory('assets').create();
    // iOS + legacy Android: full bleed, no transparency.
    await writePng('assets/launcher-ios.png', 1024, (c, s) {
      paintBackground(c, s);
      paintGlyph(c, s, scale: 0.82);
    });
    // Android adaptive foreground: glyph inside the safe-zone circle
    // (diameter 66/108 of the canvas).
    await writePng('assets/launcher.png', 1024, (c, s) {
      paintGlyph(c, s, scale: 0.7);
    });
    // Android 13 themed icon.
    await writePng('assets/launcher_monochrome.png', 1024, (c, s) {
      paintGlyph(c, s, scale: 0.7, mono: true);
    });
    // Native splash: glyph on the splash color.
    await writePng('assets/splash_icon.png', 768, (c, s) {
      paintGlyph(c, s, scale: 0.7);
    });
  });
}
