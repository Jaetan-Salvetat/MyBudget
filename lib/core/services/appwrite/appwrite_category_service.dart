import 'package:appwrite/appwrite.dart';
import 'package:mybudget/core/services/appwrite/appwrite_client_service.dart';
import 'package:mybudget/data/models/category_model.dart';

class AppwriteCategoryService {
  static final Databases _databases = Databases(AppwriteClientService.instance);
  
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.categoriesCollection
      );
      
      return result.documents.map((doc) => 
        CategoryModel.fromJson(doc.data)
      ).toList();
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<CategoryModel> getCategory(String categoryId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.categoriesCollection,
        documentId: categoryId
      );
      
      return CategoryModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final account = Account(AppwriteClientService.instance);
      final authUser = await account.get();
      final userId = authUser.$id;
      
      final data = category.toJson();
      data['user_id'] = userId;
      
      final document = await _databases.createDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.categoriesCollection,
        documentId: ID.unique(),
        data: data,
        permissions: []
      );
      
      return CategoryModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final account = Account(AppwriteClientService.instance);
      final authUser = await account.get();
      final userId = authUser.$id;
      
      final data = category.toJson();
      data['user_id'] = userId;
      
      final document = await _databases.updateDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.categoriesCollection,
        documentId: category.id,
        data: data,
        permissions: []
      );
      
      return CategoryModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<void> deleteCategory(String categoryId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.categoriesCollection,
        documentId: categoryId
      );
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Exception _handleDatabaseException(dynamic e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 404:
          return Exception('Catégorie non trouvée');
        case 409:
          return Exception('Une catégorie avec ce nom existe déjà');
        default:
          return Exception('Erreur de base de données: ${e.message}');
      }
    }
    return Exception('Erreur inconnue: $e');
  }
}
