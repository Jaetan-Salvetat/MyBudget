import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/data/models/revenue_model.dart';
import 'package:path_provider/path_provider.dart';

final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

class HiveService {
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
      
      Hive.registerAdapter(AccountModelAdapter());
      Hive.registerAdapter(ExpenseModelAdapter());
      Hive.registerAdapter(RevenueModelAdapter());
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Hive: $e');
      rethrow;
    }
  }
  
  void registerAdapter<T>(TypeAdapter<T> adapter) {
    Hive.registerAdapter(adapter);
  }

  Future<Box<T>> openBox<T>(String boxName) async {
    if (!_isInitialized) await init();
    return await Hive.openBox<T>(boxName);
  }
}
