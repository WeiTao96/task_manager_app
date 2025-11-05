import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isCompact;
  final VoidCallback? onTap;

  const AchievementCard({
    Key? key,
    required this.achievement,
    this.isCompact = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      elevation: achievement.isUnlocked ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: achievement.isUnlocked
                ? LinearGradient(
                    colors: [
                      achievement.color.withOpacity(0.1),
                      achievement.color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: achievement.isUnlocked
                ? Border.all(color: achievement.color.withOpacity(0.3), width: 2)
                : Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: isCompact ? _buildCompactContent() : _buildFullContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContent() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: achievement.isUnlocked 
                ? achievement.color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 24,
                color: achievement.isUnlocked ? null : Colors.grey,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked ? Colors.black : Colors.grey,
                ),
              ),
              if (achievement.unlockedDate != null) ...[
                SizedBox(height: 4),
                Text(
                  '解锁于 ${_formatDate(achievement.unlockedDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: achievement.color,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (achievement.isUnlocked)
          Icon(
            Icons.check_circle,
            color: achievement.color,
            size: 24,
          )
        else
          Icon(
            Icons.lock,
            color: Colors.grey,
            size: 24,
          ),
      ],
    );
  }

  Widget _buildFullContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: achievement.isUnlocked 
                    ? achievement.color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 28,
                    color: achievement.isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: achievement.isUnlocked ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      if (achievement.isUnlocked)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: achievement.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '已解锁',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '未解锁',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    achievement.type.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: achievement.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        Text(
          achievement.description,
          style: TextStyle(
            fontSize: 14,
            color: achievement.isUnlocked ? Colors.black87 : Colors.grey[600],
          ),
        ),
        
        SizedBox(height: 16),
        
        // 进度条
        if (!achievement.isUnlocked) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '进度',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${achievement.currentValue}/${achievement.targetValue}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: achievement.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: achievement.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
            minHeight: 6,
          ),
        ],
        
        // 奖励信息
        if (achievement.rewardXp > 0 || achievement.rewardGold > 0) ...[
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                '奖励: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (achievement.rewardXp > 0) ...[
                Icon(Icons.star, size: 16, color: Colors.amber),
                Text(
                  '${achievement.rewardXp}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(width: 8),
              ],
              if (achievement.rewardGold > 0) ...[
                Icon(Icons.monetization_on, size: 16, color: Colors.yellow[700]),
                Text(
                  '${achievement.rewardGold}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[700],
                  ),
                ),
              ],
            ],
          ),
        ],
        
        // 解锁时间
        if (achievement.isUnlocked && achievement.unlockedDate != null) ...[
          SizedBox(height: 8),
          Text(
            '解锁于 ${_formatDate(achievement.unlockedDate!)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}