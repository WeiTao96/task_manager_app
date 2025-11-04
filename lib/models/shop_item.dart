class ShopItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int price;
  final Map<String, dynamic> effect; // 物品效果数据
  final bool isLimited; // 是否限量
  final DateTime? limitedUntil; // 限量截止时间
  final bool isRepeatable; // 是否可重复购买
  
  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.price,
    this.effect = const {},
    this.isLimited = false,
    this.limitedUntil,
    this.isRepeatable = true, // 默认可重复购买
  });

  factory ShopItem.fromMap(Map<String, dynamic> map) {
    return ShopItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🎁',
      price: map['price'] ?? 0,
      effect: Map<String, dynamic>.from(map['effect'] ?? {}),
      isLimited: (map['isLimited'] is int) 
        ? (map['isLimited'] as int) == 1 
        : (map['isLimited'] ?? false),
      limitedUntil: map['limitedUntil'] != null 
        ? DateTime.parse(map['limitedUntil']) 
        : null,
      isRepeatable: (map['isRepeatable'] is int) 
        ? (map['isRepeatable'] as int) == 1 
        : (map['isRepeatable'] ?? true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'price': price,
      'effect': effect,
      'isLimited': isLimited ? 1 : 0,
      'limitedUntil': limitedUntil?.toIso8601String(),
      'isRepeatable': isRepeatable ? 1 : 0,
    };
  }

  // 创建商品的工厂方法，用于用户自定义
  factory ShopItem.create({
    required String name,
    required String description,
    required String icon,
    required int price,
    Map<String, dynamic>? effect,
    bool isLimited = false,
    DateTime? limitedUntil,
    bool isRepeatable = true,
  }) {
    return ShopItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      icon: icon,
      price: price,
      effect: effect ?? {},
      isLimited: isLimited,
      limitedUntil: limitedUntil,
      isRepeatable: isRepeatable,
    );
  }
}

// 用户购买记录
class PurchaseRecord {
  final String id;
  final String userId;
  final String itemId;
  final DateTime purchaseTime;
  final int pricePaid;
  final DateTime? usedTime; // 对于消耗品，记录使用时间
  final bool isActive; // 对于有时效的物品，是否仍然有效
  
  PurchaseRecord({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.purchaseTime,
    required this.pricePaid,
    this.usedTime,
    this.isActive = true,
  });

  factory PurchaseRecord.fromMap(Map<String, dynamic> map) {
    return PurchaseRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      itemId: map['itemId'] ?? '',
      purchaseTime: DateTime.parse(map['purchaseTime']),
      pricePaid: map['pricePaid'] ?? 0,
      usedTime: map['usedTime'] != null ? DateTime.parse(map['usedTime']) : null,
      isActive: (map['isActive'] is int) 
        ? (map['isActive'] as int) == 1 
        : (map['isActive'] ?? true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'itemId': itemId,
      'purchaseTime': purchaseTime.toIso8601String(),
      'pricePaid': pricePaid,
      'usedTime': usedTime?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }
}