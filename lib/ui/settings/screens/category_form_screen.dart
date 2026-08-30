import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';

sealed class CategoryFormResult {
  const CategoryFormResult();
}

final class CategoryReset extends CategoryFormResult {
  const CategoryReset();
}

final class CategoryCustomisation extends CategoryFormResult {
  final String? name;
  final String? icon;
  final int? color;

  const CategoryCustomisation({this.name, this.icon, this.color});
}

class CategoryFormScreen extends StatefulWidget {
  final CategoryDisplay initial;
  final CategoryDisplay defaults;

  const CategoryFormScreen({
    required this.initial,
    required this.defaults,
    super.key,
  });

  static Future<CategoryFormResult?> push({
    required BuildContext context,
    required CategoryDisplay initial,
    required CategoryDisplay defaults,
  }) {
    return Navigator.push<CategoryFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(initial: initial, defaults: defaults),
      ),
    );
  }

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initial.label,
  );
  late int _selectedColor = widget.initial.color;
  late String _selectedIcon = widget.initial.icon;

  bool get _isGroup => widget.initial.isGroup;

  bool get _isCustomised =>
      widget.initial.label != widget.defaults.label ||
      widget.initial.icon != widget.defaults.icon ||
      widget.initial.color != widget.defaults.color;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: widget.defaults.label,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(child: _fields(theme)),
          _actions(context),
        ],
      ),
    );
  }

  Widget _fields(ThemeData theme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
        FrostedSpacing.sp4,
        FrostedSpacing.sp4,
      ),
      children: [
        Center(
          child: CategoryIcon(
            icon: CategoryDefaults.resolveIcon(_selectedIcon),
            color: Color(_selectedColor),
            size: CategoryIconSize.md,
          ),
        ),
        const SizedBox(height: 20),
        FrostedTextField(
          controller: _nameController,
          label: 'Nom de la catégorie',
          hintText: widget.defaults.label,
          leadingIcon: Symbols.label_rounded,
        ),
        const SizedBox(height: 6),
        Text(
          'Laisser vide pour revenir à « ${widget.defaults.label} »',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (_isGroup) ...[
          _Label('Couleur'),
          const SizedBox(height: 10),
          _colorPicker(theme),
          const SizedBox(height: 24),
        ] else ...[
          Text(
            'La couleur est celle du groupe « ${widget.initial.groupLabel} ».',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
        ],
        _Label('Icône'),
        const SizedBox(height: 10),
        _iconPicker(theme),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        0,
        FrostedSpacing.sp4,
        MediaQuery.of(context).padding.bottom + FrostedSpacing.sp4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrostedButton.filled(label: 'Enregistrer', onPressed: _submit),
          if (_isCustomised)
            FrostedButton.text(
              label: 'Réinitialiser',
              onPressed: () => Navigator.pop(context, const CategoryReset()),
            ),
        ],
      ),
    );
  }

  Widget _colorPicker(ThemeData theme) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in CategoryDefaults.colors)
          GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
                border: _selectedColor == color
                    ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                    : null,
              ),
              child: _selectedColor == color
                  ? const Icon(
                      Symbols.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _iconPicker(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in CategoryDefaults.icons.entries)
          GestureDetector(
            onTap: () => setState(() => _selectedIcon = entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _selectedIcon == entry.key
                    ? Color(_selectedColor).withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(10),
                border: _selectedIcon == entry.key
                    ? Border.all(color: Color(_selectedColor), width: 2)
                    : null,
              ),
              child: Icon(
                entry.value,
                color: _selectedIcon == entry.key
                    ? Color(_selectedColor)
                    : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();

    Navigator.pop(
      context,
      CategoryCustomisation(
        name: name.isEmpty || name == widget.defaults.label ? null : name,
        icon: _selectedIcon == widget.defaults.icon ? null : _selectedIcon,
        color: !_isGroup || _selectedColor == widget.defaults.color
            ? null
            : _selectedColor,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
