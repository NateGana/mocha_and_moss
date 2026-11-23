import 'package:flutter/material.dart';

import '../models/models.dart';

/// Built-in illustration used whenever a product has no photo (or its photo
/// fails to load), so the menu never shows a broken image.
class DrinkArt extends StatelessWidget {
  const DrinkArt({super.key, required this.artKey});
  final String artKey;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArtPainter(artKey),
      size: Size.infinite,
    );
  }
}

/// Shows a product's photo when it has one, otherwise the illustration.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.radius = BorderRadius.zero,
  });

  final Product product;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl.trim();
    final art = DrinkArt(artKey: product.artKey);
    Widget child = art;
    if (url.startsWith('http')) {
      child = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => art,
        loadingBuilder: (c, w, p) => p == null ? w : art,
      );
    } else if (url.startsWith('assets/')) {
      child = Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => art,
      );
    }
    return ClipRRect(borderRadius: radius, child: SizedBox.expand(child: child));
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.artKey);
  final String artKey;

  static const _cream = Color(0xFFF1E4D5);
  static const _glassKeys = {
    'mocha_iced',
    'frappe',
    'matcha_iced',
    'matcha_strawberry',
    'matcha_frappe',
  };

  bool get _isMatcha => artKey.startsWith('matcha');

  Color get _liquid {
    switch (artKey) {
      case 'mocha_dark':
        return const Color(0xFF3B2116);
      case 'mocha_white':
        return const Color(0xFFE2C9A0);
      case 'mocha_spanish':
        return const Color(0xFF8A5A3B);
      case 'mocha_caramel':
        return const Color(0xFFB8743A);
      case 'mocha_hazelnut':
        return const Color(0xFF7A4B2E);
      case 'mocha_vanilla':
        return const Color(0xFF9A6B49);
      case 'mocha_iced':
        return const Color(0xFF5A3523);
      case 'frappe':
        return const Color(0xFF8B5A3C);
      case 'matcha':
        return const Color(0xFF8FA66F);
      case 'matcha_iced':
        return const Color(0xFF9DB57E);
      case 'matcha_strawberry':
        return const Color(0xFFE59AA8);
      case 'matcha_frappe':
        return const Color(0xFFA6BB86);
      case 'coffee':
        return const Color(0xFF2E1A12);
      case 'latte':
        return const Color(0xFFC49A6C);
      case 'chocolate':
        return const Color(0xFF5B3A29);
    }
    return const Color(0xFF5A3523); // classic mocha
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgCenter = _isMatcha ? const Color(0xFF34402E) : const Color(0xFF3B281C);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [bgCenter, const Color(0xFF1E140F)],
          radius: 0.9,
        ).createShader(Offset.zero & size),
    );
    final s = size.shortestSide;
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    switch (artKey) {
      case 'brownie':
        _brownie(canvas, s);
        return;
      case 'cookie':
        _cookie(canvas, s);
        return;
      case 'croissant':
        _croissant(canvas, s);
        return;
      case 'roll':
        _roll(canvas, s);
        return;
      case 'cake':
        _cake(canvas, s, mocha: true);
        return;
      case 'cheesecake':
        _cake(canvas, s, mocha: false);
        return;
      case 'bundle':
        _bundle(canvas, s);
        return;
    }
    if (_glassKeys.contains(artKey)) {
      _glass(canvas, s);
    } else {
      _mug(canvas, s);
    }
  }

  Paint _fill(Color c) => Paint()..color = c;

  void _mug(Canvas canvas, double s, {double dx = 0, double scale = 1}) {
    canvas.save();
    canvas.translate(dx, 0);
    canvas.scale(scale);
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..color = _cream;
    canvas.drawArc(
      Rect.fromLTWH(s * .64, s * .48, s * .2, s * .2),
      -1.5708,
      3.1416,
      false,
      handle,
    );
    canvas.drawOval(
      Rect.fromLTWH(s * .18, s * .72, s * .64, s * .12),
      _fill(const Color(0xFFD9C7B0)),
    );
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(s * .26, s * .38, s * .46, s * .40),
      bottomLeft: Radius.circular(s * .14),
      bottomRight: Radius.circular(s * .14),
    );
    canvas.drawRRect(body, _fill(_cream));
    canvas.drawOval(Rect.fromLTWH(s * .26, s * .34, s * .46, s * .10), _fill(const Color(0xFFE9D9C4)));
    canvas.drawOval(Rect.fromLTWH(s * .29, s * .355, s * .40, s * .07), _fill(_liquid));
    if (artKey == 'mocha_vanilla') {
      canvas.drawOval(Rect.fromLTWH(s * .36, s * .345, s * .26, s * .06), _fill(_cream));
    }
    final steam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.28);
    for (final x in [.40, .50, .60]) {
      final p = Path()
        ..moveTo(s * x, s * .30)
        ..cubicTo(s * (x - .04), s * .24, s * (x + .04), s * .20, s * x, s * .13);
      canvas.drawPath(p, steam);
    }
    canvas.restore();
  }

  void _glass(Canvas canvas, double s, {double dx = 0, double scale = 1}) {
    canvas.save();
    canvas.translate(dx, 0);
    canvas.scale(scale);
    final glass = Path()
      ..moveTo(s * .30, s * .26)
      ..lineTo(s * .70, s * .26)
      ..lineTo(s * .64, s * .82)
      ..lineTo(s * .36, s * .82)
      ..close();
    canvas.save();
    canvas.clipPath(glass);
    final milk = artKey == 'matcha_strawberry'
        ? const Color(0xFFC8D6A8)
        : (_isMatcha ? const Color(0xFFE9EBD6) : const Color(0xFFE8D5BC));
    canvas.drawRect(Rect.fromLTWH(0, s * .26, s, s * .56), _fill(milk));
    canvas.drawRect(Rect.fromLTWH(0, s * .52, s, s * .30), _fill(_liquid));
    final ice = _fill(Colors.white.withValues(alpha: 0.28));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s * .35, s * .34, s * .12, s * .10), Radius.circular(s * .015)), ice);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s * .50, s * .40, s * .12, s * .10), Radius.circular(s * .015)), ice);
    canvas.restore();
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = Colors.white.withValues(alpha: 0.45),
    );
    // Straw
    canvas.drawLine(
      Offset(s * .52, s * .12),
      Offset(s * .55, s * .70),
      Paint()
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round
        ..color = _isMatcha ? const Color(0xFFB7C99A) : const Color(0xFFDDAA45),
    );
    if (artKey.endsWith('frappe')) {
      // Whipped cream dome with a drizzle on blended drinks.
      canvas.drawOval(Rect.fromLTWH(s * .30, s * .17, s * .40, s * .16), _fill(_cream));
      canvas.drawOval(Rect.fromLTWH(s * .36, s * .12, s * .28, s * .14), _fill(Colors.white.withValues(alpha: 0.9)));
      canvas.drawLine(
        Offset(s * .40, s * .20),
        Offset(s * .60, s * .22),
        Paint()
          ..strokeWidth = s * 0.016
          ..strokeCap = StrokeCap.round
          ..color = _isMatcha ? const Color(0xFF6F8A55) : const Color(0xFF4A2A1B),
      );
    }
    canvas.restore();
  }

  void _brownie(Canvas canvas, double s) {
    canvas.drawOval(Rect.fromLTWH(s * .16, s * .62, s * .68, s * .16), _fill(const Color(0xFFD9C7B0)));
    for (final y in [.50, .38]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s * .26, s * y, s * .48, s * .16), Radius.circular(s * .02)),
        _fill(const Color(0xFF3D2216)),
      );
    }
    final crack = Paint()
      ..color = const Color(0xFF6B4230)
      ..strokeWidth = s * .012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * .34, s * .44), Offset(s * .46, s * .41), crack);
    canvas.drawLine(Offset(s * .54, s * .43), Offset(s * .66, s * .45), crack);
  }

  void _cookie(Canvas canvas, double s) {
    canvas.drawOval(Rect.fromLTWH(s * .14, s * .60, s * .72, s * .18), _fill(const Color(0xFFD9C7B0)));
    canvas.drawCircle(Offset(s * .5, s * .48), s * .24, _fill(const Color(0xFFC8924F)));
    final chip = _fill(const Color(0xFF3D2216));
    for (final o in const [Offset(.42, .40), Offset(.58, .44), Offset(.47, .55), Offset(.62, .56), Offset(.38, .50)]) {
      canvas.drawCircle(Offset(s * o.dx, s * o.dy), s * .03, chip);
    }
  }

  void _croissant(Canvas canvas, double s) {
    canvas.drawOval(Rect.fromLTWH(s * .14, s * .64, s * .72, s * .14), _fill(const Color(0xFFD9C7B0)));
    final gold = _fill(const Color(0xFFD59A4A));
    final deep = _fill(const Color(0xFFB87A34));
    final parts = [
      [.50, .52, .16, .26, 0.0, true],
      [.38, .54, .13, .22, -0.5, false],
      [.62, .54, .13, .22, 0.5, false],
      [.28, .58, .10, .17, -0.9, true],
      [.72, .58, .10, .17, 0.9, true],
    ];
    for (final p in parts) {
      canvas.save();
      canvas.translate(s * (p[0] as double), s * (p[1] as double));
      canvas.rotate(p[4] as double);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * (p[2] as double) * 2, height: s * (p[3] as double)),
        (p[5] as bool) ? deep : gold,
      );
      canvas.restore();
    }
  }

  void _roll(Canvas canvas, double s) {
    canvas.drawOval(Rect.fromLTWH(s * .16, s * .64, s * .68, s * .14), _fill(const Color(0xFFD9C7B0)));
    canvas.drawCircle(Offset(s * .5, s * .5), s * .24, _fill(const Color(0xFFD9A25A)));
    canvas.drawCircle(Offset(s * .5, s * .5), s * .20, _fill(const Color(0xFFF1E4D5).withValues(alpha: 0.55)));
    final swirl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .025
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8A4E27);
    canvas.drawArc(Rect.fromCircle(center: Offset(s * .5, s * .5), radius: s * .15), 0.3, 4.6, false, swirl);
    canvas.drawArc(Rect.fromCircle(center: Offset(s * .5, s * .5), radius: s * .08), 0.8, 4.2, false, swirl);
  }

  void _cake(Canvas canvas, double s, {required bool mocha}) {
    canvas.drawOval(Rect.fromLTWH(s * .14, s * .66, s * .72, s * .14), _fill(const Color(0xFFD9C7B0)));
    final body = Path()
      ..moveTo(s * .24, s * .66)
      ..lineTo(s * .24, s * .42)
      ..lineTo(s * .76, s * .34)
      ..lineTo(s * .76, s * .66)
      ..close();
    canvas.drawPath(body, _fill(mocha ? const Color(0xFF4A2A1B) : const Color(0xFFF3E3BE)));
    final layer = _fill(mocha ? const Color(0xFFC9A27A) : const Color(0xFFC8924F));
    if (mocha) {
      canvas.drawRect(Rect.fromLTWH(s * .24, s * .50, s * .52, s * .035), layer);
    } else {
      canvas.drawRect(Rect.fromLTWH(s * .24, s * .60, s * .52, s * .06), layer);
    }
    canvas.drawCircle(Offset(s * .62, s * .38), s * .03, _fill(mocha ? const Color(0xFFDDAA45) : const Color(0xFFD35C6B)));
  }

  void _bundle(Canvas canvas, double s) {
    _mug(canvas, s, dx: -s * .12, scale: 0.85);
    canvas.drawOval(Rect.fromLTWH(s * .52, s * .66, s * .40, s * .08), _fill(const Color(0xFFD9C7B0)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * .58, s * .52, s * .28, s * .17), Radius.circular(s * .02)),
      _fill(const Color(0xFF3D2216)),
    );
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.artKey != artKey;
}
