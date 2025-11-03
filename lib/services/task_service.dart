import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/profession.dart';

class TaskService {
  static Database? _database;

  //获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    //如果数据库不存在，则创建
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'tasks.db');
      // bump DB version to 3 to include professions table and professionId in tasks
      return await openDatabase(
        path, 
        version: 3, 
        onCreate: _createTables, 
        onUpgrade: _onUpgrade,
        // 添加数据库打开超时
        onOpen: (db) async {
          print('Database opened successfully');
        },
      ).timeout(Duration(seconds: 10)); // 10秒超时
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        isCompleted INTEGER NOT NULL,
        dueDate TEXT NOT NULL,
        category TEXT NOT NULL,
        xp INTEGER DEFAULT 0,
        gold INTEGER DEFAULT 0,
        professionId TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE professions(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT DEFAULT '💼',
        color TEXT DEFAULT 'blue',
        level INTEGER DEFAULT 1,
        experience INTEGER DEFAULT 0
      )
    ''');
  }

  // handle upgrading older DBs (add xp/gold columns and professions table)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN xp INTEGER DEFAULT 0');
      } catch (e) {
        // ignore if already exists
      }
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN gold INTEGER DEFAULT 0');
      } catch (e) {
        // ignore if already exists
      }
    }
    
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN professionId TEXT');
      } catch (e) {
        // ignore if already exists
      }
      
      try {
        await db.execute('''
          CREATE TABLE professions(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            icon TEXT DEFAULT '💼',
            color TEXT DEFAULT 'blue',
            level INTEGER DEFAULT 1,
            experience INTEGER DEFAULT 0
          )
        ''');
      } catch (e) {
        // ignore if already exists
      }
    }
  }

  // 添加任务
  Future<void> addTask(Task task) async {
    try {
      final db = await database;
      await db.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error adding task to database: $e');
      rethrow;
    }
  }

  // 获取所有任务
  Future<List<Task>> getTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('tasks');
      return List.generate(maps.length, (i) {
        try {
          return Task.fromMap(maps[i]);
        } catch (e) {
          print('Error parsing task at index $i: $e');
          return null;
        }
      }).where((task) => task != null).cast<Task>().toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  // 更新任务
  Future<void> updateTask(Task task) async {
    try {
      final db = await database;
      await db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      print('Error updating task in database: $e');
      rethrow;
    }
  }

  // 删除任务
  Future<void> deleteTask(String id) async {
    try {
      final db = await database;
      await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting task from database: $e');
      rethrow;
    }
  }

  // === 职业相关操作 ===
  
  // 添加职业
  Future<void> addProfession(Profession profession) async {
    final db = await database;
    await db.insert(
      'professions',
      profession.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取所有职业
  Future<List<Profession>> getProfessions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('professions');
      return List.generate(maps.length, (i) {
        try {
          return Profession.fromMap(maps[i]);
        } catch (e) {
          print('Error parsing profession at index $i: $e');
          return null;
        }
      }).where((profession) => profession != null).cast<Profession>().toList();
    } catch (e) {
      print('Error getting professions: $e');
      return [];
    }
  }

  // 更新职业
  Future<void> updateProfession(Profession profession) async {
    final db = await database;
    await db.update(
      'professions',
      profession.toMap(),
      where: 'id = ?',
      whereArgs: [profession.id],
    );
  }

  // 删除职业
  Future<void> deleteProfession(String id) async {
    final db = await database;
    // 先清除该职业关联的任务的professionId
    await db.update(
      'tasks',
      {'professionId': null},
      where: 'professionId = ?',
      whereArgs: [id],
    );
    // 删除职业
    await db.delete(
      'professions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 根据职业ID获取相关任务
  Future<List<Task>> getTasksByProfession(String professionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'professionId = ?',
      whereArgs: [professionId],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }
}
