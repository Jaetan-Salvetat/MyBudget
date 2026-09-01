abstract final class ReceiptSchema {
  static const String name = 'receipt';

  static const String storeKey = 'store';
  static const String dateKey = 'date';
  static const String totalKey = 'total';
  static const String itemsKey = 'items';
  static const String itemNameKey = 'name';
  static const String itemAmountKey = 'amount';
  static const String itemDiscountKey = 'discount';

  static const int maxReceiptCharacters = 4000;

  static const double checksumTolerance = 0.005;
}
