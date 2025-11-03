import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profession_provider.dart';
import '../models/profession.dart';

class ProfessionFormScreen extends StatefulWidget {
  static const routeName = '/add_profession';
  static const editRouteName = '/edit_profession';
  
  @override
  _ProfessionFormScreenState createState() => _ProfessionFormScreenState();
}

class _ProfessionFormScreenState extends State<ProfessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedIcon = '💼';
  String _selectedColor = 'blue';
  Profession? _editingProfession;
  bool _showTemplates = true;
  
  final List<String> _availableIcons = ['💼', '💻', '🎨', '💪', '📚', '🎭', '⚔️', '🔧', '🎵', '🍳'];
  final List<Map<String, String>> _colorOptions = [
    {'name': 'blue', 'display': '蓝色'},
    {'name': 'purple', 'display': '紫色'},
    {'name': 'red', 'display': '红色'},
    {'name': 'green', 'display': '绿色'},
    {'name': 'orange', 'display': '橙色'},
    {'name': 'pink', 'display': '粉色'},
  ];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Profession) {
        setState(() {
          _editingProfession = args;
          _nameController.text = args.name;
          _descriptionController.text = args.description;
          _selectedIcon = args.icon;
          _selectedColor = args.color;
          _showTemplates = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingProfession == null ? '添加职业' : '编辑职业'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 模板选择（仅新建时显示）
              if (_editingProfession == null && _showTemplates) ...[
                Text('快速开始', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('选择一个模板快速创建职业：', style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: Profession.templates.length,
                  itemBuilder: (context, index) {
                    final template = Profession.templates[index];
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _useTemplate(template),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text(template['icon']!, style: TextStyle(fontSize: 24)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(template['name']!, style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(template['description']!, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('或自定义创建', style: TextStyle(color: Colors.grey[600])),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: 24),
              ],
              
              // 职业名称
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '职业名称',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入职业名称';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // 职业描述
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '职业描述',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入职业描述';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // 图标选择
              Text('选择图标', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = _availableIcons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: isSelected ? Colors.deepPurple : Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? Colors.deepPurple[50] : null,
                      ),
                      child: Center(
                        child: Text(icon, style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              
              // 颜色选择
              Text('选择颜色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _colorOptions.map((colorOption) {
                  final isSelected = colorOption['name'] == _selectedColor;
                  return ChoiceChip(
                    label: Text(colorOption['display']!),
                    selected: isSelected,
                    selectedColor: _getColorFromString(colorOption['name']!).withOpacity(0.3),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedColor = colorOption['name']!);
                      }
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 32),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfession,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  child: Text(
                    _editingProfession == null ? '创建职业' : '更新职业',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _useTemplate(Map<String, String> template) {
    setState(() {
      _nameController.text = template['name']!;
      _descriptionController.text = template['description']!;
      _selectedIcon = template['icon']!;
      _selectedColor = template['color']!;
      _showTemplates = false;
    });
  }
  
  void _saveProfession() async {
    if (_formKey.currentState!.validate()) {
      final professionProvider = Provider.of<ProfessionProvider>(context, listen: false);
      
      if (_editingProfession == null) {
        // 创建新职业
        final newProfession = Profession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          description: _descriptionController.text,
          icon: _selectedIcon,
          color: _selectedColor,
        );
        await professionProvider.addProfession(newProfession);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('职业"${newProfession.name}"创建成功！')),
        );
      } else {
        // 更新现有职业
        _editingProfession!.name = _nameController.text;
        _editingProfession!.description = _descriptionController.text;
        _editingProfession!.icon = _selectedIcon;
        _editingProfession!.color = _selectedColor;
        await professionProvider.updateProfession(_editingProfession!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('职业"${_editingProfession!.name}"更新成功！')),
        );
      }
      
      Navigator.pop(context);
    }
  }
  
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue': return Colors.blue;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'pink': return Colors.pink;
      default: return Colors.blue;
    }
  }
}