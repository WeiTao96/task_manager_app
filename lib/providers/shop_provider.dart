import 'package:flutter/material.dart';
import '../models/shop_item.dart';
import '../services/task_service.dart';

class ShopProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  
  List<ShopItem> _items = [];
  List<PurchaseRecord> _purchaseHistory = [];
  List<ShopItem> _inventory = []; // 用户已拥有的物品
  Map<String, DateTime> _activeBoosts = {}; // 当前生效的增益
  int _userGold = 0;
  bool _isLoading = false; // 防止重复加载

  List<ShopItem> get items => _items;
  List<PurchaseRecord> get purchaseHistory => _purchaseHistory;
  List<ShopItem> get inventory => _inventory;
  Map<String, DateTime> get activeBoosts => _activeBoosts;
  int get userGold => _userGold;
  bool get isLoading => _isLoading;
  
  // 获取可用的商品（排除已过期的限时商品）
  List<ShopItem> get availableItems {
    final now = DateTime.now();
    final available = _items.where((item) {
      if (item.isLimited && item.limitedUntil != null) {
        return now.isBefore(item.limitedUntil!);
      }
      return true;
    }).toList();
    return available;
  }
  
  // 初始化商店
  Future<void> initializeShop() async {
    if (_isLoading) {
      print('Shop already initializing, skipping...');
      return;
    }
    
    _isLoading = true;
    try {
      // 从数据库加载用户创建的商品
      await _loadShopItems();
      
      // 从数据库加载用户购买记录
      await _loadPurchaseHistory();
      await _loadInventory();
      await _loadActiveBoosts();
      
      notifyListeners();
    } catch (e) {
      print('Error initializing shop: $e');
    } finally {
      _isLoading = false;
    }
  }

  // 加载商店商品
  Future<void> _loadShopItems() async {
    try {
      final itemMaps = await _taskService.getShopItems();
      _items = itemMaps.map((map) => ShopItem.fromMap(map)).toList();
      print('Loaded ${_items.length} shop items from database');
    } catch (e) {
      print('Error loading shop items: $e');
      _items = [];
    }
  }
  
  // 加载购买历史
  Future<void> _loadPurchaseHistory() async {
    try {
      final records = await _taskService.getPurchaseHistory();
      _purchaseHistory = records.map((map) => PurchaseRecord.fromMap(map)).toList();
    } catch (e) {
      print('Error loading purchase history: $e');
    }
  }
  
  // 加载用户库存
  Future<void> _loadInventory() async {
    try {
      final items = await _taskService.getUserInventory();
      _inventory = items.map((map) => ShopItem.fromMap(map)).toList();
    } catch (e) {
      print('Error loading inventory: $e');
    }
  }
  
  // 加载当前生效的增益
  Future<void> _loadActiveBoosts() async {
    try {
      final boosts = await _taskService.getActiveBoosts();
      _activeBoosts = Map<String, DateTime>.from(boosts);
      
      // 清理过期的增益
      final now = DateTime.now();
      _activeBoosts.removeWhere((key, expiry) => now.isAfter(expiry));
      
      // 保存清理后的增益
      await _taskService.saveActiveBoosts(_activeBoosts);
    } catch (e) {
      print('Error loading active boosts: $e');
    }
  }
  
  // 更新用户金币数量
  void updateUserGold(int gold) {
    _userGold = gold;
    notifyListeners();
  }
  
  // 购买物品
  Future<bool> purchaseItem(ShopItem item) async {
    try {
      // 检查金币是否足够
      if (_userGold < item.price) {
        return false;
      }
      
      // 检查是否为限时物品且已过期
      if (item.isLimited && item.limitedUntil != null) {
        if (DateTime.now().isAfter(item.limitedUntil!)) {
          return false;
        }
      }
      
      // 扣除金币
      _userGold -= item.price;
      
      // 创建购买记录
      final purchaseRecord = PurchaseRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user', // 在实际应用中应该使用真实用户ID
        itemId: item.id,
        purchaseTime: DateTime.now(),
        pricePaid: item.price,
      );
      
      // 保存购买记录
      await _taskService.savePurchaseRecord(purchaseRecord.toMap());
      _purchaseHistory.add(purchaseRecord);
      
      // 处理物品效果
      await _applyItemEffect(item);
      
      // 将商品添加到库存
      _inventory.add(item);
      await _taskService.addToInventory(item.toMap());
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error purchasing item: $e');
      return false;
    }
  }
  
  // 应用物品效果
  Future<void> _applyItemEffect(ShopItem item) async {
    try {
      switch (item.id) {
        case 'exp_boost_1h':
        case 'gold_boost_1h':
          // 添加增益效果
          final duration = Duration(hours: item.effect['duration_hours'] ?? 1);
          final expiry = DateTime.now().add(duration);
          _activeBoosts[item.id] = expiry;
          await _taskService.saveActiveBoosts(_activeBoosts);
          break;
          
        case 'treasure_key':
          // 宝箱钥匙的效果在使用时处理
          break;
          
        case 'time_crystal':
          // 时间水晶的效果在使用时处理
          break;
          
        default:
          // 其他物品的效果
          break;
      }
    } catch (e) {
      print('Error applying item effect: $e');
    }
  }
  
  // 使用消耗品
  Future<bool> useConsumableItem(String itemId, {Map<String, dynamic>? context}) async {
    try {
      // 检查是否拥有该物品
      final purchaseRecord = _purchaseHistory
          .where((record) => record.itemId == itemId && record.usedTime == null)
          .firstOrNull;
      
      if (purchaseRecord == null) {
        return false;
      }
      
      final item = _items.firstWhere((item) => item.id == itemId);
      
      // 应用使用效果
      bool success = await _applyUseEffect(item, context);
      
      if (success) {
        // 标记为已使用
        final updatedRecord = PurchaseRecord(
          id: purchaseRecord.id,
          userId: purchaseRecord.userId,
          itemId: purchaseRecord.itemId,
          purchaseTime: purchaseRecord.purchaseTime,
          pricePaid: purchaseRecord.pricePaid,
          usedTime: DateTime.now(),
          isActive: false,
        );
        
        await _taskService.updatePurchaseRecord(updatedRecord.toMap());
        
        // 更新本地记录
        final index = _purchaseHistory.indexOf(purchaseRecord);
        _purchaseHistory[index] = updatedRecord;
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('Error using consumable item: $e');
      return false;
    }
  }
  
  // 应用使用效果
  Future<bool> _applyUseEffect(ShopItem item, Map<String, dynamic>? context) async {
    switch (item.id) {
      case 'treasure_key':
        // 直接打开宝箱的逻辑
        // 这里需要与TaskProvider协调
        return true;
        
      case 'time_crystal':
        // 延长任务时间的逻辑
        if (context != null && context.containsKey('taskId')) {
          // 这里需要与TaskProvider协调延长任务时间
          return true;
        }
        return false;
        
      case 'task_template_pack':
        // 添加任务模板的逻辑
        return true;
        
      default:
        return false;
    }
  }
  
  // 获取当前生效的经验倍数
  double getExpMultiplier() {
    if (_activeBoosts.containsKey('exp_boost_1h')) {
      final expiry = _activeBoosts['exp_boost_1h']!;
      if (DateTime.now().isBefore(expiry)) {
        return 1.5; // 50% 增益
      } else {
        _activeBoosts.remove('exp_boost_1h');
        _taskService.saveActiveBoosts(_activeBoosts);
      }
    }
    return 1.0;
  }
  
  // 获取当前生效的金币倍数
  double getGoldMultiplier() {
    if (_activeBoosts.containsKey('gold_boost_1h')) {
      final expiry = _activeBoosts['gold_boost_1h']!;
      if (DateTime.now().isBefore(expiry)) {
        return 2.0; // 100% 增益
      } else {
        _activeBoosts.remove('gold_boost_1h');
        _taskService.saveActiveBoosts(_activeBoosts);
      }
    }
    return 1.0;
  }
  
  // 检查是否拥有某个物品
  bool hasItem(String itemId) {
    return _inventory.any((item) => item.id == itemId) ||
           _purchaseHistory.any((record) => 
               record.itemId == itemId && 
               record.usedTime == null);
  }
  
  // 获取拥有的消耗品数量
  int getConsumableCount(String itemId) {
    return _purchaseHistory.where((record) => 
        record.itemId == itemId && 
        record.usedTime == null).length;
  }
  
  // 获取商店统计信息
  Map<String, dynamic> getShopStats() {
    final totalSpent = _purchaseHistory.fold<int>(
      0, (sum, record) => sum + record.pricePaid);
    
    final totalItems = _purchaseHistory.length;
    
    final activeBoostsCount = _activeBoosts.length;
    
    return {
      'totalSpent': totalSpent,
      'totalItems': totalItems,
      'inventorySize': _inventory.length,
      'activeBoosts': activeBoostsCount,
    };
  }

  // === 商品管理方法 ===
  
  // 添加新商品
  Future<bool> addItem(ShopItem item) async {
    try {
      print('Adding shop item: ${item.name}');
      await _taskService.addShopItem(item.toMap());
      print('Shop item added to database: ${item.name}');
      
      // 重新加载商品列表
      await _loadShopItems();
      notifyListeners();
      
      print('Shop item added successfully and list reloaded: ${item.name}');
      return true;
    } catch (e) {
      print('Error adding shop item: $e');
      throw Exception('添加商品失败: ${e.toString()}');
    }
  }

  // 更新商品
  Future<bool> updateItem(ShopItem item) async {
    try {
      print('Updating shop item: ${item.name}');
      await _taskService.updateShopItem(item.toMap());
      
      // 重新加载商品列表
      await _loadShopItems();
      notifyListeners();
      
      print('Shop item updated successfully: ${item.name}');
      return true;
    } catch (e) {
      print('Error updating shop item: $e');
      return false;
    }
  }

  // 删除商品
  Future<bool> deleteItem(String itemId) async {
    try {
      await _taskService.deleteShopItem(itemId);
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting shop item: $e');
      return false;
    }
  }

  // 重新加载商品列表
  Future<void> reloadItems() async {
    await _loadShopItems();
    notifyListeners();
  }
}