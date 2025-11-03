import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profession_provider.dart';
import '../models/profession.dart';
import 'profession_form_screen.dart';

class ProfessionScreen extends StatefulWidget {
  static const routeName = '/professions';
  
  @override
  _ProfessionScreenState createState() => _ProfessionScreenState();
}

class _ProfessionScreenState extends State<ProfessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfessionProvider>(context, listen: false).loadProfessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('职业系统', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('职业系统说明'),
                  content: Text('创建职业并将任务关联到职业，完成任务可获得职业经验，提升职业等级！'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('了解'))
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProfessionProvider>(
        builder: (context, professionProvider, child) {
          final professions = professionProvider.professions;
          final activeProfession = professionProvider.activeProfession;
          
          if (professions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('还没有职业', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('点击下方按钮创建你的第一个职业', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: professions.length,
            itemBuilder: (context, index) {
              final profession = professions[index];
              final isActive = activeProfession?.id == profession.id;
              
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: isActive ? 4 : 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isActive ? Border.all(color: Colors.deepPurple, width: 2) : null,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: _getColorFromString(profession.color),
                      child: Text(profession.icon, style: TextStyle(fontSize: 24)),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            profession.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        if (isActive) 
                          Chip(
                            label: Text('当前', style: TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: Colors.deepPurple,
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text(profession.description),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Text('等级 ${profession.level}', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 16),
                            Text('经验: ${profession.experience}'),
                          ],
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: profession.levelProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(_getColorFromString(profession.color)),
                        ),
                        SizedBox(height: 4),
                        Text('距离下一等级: ${profession.expToNextLevel} 经验', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'activate') {
                          professionProvider.setActiveProfession(profession.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已激活职业：${profession.name}')),
                          );
                        } else if (value == 'edit') {
                          Navigator.of(context).pushNamed(
                            ProfessionFormScreen.editRouteName,
                            arguments: profession,
                          );
                        } else if (value == 'delete') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('删除职业'),
                              content: Text('确定要删除职业"${profession.name}"吗？\n关联的任务将解除职业关联。'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('取消')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('删除')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await professionProvider.deleteProfession(profession.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已删除职业：${profession.name}')),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isActive)
                          PopupMenuItem(value: 'activate', child: Row(children: [Icon(Icons.star), SizedBox(width: 8), Text('激活')])),
                        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('编辑')])),
                        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text('删除')])),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(ProfessionFormScreen.routeName);
        },
        label: Text('添加职业'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
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