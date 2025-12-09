import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/task_provider.dart';
import '../providers/profession_provider.dart';
import '../models/task.dart';
import '../widgets/achievement_card.dart';
import 'achievement_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final achievementProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    await achievementProvider.loadAchievements();

    // 更新成就进度
    final completedTasks = taskProvider.tasks
        .where((t) => t.isCompleted)
        .toList();
    final difficultyTaskCounts = <TaskDifficulty, int>{};

    for (final task in completedTasks) {
      difficultyTaskCounts[task.difficulty] =
          (difficultyTaskCounts[task.difficulty] ?? 0) + 1;
    }

    await achievementProvider.checkAchievements(
      completedTasks: completedTasks,
      totalExperience: taskProvider.totalExp,
      totalGold: taskProvider.totalGold,
      difficultyTaskCounts: difficultyTaskCounts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('个人档案'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AchievementManagementScreen.routeName,
              );
            },
            tooltip: '成就管理',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.person), text: '概览'),
            Tab(icon: Icon(Icons.emoji_events), text: '成就'),
            Tab(icon: Icon(Icons.bar_chart), text: '统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAchievementsTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer3<TaskProvider, ProfessionProvider, AchievementProvider>(
      builder:
          (
            context,
            taskProvider,
            professionProvider,
            achievementProvider,
            child,
          ) {
            final stats = achievementProvider.getAchievementStats();
            final recentAchievements = achievementProvider.getRecentlyUnlocked(
              limit: 3,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户头像和基本信息
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo, Colors.indigoAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.indigo,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '成长探索者',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          taskProvider.tasks.isNotEmpty
                              ? '已创建 ${taskProvider.tasks.length} 个任务'
                              : '开始你的任务管理之旅',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // 快速统计卡片
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          title: '总经验',
                          value: taskProvider.totalExp.toString(),
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          title: '总金币',
                          value: taskProvider.totalGold.toString(),
                          icon: Icons.monetization_on,
                          color: Colors.yellow[700]!,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          title: '完成任务',
                          value: taskProvider.tasks
                              .where((t) => t.isCompleted)
                              .length
                              .toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          title: '解锁成就',
                          value: '${stats['unlocked']}/${stats['total']}',
                          icon: Icons.emoji_events,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // 最近解锁的成就
                  if (recentAchievements.isNotEmpty) ...[
                    Text(
                      '最近解锁的成就',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...recentAchievements.map(
                      (achievement) => AchievementCard(
                        achievement: achievement,
                        isCompact: true,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // 职业概览
                  if (professionProvider.professions.isNotEmpty) ...[
                    Text(
                      '职业概览',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: professionProvider.professions.length,
                        itemBuilder: (context, index) {
                          final profession =
                              professionProvider.professions[index];
                          return Container(
                            width: 100,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  profession.icon,
                                  style: TextStyle(fontSize: 32),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  profession.name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Lv.${profession.level}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        final achievements = achievementProvider.achievements;

        if (achievements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  '暂无成就',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return AchievementCard(achievement: achievement);
          },
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer3<TaskProvider, ProfessionProvider, AchievementProvider>(
      builder: (context, taskProvider, professionProvider, achievementProvider, child) {
        final completedTasks = taskProvider.tasks
            .where((t) => t.isCompleted)
            .toList();
        final achievementStats = achievementProvider.getAchievementStats();

        // 按难度统计任务
        final difficultyStats = <TaskDifficulty, int>{};
        for (final task in completedTasks) {
          difficultyStats[task.difficulty] =
              (difficultyStats[task.difficulty] ?? 0) + 1;
        }

        // 按类型统计任务
        final typeStats = <TaskRepeatType, int>{};
        for (final task in completedTasks) {
          typeStats[task.repeatType] = (typeStats[task.repeatType] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 成就统计
              _buildStatisticsSection(
                title: '成就统计',
                children: [
                  _buildStatisticItem('总成就数', '${achievementStats['total']}'),
                  _buildStatisticItem('已解锁', '${achievementStats['unlocked']}'),
                  _buildStatisticItem(
                    '完成率',
                    '${achievementStats['completion_rate']}%',
                  ),
                  _buildStatisticItem('自定义成就', '${achievementStats['custom']}'),
                ],
              ),

              // 任务统计
              _buildStatisticsSection(
                title: '任务统计',
                children: [
                  _buildStatisticItem('总任务数', '${taskProvider.tasks.length}'),
                  _buildStatisticItem('已完成', '${completedTasks.length}'),
                  _buildStatisticItem(
                    '进行中',
                    '${taskProvider.tasks.length - completedTasks.length}',
                  ),
                  _buildStatisticItem(
                    '完成率',
                    taskProvider.tasks.isNotEmpty
                        ? '${((completedTasks.length / taskProvider.tasks.length) * 100).round()}%'
                        : '0%',
                  ),
                ],
              ),

              // 难度分布
              _buildStatisticsSection(
                title: '任务难度分布',
                children: [
                  _buildStatisticItem(
                    '低难度',
                    '${difficultyStats[TaskDifficulty.low] ?? 0}',
                    color: TaskDifficulty.low.color,
                  ),
                  _buildStatisticItem(
                    '中等难度',
                    '${difficultyStats[TaskDifficulty.medium] ?? 0}',
                    color: TaskDifficulty.medium.color,
                  ),
                  _buildStatisticItem(
                    '高难度',
                    '${difficultyStats[TaskDifficulty.high] ?? 0}',
                    color: TaskDifficulty.high.color,
                  ),
                ],
              ),

              // 任务类型分布
              _buildStatisticsSection(
                title: '任务类型分布',
                children: [
                  _buildStatisticItem(
                    '特殊任务',
                    '${typeStats[TaskRepeatType.special] ?? 0}',
                  ),
                  _buildStatisticItem(
                    '每日任务',
                    '${typeStats[TaskRepeatType.daily] ?? 0}',
                  ),
                  _buildStatisticItem(
                    '每周任务',
                    '${typeStats[TaskRepeatType.weekly] ?? 0}',
                  ),
                  _buildStatisticItem(
                    '每月任务',
                    '${typeStats[TaskRepeatType.monthly] ?? 0}',
                  ),
                ],
              ),

              // 经验和金币统计
              _buildStatisticsSection(
                title: '收益统计',
                children: [
                  _buildStatisticItem('总经验值', '${taskProvider.totalExp}'),
                  _buildStatisticItem('总金币', '${taskProvider.totalGold}'),
                  _buildStatisticItem(
                    '平均经验/任务',
                    completedTasks.isNotEmpty
                        ? '${(taskProvider.totalExp / completedTasks.length).round()}'
                        : '0',
                  ),
                  _buildStatisticItem(
                    '平均金币/任务',
                    completedTasks.isNotEmpty
                        ? '${(taskProvider.totalGold / completedTasks.length).round()}'
                        : '0',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(String label, String value, {Color? color}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
