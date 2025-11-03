import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/profession_provider.dart';
import '../widgets/task_list.dart';
import '../widgets/character_panel.dart';
import '../widgets/filter_chips.dart';
import '../widgets/add_task_fab.dart';
import '../screens/profession_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
      Provider.of<ProfessionProvider>(context, listen: false).loadProfessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('个人成长RPG系统',
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.work),
            onPressed: () {
              Navigator.of(context).pushNamed(ProfessionScreen.routeName);
            },
            tooltip: '职业系统',
          ),
        ],
      ),
      body: Column(
        children: [
          // 角色面板（显示等级/经验/金币）
          CharacterPanel(),
          // 宝箱卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                        title: Text('宝箱已开启 🎉'),
                        content: Text('获得经验：$xp\n获得金币：$gold'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('确定'))
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
                
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(
                      Icons.card_giftcard, 
                      color: canOpen ? Colors.deepPurple : Colors.grey
                    ),
                    title: Text('宝箱系统'),
                    subtitle: Text(subtitle),
                    trailing: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canOpen ? null : Colors.grey,
                      ),
                      child: Text(buttonText),
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