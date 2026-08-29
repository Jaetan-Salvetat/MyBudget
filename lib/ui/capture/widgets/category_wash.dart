import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

/// The category colour washing the whole ground for half a second as the
/// transaction lands. One colour crossing the screen says more than a badge
/// in a corner, and it costs a gradient — no extra backdrop filter.
class CategoryWash extends ConsumerStatefulWidget {
  static const Duration rise = Duration(milliseconds: 520);
  static const Duration hold = Duration(milliseconds: 200);
  static const double peakOpacity = 0.42;

  const CategoryWash({super.key});

  @override
  ConsumerState<CategoryWash> createState() => _CategoryWashState();
}

class _CategoryWashState extends ConsumerState<CategoryWash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CategoryWash.rise,
    reverseDuration: CategoryWash.rise,
  );

  Color? _color;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Only a new arrival washes the screen : an expiry or an undo shortens the
  /// list too, and neither is worth a colour.
  void _onSubmissions(
    List<QuickAddSubmission>? previous,
    List<QuickAddSubmission> next,
  ) {
    if (next.length <= (previous?.length ?? 0)) return;

    final display = ref
        .read(categoryDisplayResolverProvider)
        .value
        ?.resolve(next.last.categorySlug);
    if (display == null) return;

    setState(() => _color = Color(display.color));
    _controller.forward(from: 0).then((_) {
      if (!mounted) return;
      Future<void>.delayed(CategoryWash.hold, () {
        if (mounted) _controller.reverse();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(quickAddRecentSubmissionsProvider, _onSubmissions);

    final color = _color;
    if (color == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 0.56),
              radius: 0.8,
              colors: [
                color.withValues(
                  alpha: CategoryWash.peakOpacity * _controller.value,
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
