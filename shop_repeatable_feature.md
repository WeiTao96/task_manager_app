# 商店重复购买功能说明

## 🆕 **新功能概述**

为商店系统添加了"重复购买"控制功能，解决了商品购买后仍然显示在商店中的问题。

## ✨ **功能特性**

### 1. **重复购买开关**
- 在添加/编辑商品时，可以设置该商品是否允许重复购买
- 默认值：允许重复购买（保持原有行为）

### 2. **商品显示逻辑**
- **允许重复购买的商品**：购买后仍然显示在商店中，可以再次购买
- **不允许重复购买的商品**：购买后自动从商店列表中消失

### 3. **视觉标识**
- 不可重复购买的商品显示红色"限购"标签
- 限时商品显示橙色"限时"标签
- 推荐商品显示紫色"推荐"标签

## 🎯 **使用场景**

### 适合重复购买的商品：
- 🧪 药水类消耗品（体力药水、经验药水等）
- 🪙 金币包、钻石包等虚拟货币
- 🔋 能量包、加速器等临时增益

### 适合单次购买的商品：
- 🔑 特殊钥匙、通行证
- 🏆 独特装备、收藏品
- 📋 功能解锁、权限升级
- 🎨 皮肤、主题等个性化内容

## 🛠️ **技术实现**

### 数据库更新
- 添加 `isRepeatable` 字段到 `shop_items` 表
- 数据库版本升级到 v7
- 自动迁移现有数据（默认为可重复购买）

### 核心逻辑
```dart
// 商品可见性过滤
List<ShopItem> get availableItems {
  return _items.where((item) {
    // 检查限时商品是否过期
    if (item.isLimited && item.limitedUntil != null) {
      if (DateTime.now().isAfter(item.limitedUntil!)) {
        return false;
      }
    }
    
    // 检查不可重复购买的商品是否已购买
    if (!item.isRepeatable) {
      final hasPurchased = _purchaseHistory.any((record) => 
        record.itemId == item.id);
      if (hasPurchased) {
        return false; // 已购买且不可重复购买，隐藏
      }
    }
    
    return true;
  }).toList();
}
```

## 📱 **用户操作流程**

### 添加商品时：
1. 填写商品基本信息（名称、描述、价格、图标）
2. 设置限时选项（可选）
3. **设置重复购买选项**
   - 开启：商品可以重复购买
   - 关闭：商品购买一次后从商店消失
4. 保存商品

### 购买商品时：
- 可重复购买的商品：购买后仍在商店中显示
- 不可重复购买的商品：购买后自动从商店列表移除

## 🔄 **向后兼容性**

- 现有商品默认设置为"允许重复购买"
- 不影响已有的购买记录和库存
- 保持原有的商店UI和购买流程

## 📊 **数据结构**

```dart
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int price;
  final Map<String, dynamic> effect;
  final bool isLimited;
  final DateTime? limitedUntil;
  final bool isRepeatable; // 新增字段
  
  // ... 其他方法
}
```

## ✅ **测试建议**

1. **创建不可重复购买的商品**，购买后确认其从商店列表消失
2. **创建可重复购买的商品**，购买后确认其仍在商店中显示
3. **编辑现有商品**的重复购买设置，验证行为变化
4. **混合场景测试**：同时有可重复和不可重复的商品

---

此功能已集成到商店系统中，为游戏化任务管理应用提供了更灵活的商品管理能力！