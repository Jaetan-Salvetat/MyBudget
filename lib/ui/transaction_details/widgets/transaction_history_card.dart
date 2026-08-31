import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/transaction_rule_version.dart';
import 'package:mybudget/ui/common/widgets/detail/detail_info_card.dart';
import 'package:mybudget/ui/common/widgets/detail/detail_row.dart';

const String _title = 'Historique du montant';

class TransactionHistoryCard extends StatelessWidget {
  final List<TransactionRuleVersion> versions;

  const TransactionHistoryCard({required this.versions, super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateFormatter = DateFormat('dd/MM/yy');

    return DetailInfoCard(
      title: _title,
      rows: [
        for (var index = 0; index < versions.length; index++)
          DetailRow(
            label: _periodOf(versions[index], dateFormatter),
            value: formatter.format(versions[index].amount),
            showDivider: index < versions.length - 1,
          ),
      ],
    );
  }

  String _periodOf(TransactionRuleVersion version, DateFormat formatter) {
    final start = formatter.format(version.startDate);
    final end = version.endDate;
    return end == null
        ? 'Depuis le $start'
        : 'Du $start au ${formatter.format(end)}';
  }
}
