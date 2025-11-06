import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../screens/profile_screen.dart';

class CharacterPanel extends StatelessWidget {
  final String characterName;
  const CharacterPanel({Key? key, this.characterName = '成长探索者'}) : super(key: key);

  // 每一级需要的经验值（按附件的公式：round(pow(level * 100, 1.2)))）
  int requiredForLevel(int level) {
    return (math.pow(level * 100, 1.2)).round();
  }

  // 根据累计经验计算等级（将每一级视为需要消耗的经验）
  Map<String, dynamic> deriveLevelAndProgress(int totalExp) {
    int level = 1;
    int remaining = totalExp;
    while (true) {
      int need = requiredForLevel(level);
      if (remaining >= need) {
        remaining -= need;
        level++;
      } else {
        return {
          'level': level,
          'current': remaining,
          'need': need,
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final totalExp = provider.totalExp;
    final totalGold = provider.totalGold;
    final info = deriveLevelAndProgress(totalExp);
    final level = info['level'] as int;
    final current = info['current'] as int;
    final need = info['need'] as int;
    final progress = need > 0 ? (current / need).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2E4057), // 深蓝灰
            Color(0xFF048A81), // 青绿
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Color(0xFFFFD23F), width: 2), // 金色边框
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 像素风格角色头像
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, ProfileScreen.routeName);
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFFFD23F), width: 3),
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFD23F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 角色图标
                    Center(
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    // 等级标签
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Color(0xFFFFD23F), width: 1),
                        ),
                        child: Text(
                          'L$level',
                          style: TextStyle(
                            color: Color(0xFFFFD23F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            
            // 角色信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 角色名和金币
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          characterName,
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 金币显示
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFD23F),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Color(0xFF1A1A2E), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 16,
                              color: Color(0xFF1A1A2E),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '$totalGold',
                              style: TextStyle(
                                color: Color(0xFF1A1A2E),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // 经验值文本
                  Text(
                    'EXP: $current / $need',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'monospace',
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.7),
                          offset: Offset(1, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 6),
                  
                  // 像素风格经验条
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Color(0xFF1A1A2E), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          // 背景
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Color(0xFF1A1A2E),
                          ),
                          // 进度条
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF048A81),
                                    Color(0xFF00D4AA),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          // 光泽效果
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.1),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
