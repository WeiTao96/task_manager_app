import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../models/shop_item.dart';

class ShopItemFormScreen extends StatefulWidget {
  static const routeName = '/add_shop_item';
  static const editRouteName = '/edit_shop_item';
  
  @override
  _ShopItemFormScreenState createState() => _ShopItemFormScreenState();
}

class _ShopItemFormScreenState extends State<ShopItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedIcon = '🎁';
  bool _isLimited = false;
  DateTime? _limitedUntil;
  
  ShopItem? _editingItem;
  bool _isLoading = false;
  
  final List<String> _commonIcons = [
    '🎁', '🏆', '👑', '💎', '🔑', '🧪', '🪙', '📋', 
    '🎯', '⭐', '💰', '🎨', '🛡️', '⚡', '🔥', '❄️',
    '🌟', '💝', '🎪', '🎭', '🎨', '🎪', '🎨', '🏅'
  ];
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }
  
  Future<void> _initializeForm() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is ShopItem) {
        setState(() {
          _editingItem = args;
          _nameController.text = args.name;
          _descriptionController.text = args.description;
          _priceController.text = args.price.toString();
          _selectedIcon = args.icon;
          _isLimited = args.isLimited;
          _limitedUntil = args.limitedUntil;
        });
      }
    } catch (e) {
      print('Error initializing form: $e');
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingItem == null ? '添加商品' : '编辑商品'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          if (_editingItem != null) ...[
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteItem,
            ),
          ],
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品名称
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '商品名称',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入商品名称';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // 商品描述
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: '商品描述',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入商品描述';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // 价格
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: '价格（金币）',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on, color: Colors.amber),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入价格';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return '请输入有效的价格';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // 图标选择
                  Text(
                    '选择图标',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonIcons.map((icon) {
                        final isSelected = icon == _selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.deepPurple[100] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.deepPurple[400]! : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                icon,
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // 限时商品选项
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.orange[600]),
                              SizedBox(width: 8),
                              Text(
                                '限时商品设置',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          SwitchListTile(
                            title: Text('设为限时商品'),
                            subtitle: Text('限时商品在指定时间后将不再可购买'),
                            value: _isLimited,
                            onChanged: (bool value) {
                              setState(() {
                                _isLimited = value;
                                if (!value) {
                                  _limitedUntil = null;
                                }
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_isLimited) ...[
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.calendar_today),
                              title: Text('限时截止日期'),
                              subtitle: Text(
                                _limitedUntil != null
                                    ? '${_limitedUntil!.year}-${_limitedUntil!.month.toString().padLeft(2, '0')}-${_limitedUntil!.day.toString().padLeft(2, '0')}'
                                    : '未设置',
                              ),
                              trailing: Icon(Icons.arrow_drop_down),
                              onTap: _selectLimitDate,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveItem,
                      child: Text(
                        _editingItem == null ? '添加商品' : '更新商品',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
  
  Future<void> _selectLimitDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _limitedUntil ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _limitedUntil = picked;
      });
    }
  }
  
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isLimited && _limitedUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('限时商品请设置截止日期')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final price = int.parse(_priceController.text);
      
      final ShopItem item;
      if (_editingItem == null) {
        // 添加新商品
        item = ShopItem.create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          price: price,
          isLimited: _isLimited,
          limitedUntil: _limitedUntil,
        );
        
        final success = await shopProvider.addItem(item);
        if (success) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('商品添加成功！')),
            );
          }
        } else {
          throw Exception('添加商品失败');
        }
      } else {
        // 更新现有商品
        item = ShopItem(
          id: _editingItem!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          price: price,
          isLimited: _isLimited,
          limitedUntil: _limitedUntil,
        );
        
        final success = await shopProvider.updateItem(item);
        if (success) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('商品更新成功！')),
            );
          }
        } else {
          throw Exception('更新商品失败');
        }
      }
    } catch (e) {
      print('Error saving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _deleteItem() async {
    if (_editingItem == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除商品"${_editingItem!.name}"吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('删除'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final shopProvider = Provider.of<ShopProvider>(context, listen: false);
        final success = await shopProvider.deleteItem(_editingItem!.id);
        
        if (success) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('商品删除成功！')),
            );
          }
        } else {
          throw Exception('删除商品失败');
        }
      } catch (e) {
        print('Error deleting item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}