import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../widgets/section.dart';

class InputsPage extends StatelessWidget {
  const InputsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
        FrostedSpacing.sp4,
        FrostedSpacing.sp7,
      ),
      children: const <Widget>[
        Section(title: 'Text fields', child: _TextFieldsDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Search', child: _SearchDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Dropdown', child: _DropdownDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Autocomplete', child: _AutocompleteDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Sliders', child: _SlidersDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Date & time', child: _DateTimeDemo()),
      ],
    );
  }
}

class _TextFieldsDemo extends StatefulWidget {
  const _TextFieldsDemo();

  @override
  State<_TextFieldsDemo> createState() => _TextFieldsDemoState();
}

class _TextFieldsDemoState extends State<_TextFieldsDemo> {
  bool _obscure = true;
  bool _glass = false;

  @override
  Widget build(BuildContext context) {
    final Widget fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedTextField(
          label: 'Email',
          hintText: 'ada@glass.dev',
          leadingIcon: Icons.mail_outline,
          glass: _glass,
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedTextField(
          label: 'Display name',
          hintText: 'Ada Lovelace',
          glass: _glass,
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedTextField(
          label: 'Password',
          obscureText: _obscure,
          errorText: 'Au moins 8 caractères',
          glass: _glass,
          trailingIcon:
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          onTrailingTap: () => setState(() => _obscure = !_obscure),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedTextField(
          label: 'Notes',
          hintText: 'Multiline…',
          maxLines: 3,
          helperText: 'Optionnel',
          glass: _glass,
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const FrostedTextField(label: 'Disabled', enabled: false),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('Glass'),
            const SizedBox(width: FrostedSpacing.sp2),
            FrostedSwitch(
              value: _glass,
              onChanged: (bool v) => setState(() => _glass = v),
            ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        if (_glass)
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF7C5CFF), Color(0xFFFF6FA5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(FrostedRadius.lg)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(FrostedSpacing.sp4),
              child: fields,
            ),
          )
        else
          fields,
      ],
    );
  }
}

class _SearchDemo extends StatelessWidget {
  const _SearchDemo();

  @override
  Widget build(BuildContext context) {
    return const FrostedSearchField(hintText: 'Rechercher une transaction');
  }
}

class _DropdownDemo extends StatefulWidget {
  const _DropdownDemo();

  @override
  State<_DropdownDemo> createState() => _DropdownDemoState();
}

class _DropdownDemoState extends State<_DropdownDemo> {
  String? _value = 'monthly';

  @override
  Widget build(BuildContext context) {
    return FrostedDropdown<String>(
      label: 'Fréquence',
      value: _value,
      onChanged: (String v) => setState(() => _value = v),
      items: const <FrostedDropdownItem<String>>[
        FrostedDropdownItem<String>(
          value: 'monthly',
          label: 'Mensuel',
          icon: Icons.calendar_month_outlined,
        ),
        FrostedDropdownItem<String>(
          value: 'annual',
          label: 'Annuel',
          icon: Icons.event_outlined,
        ),
        FrostedDropdownItem<String>(
          value: 'oneTime',
          label: 'Ponctuel',
          icon: Icons.bolt_outlined,
        ),
      ],
    );
  }
}

class _AutocompleteDemo extends StatelessWidget {
  const _AutocompleteDemo();

  static const List<String> _cities = <String>[
    'Paris',
    'Marseille',
    'Lyon',
    'Toulouse',
    'Nice',
    'Nantes',
    'Strasbourg',
    'Montpellier',
    'Bordeaux',
    'Lille',
  ];

  @override
  Widget build(BuildContext context) {
    return FrostedAutocomplete(
      label: 'Ville',
      hintText: 'Commencez à taper…',
      leadingIcon: Icons.location_city_outlined,
      options: _cities,
      onSelected: (_) {},
    );
  }
}

class _SlidersDemo extends StatefulWidget {
  const _SlidersDemo();

  @override
  State<_SlidersDemo> createState() => _SlidersDemoState();
}

class _SlidersDemoState extends State<_SlidersDemo> {
  double _single = 0.4;
  double _stepped = 3;
  RangeValues _range = const RangeValues(200, 800);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedSlider(
          value: _single,
          onChanged: (double v) => setState(() => _single = v),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedSlider(
          value: _stepped,
          min: 0,
          max: 10,
          divisions: 10,
          label: _stepped.round().toString(),
          onChanged: (double v) => setState(() => _stepped = v),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedRangeSlider(
          values: _range,
          min: 0,
          max: 1000,
          divisions: 20,
          labels: RangeLabels(
            _range.start.round().toString(),
            _range.end.round().toString(),
          ),
          onChanged: (RangeValues v) => setState(() => _range = v),
        ),
      ],
    );
  }
}

class _DateTimeDemo extends StatefulWidget {
  const _DateTimeDemo();

  @override
  State<_DateTimeDemo> createState() => _DateTimeDemoState();
}

class _DateTimeDemoState extends State<_DateTimeDemo> {
  DateTime? _date;
  TimeOfDay? _time;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedDateField(
          label: 'Date',
          hintText: 'Choisir une date',
          value: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          format: _formatDate,
          onChanged: (DateTime d) => setState(() => _date = d),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedTimeField(
          label: 'Heure',
          hintText: 'Choisir une heure',
          value: _time,
          onChanged: (TimeOfDay t) => setState(() => _time = t),
        ),
      ],
    );
  }
}
