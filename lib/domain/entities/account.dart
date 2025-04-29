abstract class Account {
  final String id;
  final String name;
  final String bank;

  Account({
    required this.id,
    required this.name,
    required this.bank,
  });

  Map<String, dynamic> toJson();
}
