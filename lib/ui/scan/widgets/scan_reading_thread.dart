import 'package:material_ui/material_ui.dart';

class ScanReadingThread extends StatefulWidget {
  static const double thickness = 1.5;
  static const Duration period = Duration(milliseconds: 1600);
  static const double sweepWidth = 0.32;

  const ScanReadingThread({super.key});

  @override
  State<ScanReadingThread> createState() => _ScanReadingThreadState();
}

class _ScanReadingThreadState extends State<ScanReadingThread>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ScanReadingThread.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = MediaQuery.maybeDisableAnimationsOf(context) != true;
    if (animate && !_controller.isAnimating) _controller.repeat();
    if (!animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: ScanReadingThread.thickness,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ThreadPainter(
                progress: _controller.value,
                color: scheme.primary,
                track: scheme.outlineVariant,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _ThreadPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _ThreadPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = track);

    final width = size.width * ScanReadingThread.sweepWidth;
    final left = (size.width + width) * progress - width;
    final rect = Rect.fromLTWH(left, 0, width, size.height);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color,
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ThreadPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
