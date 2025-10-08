import 'package:flutter/material.dart';

class BeforeAfter extends StatefulWidget {
  final Widget before;
  final Widget after;
  const BeforeAfter({super.key, required this.before, required this.after});

  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter> {
  double _ratio = 1;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        return Stack(
          children: [
            Positioned.fill(child: widget.before),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: _ratio,
                child: SizedBox(width: w, child: widget.after),
              ),
            ),
            Positioned(
              left: w * _ratio - 12,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate:
                    (d) => setState(
                      () => _ratio = (_ratio + d.delta.dx / w).clamp(0.0, 1.0),
                    ),
                child: Container(width: 24, color: Colors.black26),
              ),
            ),
          ],
        );
      },
    );
  }
}
