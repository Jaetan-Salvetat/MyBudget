import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/transfer_model.dart';

class Transfer {
  final TransferModel _model;

  Transfer(this._model);

  int get id => _model.id;
  String get name => _model.name;
  double get amount => _model.amount;
  int get fromAccountId => _model.fromAccountId;
  int get toAccountId => _model.toAccountId;
  DateTime get date => _model.date;
  Frequency get frequency => _model.frequencyEnum;

  TransferModel get model => _model;

  double get monthlyAmount {
    switch (frequency) {
      case Frequency.annual:
        return amount / 12;
      case Frequency.oneTime:
        return 0.0;
      case Frequency.monthly:
        return amount;
    }
  }

  bool isOutgoingFrom(int accountId) => fromAccountId == accountId;

  bool isIncomingTo(int accountId) => toAccountId == accountId;

  static Transfer fromModel(TransferModel model) {
    return Transfer(model);
  }
}
