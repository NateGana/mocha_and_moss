import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../theme/app_theme.dart';

/// Minimal mocha cup with a small leaf for the matcha side of the menu.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.color, this.leafColor});

  final double size;
  final Color? color;
  final Color? leafColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkPainter(color ?? colors.gold, leafColor ?? colors.matcha),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.line, this.leaf);
  final Color line;
  final Color leaf;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.shortestSide;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = line;

    final cup = Path()
      ..moveTo(w * .22, w * .46)
      ..lineTo(w * .74, w * .46)
      ..lineTo(w * .69, w * .72)
      ..quadraticBezierTo(w * .68, w * .78, w * .62, w * .78)
      ..lineTo(w * .34, w * .78)
      ..quadraticBezierTo(w * .28, w * .78, w * .27, w * .72)
      ..close();
    canvas.drawPath(cup, stroke);
    canvas.drawArc(
      Rect.fromLTWH(w * .66, w * .50, w * .2, w * .18),
      -1.5708,
      3.1416,
      false,
      stroke,
    );
    canvas.drawLine(Offset(w * .16, w * .87), Offset(w * .80, w * .87), stroke);
    // A thin line inside the cup suggests the mocha's surface.
    canvas.drawLine(Offset(w * .31, w * .55), Offset(w * .65, w * .55), stroke);

    final leafPath = Path()
      ..moveTo(w * .46, w * .38)
      ..quadraticBezierTo(w * .38, w * .17, w * .63, w * .09)
      ..quadraticBezierTo(w * .72, w * .31, w * .46, w * .38)
      ..close();
    canvas.drawPath(leafPath, Paint()..color = leaf);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.line != line || old.leaf != leaf;
}

/// Mark + wordmark + optional tagline. Reads the café name from settings so
/// renaming the café in the admin screen updates it everywhere.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.markSize = 34,
    this.nameSize = 24,
    this.showTagline = true,
  });

  final double markSize;
  final double nameSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: markSize),
            const SizedBox(height: 8),
            Text(
              store.settings.name,
              textAlign: TextAlign.center,
              style: AppFonts.serif(
                fontSize: nameSize,
                color: colors.latte,
                letterSpacing: 1.5,
              ),
            ),
            if (showTagline) ...[
              const SizedBox(height: 4),
              Text(
                store.settings.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.oat, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}
