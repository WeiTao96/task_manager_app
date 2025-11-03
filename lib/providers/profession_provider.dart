import 'package:flutter/foundation.dart';
import '../models/profession.dart';
import '../services/task_service.dart';

class ProfessionProvider with ChangeNotifier {
  List<Profession> _professions = [];
  String? _activeProfessionId; // 当前激活的职业

  List<Profession> get professions => _professions;
  
  Profession? get activeProfession {
    if (_activeProfessionId == null) return null;
    try {
      return _professions.firstWhere((p) => p.id == _activeProfessionId);
    } catch (e) {
      return null;
    }
  }

  String? get activeProfessionId => _activeProfessionId;

  final TaskService _taskService = TaskService();

  // 加载所有职业
  Future<void> loadProfessions() async {
    try {
      _professions = await _taskService.getProfessions();
      notifyListeners();
    } catch (e) {
      print('Error loading professions: $e');
      _professions = []; // 如果加载失败，设置为空列表
      notifyListeners();
    }
  }

  // 添加职业
  Future<void> addProfession(Profession profession) async {
    try {
      await _taskService.addProfession(profession);
      await loadProfessions();
    } catch (e) {
      print('Error adding profession: $e');
    }
  }

  // 更新职业
  Future<void> updateProfession(Profession profession) async {
    try {
      await _taskService.updateProfession(profession);
      await loadProfessions();
    } catch (e) {
      print('Error updating profession: $e');
    }
  }

  // 删除职业
  Future<void> deleteProfession(String id) async {
    try {
      await _taskService.deleteProfession(id);
      // 如果删除的是当前激活的职业，清除激活状态
      if (_activeProfessionId == id) {
        _activeProfessionId = null;
      }
      await loadProfessions();
    } catch (e) {
      print('Error deleting profession: $e');
    }
  }

  // 设置激活的职业
  void setActiveProfession(String? professionId) {
    _activeProfessionId = professionId;
    notifyListeners();
  }

  // 为职业添加经验值（当完成关联任务时调用）
  Future<void> addExperienceToProfession(String professionId, int experience) async {
    try {
      final professionIndex = _professions.indexWhere((p) => p.id == professionId);
      if (professionIndex == -1) return;
      
      final profession = _professions[professionIndex];
      profession.addExperience(experience);
      await updateProfession(profession);
    } catch (e) {
      print('Error adding experience to profession: $e');
    }
  }

  // 根据模板创建职业
  Future<Profession> createFromTemplate(Map<String, String> template) async {
    final profession = Profession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: template['name']!,
      description: template['description']!,
      icon: template['icon']!,
      color: template['color']!,
    );
    
    await addProfession(profession);
    return profession;
  }

  // 获取职业的经验值统计
  Map<String, dynamic> getProfessionStats(String professionId) {
    final profession = _professions.firstWhere((p) => p.id == professionId);
    return {
      'level': profession.level,
      'experience': profession.experience,
      'progress': profession.levelProgress,
      'expToNext': profession.expToNextLevel,
    };
  }

  // 重置职业经验（开发/测试用）
  Future<void> resetProfessionExperience(String professionId) async {
    final profession = _professions.firstWhere((p) => p.id == professionId);
    profession.level = 1;
    profession.experience = 0;
    await updateProfession(profession);
  }
}