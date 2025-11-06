import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/profession_provider.dart';
import '../widgets/task_list.dart';
import '../widgets/character_panel.dart';
import '../widgets/filter_chips.dart';
import '../widgets/add_task_fab.dart';
import '../screens/profession_screen.dart';
import '../screens/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final professionProvider = Provider.of<ProfessionProvider>(context, listen: false);
      
      await Future.wait([
        taskProvider.loadTasks(),
        professionProvider.loadProfessions(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
      // 可以在这里显示错误提示给用户
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), // 浅色背景
      appBar: AppBar(
        title: Text(
          '⚔️ 个人成长RPG系统 ⚔️',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 18,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        backgroundColor: Color(0xFF2E4057),
        elevation: 4,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E4057), Color(0xFF048A81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // 商店按钮
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFFFD23F), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.shopping_bag, color: Color(0xFFFFD23F)),
              onPressed: () {
                Navigator.of(context).pushNamed(ShopScreen.routeName);
              },
              tooltip: '🛒 商店',
            ),
          ),
          // 职业系统按钮
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFFF6B35), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.work, color: Color(0xFFFF6B35)),
              onPressed: () {
                Navigator.of(context).pushNamed(ProfessionScreen.routeName);
              },
              tooltip: '⚒️ 职业系统',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 角色面板（显示等级/经验/金币）
          CharacterPanel(),
          // 宝箱卡片
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final canOpen = taskProvider.canOpenTreasure;
                final completedToday = taskProvider.todayCompletedTasks;
                final hasReceived = taskProvider.hasTodayTreasure;
                
                String subtitle;
                String buttonText;
                VoidCallback? onPressed;
                
                if (hasReceived) {
                  subtitle = '今日宝箱已领取，明天再来吧！';
                  buttonText = '已领取';
                  onPressed = null;
                } else if (canOpen) {
                  subtitle = '恭喜！你已完成$completedToday个任务，可以开启宝箱了！';
                  buttonText = '开启宝箱';
                  onPressed = () async {
                    // 随机生成奖励并存为已完成的奖励任务
                    final rnd = DateTime.now().millisecondsSinceEpoch % 100;
                    final xp = 50 + (rnd % 51); // 50-100
                    final gold = 10 + (rnd % 91); // 10-100
                    await taskProvider.addReward(xp: xp, gold: gold, note: '宝箱奖励');
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Color(0xFF2E4057),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Color(0xFFFFD23F), width: 2),
                        ),
                        title: Text(
                          '🎉 宝箱已开启 🎉',
                          style: TextStyle(
                            color: Color(0xFFFFD23F),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          '获得经验：$xp EXP\n获得金币：$gold GOLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF048A81),
                              foregroundColor: Colors.white,
                            ),
                            child: Text('确定', style: TextStyle(fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                    );
                  };
                } else {
                  final remaining = 3 - completedToday;
                  subtitle = '完成$remaining个任务即可开启宝箱！(当前: $completedToday/3)';
                  buttonText = '未解锁';
                  onPressed = null;
                }
                
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: canOpen 
                          ? [Color(0xFFFFD23F), Color(0xFFFF6B35)]
                          : [Color(0xFF9E9E9E), Color(0xFF757575)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canOpen ? Color(0xFF2E4057) : Color(0xFF616161),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 宝箱图标
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: canOpen ? Color(0xFF2E4057) : Colors.grey[600],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            canOpen ? Icons.card_giftcard : Icons.lock,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        
                        SizedBox(width: 12),
                        
                        // 宝箱信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🏆 每日宝箱',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.7),
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // 开启按钮
                        Container(
                          decoration: BoxDecoration(
                            color: onPressed != null ? Color(0xFF048A81) : Colors.grey[600],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: onPressed != null ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ] : null,
                          ),
                          child: ElevatedButton(
                            onPressed: onPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 筛选器
          FilterChips(),
          // 任务列表
          Expanded(
            child: TaskList(),
          ),
        ],
      ),
      floatingActionButton: AddTaskFAB(),
      );
  }
}