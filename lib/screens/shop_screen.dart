import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../providers/task_provider.dart';
import '../models/shop_item.dart';
import '../widgets/shop_item_card.dart';
import '../screens/shop_item_form_screen.dart';

class ShopScreen extends StatefulWidget {
  static const routeName = '/shop';
  
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  
  @override
  void initState() {
    super.initState();
    
    // 初始化商店
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      shopProvider.initializeShop();
      shopProvider.updateUserGold(taskProvider.totalGold);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('商店'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add_shopping_cart),
            onPressed: () {
              Navigator.of(context).pushNamed(ShopItemFormScreen.routeName).then((_) {
                // 返回时重新加载商品列表
                final shopProvider = Provider.of<ShopProvider>(context, listen: false);
                shopProvider.reloadItems();
              });
            },
            tooltip: '添加商品',
          ),
        ],
      ),
      body: Column(
        children: [
          // 金币显示区域
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber[100]!, Colors.orange[100]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.amber[800], size: 32),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '我的金币',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.amber[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${shopProvider.userGold}',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.amber[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // 激活增益显示
                    if (shopProvider.activeBoosts.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, color: Colors.green[700], size: 16),
                            SizedBox(width: 4),
                            Text(
                              '增益生效中',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          
          // 商品列表
          Expanded(
            child: Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                final items = shopProvider.availableItems;
                
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          '暂无商品',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '点击右上角添加新商品',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ShopItemCard(
                        item: items[index],
                        onEdit: () => _editItem(items[index]),
                        onPurchase: () => _purchaseItem(items[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showInventoryDialog();
        },
        icon: Icon(Icons.backpack),
        label: Text('我的物品'),
        backgroundColor: Colors.deepPurple[600],
      ),
    );
  }

  void _editItem(ShopItem item) {
    Navigator.of(context).pushNamed(
      ShopItemFormScreen.editRouteName,
      arguments: item,
    ).then((_) {
      // 返回时重新加载商品列表
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      shopProvider.reloadItems();
    });
  }

  Future<void> _purchaseItem(ShopItem item) async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // 检查金币是否足够
    if (shopProvider.userGold < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('金币不足！需要 ${item.price} 金币'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 确认购买对话框
    final shouldPurchase = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(item.icon, style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Expanded(child: Text('确认购买')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('商品：${item.name}'),
              SizedBox(height: 8),
              Text('价格：${item.price} 金币'),
              SizedBox(height: 8),
              Text('描述：${item.description}'),
              SizedBox(height: 16),
              Text(
                '购买后剩余金币：${shopProvider.userGold - item.price}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('确认购买'),
            ),
          ],
        );
      },
    );

    if (shouldPurchase == true) {
      final success = await shopProvider.purchaseItem(item);
      if (success) {
        // 更新任务提供者的金币数量
        await taskProvider.updateGold(taskProvider.totalGold - item.price);
        shopProvider.updateUserGold(taskProvider.totalGold);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('购买成功！${item.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('购买失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInventoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.backpack, color: Colors.deepPurple[600]),
              SizedBox(width: 8),
              Text('我的物品'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                if (shopProvider.inventory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          '背包空空如也',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '去商店购买一些物品吧！',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: shopProvider.inventory.length,
                  itemBuilder: (context, index) {
                    final item = shopProvider.inventory[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple[100],
                          child: Text(
                            item.icon,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text(item.description),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}