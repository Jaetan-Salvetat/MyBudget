import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/common/widgets/detail/detail_row.dart';
import 'package:mybudget/ui/common/widgets/detail/detail_section.dart';

class DetailInfoCard extends StatelessWidget {
  final String title;
  final List<DetailRow> rows;

  const DetailInfoCard({
    required this.title,
    required this.rows,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DetailSection(title: title, child: Column(children: rows));
  }
}
