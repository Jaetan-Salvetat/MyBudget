import 'package:appwrite/appwrite.dart';
import 'package:mybudget/core/services/appwrite/appwrite_client_service.dart';
import 'package:mybudget/data/models/expense_model.dart';

class AppwriteExpenseService {
  static final Databases _databases = Databases(AppwriteClientService.instance);
  
  static Future<List<ExpenseModel>> getExpenses() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.expensesCollection
      );
      
      return result.documents.map((doc) => 
        ExpenseModel.fromJson(doc.data)
      ).toList();
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<List<ExpenseModel>> getExpensesByAccount(String accountId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.expensesCollection,
        queries: [
          Query.equal('accountId', accountId)
        ]
      );
      
      return result.documents.map((doc) => 
        ExpenseModel.fromJson(doc.data)
      ).toList();
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<ExpenseModel> getExpense(String expenseId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.expensesCollection,
        documentId: expenseId
      );
      
      return ExpenseModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      final account = Account(AppwriteClientService.instance);
      final authUser = await account.get();
      final userId = authUser.$id;
      
      final data = expense.toJson();
      data['user_id'] = userId;
      
      final document = await _databases.createDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.expensesCollection,
        documentId: ID.unique(),
        data: data,
        permissions: []
      );
      
      return ExpenseModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      final account = Account(AppwriteClientService.instance);
      final authUser = await account.get();
      final userId = authUser.$id;
      
      final data = expense.toJson();
      data['user_id'] = userId;
      
      final document = await _databases.updateDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.expensesCollection,
        documentId: expense.id,
        data: data,
        permissions: []
      );
      
      return ExpenseModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<void> deleteExpense(String expenseId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.expensesCollection,
        documentId: expenseId
      );
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Exception _handleDatabaseException(dynamic e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 404:
          return Exception('Dépense non trouvée');
        default:
          return Exception('Erreur de base de données: ${e.message}');
      }
    }
    return Exception('Erreur inconnue: $e');
  }
}
