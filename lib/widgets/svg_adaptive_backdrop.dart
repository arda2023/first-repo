import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgAdaptivePalette {
  static final Map<String, Future<List<Color>>> _cache = {};

  static Future<List<Color>> fromAsset(String assetName) {
    return _cache.putIfAbsent(assetName, () => _extractFromSvg(assetName));
  }

  static List<Color> fallback() => const <Color>[
    Color(0xFF2E5BFF), // electric blue
    Color(0xFFFFD54A), // warm yellow
    Color(0xFF00C2FF), // cyan
  ];

  static Future<List<Color>> _extractFromSvg(String assetName) async {
    final SvgAssetLoader loader = SvgAssetLoader(assetName);
    final PictureInfo pictureInfo = await vg.loadPicture(loader, null);

    const int targetSize = 96;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    final ui.Size src = pictureInfo.size;
    final double safeW = src.width == 0 ? 1 : src.width;
    final double safeH = src.height == 0 ? 1 : src.height;
    final double scale =
        math.min(targetSize / safeW, targetSize / safeH).clamp(0.0, 1000.0);

    final double scaledW = safeW * scale;
    final double scaledH = safeH * scale;
    final double dx = (targetSize - scaledW) / 2.0;
    final double dy = (targetSize - scaledH) / 2.0;

    canvas.translate(dx, dy);
    canvas.scale(scale, scale);
    canvas.drawPicture(pictureInfo.picture);
    pictureInfo.picture.dispose();

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(targetSize, targetSize);
    picture.dispose();

    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) {
      return fallback();
    }

    final Uint8List bytes = byteData.buffer.asUint8List();
    final Map<int, _ColorStat> stats = <int, _ColorStat>{};

    for (int i = 0; i < bytes.length; i += 4) {
      final int r = bytes[i];
      final int g = bytes[i + 1];
      final int b = bytes[i + 2];
      final int a = bytes[i + 3];

      if (a < 24) continue;

      final int maxC = math.max(r, math.max(g, b));
      final int minC = math.min(r, math.min(g, b));
      if (maxC - minC < 10) continue; // nearly gray

      final double luminance =
          (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
      if (luminance < 0.06 || luminance > 0.98) continue;

      final int qr = (r ~/ 16) * 16;
      final int qg = (g ~/ 16) * 16;
      final int qb = (b ~/ 16) * 16;
      final int key = (qr << 16) | (qg << 8) | qb;
      final Color color = Color(0xFF000000 | key);

      final HSLColor hsl = HSLColor.fromColor(color);
      if (hsl.saturation < 0.18) continue;

      final _ColorStat stat = stats.putIfAbsent(key, () => _ColorStat(color));
      stat.count += 1;
      stat.weight += (a / 255.0) * (0.6 + 0.8 * hsl.saturation);
    }

    if (stats.isEmpty) {
      return fallback();
    }

    final List<_ColorStat> ordered = stats.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));

    final List<Color> result = <Color>[];
    for (final _ColorStat stat in ordered) {
      if (result.isEmpty) {
        result.add(stat.color);
      } else {
        final bool tooClose =
            result.any((c) => _colorDistance(c, stat.color) < 28);
        if (!tooClose) {
          result.add(stat.color);
        }
      }
      if (result.length >= 3) break;
    }

    if (result.isEmpty) return fallback();
    while (result.length < 2) {
      result.add(result.first);
    }
    return result;
  }

  static double _colorDistance(Color a, Color b) {
    final int ar = _channel255(a.r);
    final int ag = _channel255(a.g);
    final int ab = _channel255(a.b);

    final int br = _channel255(b.r);
    final int bg = _channel255(b.g);
    final int bb = _channel255(b.b);

    final int dr = ar - br;
    final int dg = ag - bg;
    final int db = ab - bb;
    return math.sqrt((dr * dr + dg * dg + db * db).toDouble());
  }

  static int _channel255(double v) {
    final int c = (v * 255.0).round();
    if (c < 0) return 0;
    if (c > 255) return 255;
    return c;
  }
}

class _ColorStat {
  _ColorStat(this.color);

  final Color color;
  int count = 0;
  double weight = 0;
}

class SvgAdaptiveBackdrop extends StatelessWidget {
  const SvgAdaptiveBackdrop({
    super.key,
    required this.assetName,
    this.strength = 1.0,
  });

  final String assetName;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Color>>(
      future: SvgAdaptivePalette.fromAsset(assetName),
      builder: (context, snapshot) {
        final List<Color> colors =
            snapshot.data ?? SvgAdaptivePalette.fallback();
        return LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final double s = math.max(w, h);

            final Color c1 = colors[0];
            final Color c2 = colors.length > 1 ? colors[1] : colors[0];
            final Color c3 = colors.length > 2 ? colors[2] : colors[0];

            final Color baseTop = Color.alphaBlend(
              c1.withValues(alpha: 0.10 * strength),
              const Color(0xFF0A0A0A),
            );
            final Color baseBottom = Color.alphaBlend(
              c2.withValues(alpha: 0.06 * strength),
              const Color(0xFF050506),
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [baseTop, baseBottom],
                    ),
                  ),
                ),
                _DiffuseGlow(
                  color: c1,
                  diameter: s * 0.85,
                  blurSigma: 120,
                  opacity: 0.18 * strength,
                  alignment: const Alignment(-0.2, -0.75),
                ),
                _DiffuseGlow(
                  color: c2,
                  diameter: s * 0.75,
                  blurSigma: 120,
                  opacity: 0.14 * strength,
                  alignment: const Alignment(0.65, -0.35),
                ),
                _DiffuseGlow(
                  color: c3,
                  diameter: s * 0.70,
                  blurSigma: 140,
                  opacity: 0.10 * strength,
                  alignment: const Alignment(0.2, 0.75),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class SvgAdaptiveGlow extends StatelessWidget {
  const SvgAdaptiveGlow({
    super.key,
    required this.assetName,
    required this.size,
    required this.child,
    this.strength = 1.0,
  });

  final String assetName;
  final double size;
  final Widget child;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Color>>(
      future: SvgAdaptivePalette.fromAsset(assetName),
      builder: (context, snapshot) {
        final List<Color> colors =
            snapshot.data ?? SvgAdaptivePalette.fallback();
        final Color c1 = colors[0];
        final Color c2 = colors.length > 1 ? colors[1] : colors[0];
        final Color c3 = colors.length > 2 ? colors[2] : colors[0];

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _DiffuseGlow(
                color: c1,
                diameter: size * 1.25,
                blurSigma: 120,
                opacity: 0.16 * strength,
                alignment: const Alignment(-0.2, -0.5),
              ),
              _DiffuseGlow(
                color: c2,
                diameter: size * 1.15,
                blurSigma: 120,
                opacity: 0.12 * strength,
                alignment: const Alignment(0.65, -0.2),
              ),
              _DiffuseGlow(
                color: c3,
                diameter: size * 1.10,
                blurSigma: 140,
                opacity: 0.10 * strength,
                alignment: const Alignment(0.1, 0.55),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _DiffuseGlow extends StatelessWidget {
  const _DiffuseGlow({
    required this.color,
    required this.diameter,
    required this.blurSigma,
    required this.opacity,
    required this.alignment,
  });

  final Color color;
  final double diameter;
  final double blurSigma;
  final double opacity;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: opacity),
                  color.withValues(alpha: opacity * 0.20),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
