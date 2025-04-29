import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/config/appwrite_constants.dart';
import 'package:mybudget/data/datasources/appwrite_client.dart';

final expenseDataSourceProvider = Provider<ExpenseDataSource>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return ExpenseDataSource(appwriteClient);
});

class ExpenseDataSource {
  final AppwriteClient _appwriteClient;

  ExpenseDataSource(this._appwriteClient);

  Future<Document> createExpense(String name, double amount, String category, DateTime date, String frequency, String accountId) async {
    final userId = await _appwriteClient.getUserId();
    
    final expense = await _appwriteClient.databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.expensesCollection,
      documentId: ID.unique(),
      data: {
        'name': name,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'frequency': frequency,
        'accountId': accountId,
        'user_id': userId,
      },
      permissions: [
        Permission.read(Role.user(userId!)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
    
    return expense;
  }

  Future<List<Document>> getExpenses() async {
    final userId = await _appwriteClient.getUserId();
    
    final expenses = await _appwriteClient.databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.expensesCollection,
      queries: [
        Query.equal('user_id', userId!)
      ],
    );
    
    return expenses.documents;
  }

  Future<List<Document>> getExpensesByAccount(String accountId) async {
    final userId = await _appwriteClient.getUserId();
    
    final expenses = await _appwriteClient.databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.expensesCollection,
      queries: [
        Query.equal('user_id', userId!),
        Query.equal('accountId', accountId)
      ],
    );
    
    return expenses.documents;
  }

  Future<Document> getExpense(String expenseId) async {
    final document = await _appwriteClient.databases.getDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.expensesCollection,
      documentId: expenseId,
    );
    
    return document;
  }

  Future<Document> updateExpense(String expenseId, {String? name, double? amount, String? category, DateTime? date, String? frequency, String? accountId}) async {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (amount != null) data['amount'] = amount;
    if (category != null) data['category'] = category;
    if (date != null) data['date'] = date.toIso8601String();
    if (frequency != null) data['frequency'] = frequency;
    if (accountId != null) data['accountId'] = accountId;
    
    final document = await _appwriteClient.databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.expensesCollection,
      documentId: expenseId,
      data: data,
    );
    
    return document;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _appwriteClient.databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.expensesCollection,
      documentId: expenseId,
    );
  }
}
