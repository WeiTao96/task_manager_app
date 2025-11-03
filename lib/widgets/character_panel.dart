import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class CharacterPanel extends StatelessWidget {
  final String characterName;
  const CharacterPanel({Key? key, this.characterName = '罗伟韬'}) : super(key: key);

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

    return Card(
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Colors.orange[200],
              child: Text(
                'L$level',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        characterName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(Icons.monetization_on, size: 18, color: Colors.amber[700]),
                          SizedBox(width: 4),
                          Text('$totalGold'),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('经验：$current / $need'),
                  SizedBox(height: 6),
                  LinearProgressIndicator(value: progress, minHeight: 8),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
