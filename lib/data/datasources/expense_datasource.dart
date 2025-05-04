import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/data/models/expense_model.dart';

class ExpenseDatasource {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final result = await _appwriteService.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.expensesCollectionId,
        queries: [Query.orderDesc('\$createdAt')],
      );

      return result.documents.map((doc) {
        return ExpenseModel.fromJson(doc.data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get expenses: ${e.toString()}');
    }
  }

  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      final result = await _appwriteService.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.expensesCollectionId,
        documentId: ID.unique(),
        data: expense.toJson(),
        permissions: []
      );

      return ExpenseModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Failed to create expense: ${e.toString()}');
    }
  }

  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      final result = await _appwriteService.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.expensesCollectionId,
        documentId: expense.id,
        data: expense.toJson(),
        permissions: []
      );

      return ExpenseModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Failed to update expense: ${e.toString()}');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _appwriteService.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.expensesCollectionId,
        documentId: id,
      );
    } catch (e) {
      throw Exception('Failed to delete expense: ${e.toString()}');
    }
  }
}
