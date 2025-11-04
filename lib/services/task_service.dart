import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
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
      print('Initializing database at: $path');
      
      // bump DB version to 7 to add isRepeatable to shop_items
      return await openDatabase(
        path, 
        version: 7, 
        onCreate: _createTables, 
        onUpgrade: _onUpgrade,
        // 简化数据库打开配置，避免PRAGMA问题
        onOpen: (db) async {
          print('Database opened successfully');
        },
      ).timeout(
        Duration(seconds: 15), 
        onTimeout: () {
          print('Database initialization timeout');
          throw Exception('Database initialization timeout');
        },
      ); // 15秒超时
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
    
    // 商店相关表
    await db.execute('''
      CREATE TABLE purchase_records(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        purchaseTime TEXT NOT NULL,
        pricePaid INTEGER NOT NULL,
        usedTime TEXT,
        isActive INTEGER DEFAULT 1
      )
    ''');
    
    await db.execute('''
      CREATE TABLE user_inventory(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        itemData TEXT NOT NULL,
        acquiredTime TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE active_boosts(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        boostType TEXT NOT NULL,
        expiryTime TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_items(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT DEFAULT '🎁',
        price INTEGER NOT NULL,
        effect TEXT DEFAULT '{}',
        isLimited INTEGER DEFAULT 0,
        limitedUntil TEXT,
        isRepeatable INTEGER DEFAULT 1,
        createdBy TEXT DEFAULT 'user',
        createdTime TEXT NOT NULL
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
    
    if (oldVersion < 4) {
      // 添加商店相关表
      try {
        await db.execute('''
          CREATE TABLE purchase_records(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            itemId TEXT NOT NULL,
            purchaseTime TEXT NOT NULL,
            pricePaid INTEGER NOT NULL,
            usedTime TEXT,
            isActive INTEGER DEFAULT 1
          )
        ''');
      } catch (e) {
        // ignore if already exists
      }
      
      try {
        await db.execute('''
          CREATE TABLE user_inventory(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            itemData TEXT NOT NULL,
            acquiredTime TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // ignore if already exists
      }
      
      try {
        await db.execute('''
          CREATE TABLE active_boosts(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            boostType TEXT NOT NULL,
            expiryTime TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // ignore if already exists
      }

      try {
        await db.execute('''
          CREATE TABLE shop_items(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            icon TEXT DEFAULT '🎁',
            price INTEGER NOT NULL,
            effect TEXT DEFAULT '{}',
            isLimited INTEGER DEFAULT 0,
            limitedUntil TEXT,
            createdBy TEXT DEFAULT 'user',
            createdTime TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // ignore if already exists
      }
    }
    
    if (oldVersion < 5) {
      // 删除商品分类字段，创建新表并迁移数据
      try {
        // 创建新的shop_items表（不包含category字段）
        await db.execute('''
          CREATE TABLE shop_items_new(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            icon TEXT DEFAULT '🎁',
            price INTEGER NOT NULL,
            type TEXT NOT NULL,
            effect TEXT DEFAULT '{}',
            isLimited INTEGER DEFAULT 0,
            limitedUntil TEXT,
            createdBy TEXT DEFAULT 'user',
            createdTime TEXT NOT NULL
          )
        ''');
        
        // 复制现有数据（排除category字段）
        await db.execute('''
          INSERT INTO shop_items_new (id, name, description, icon, price, type, effect, isLimited, limitedUntil, createdBy, createdTime)
          SELECT id, name, description, icon, price, type, effect, isLimited, limitedUntil, createdBy, createdTime
          FROM shop_items
        ''');
        
        // 删除旧表
        await db.execute('DROP TABLE shop_items');
        
        // 重命名新表
        await db.execute('ALTER TABLE shop_items_new RENAME TO shop_items');
      } catch (e) {
        print('Error migrating shop_items table: $e');
        // 如果出错，忽略继续
      }
    }
    
    if (oldVersion < 6) {
      // 删除商品类型字段，创建新表并迁移数据
      try {
        // 创建新的shop_items表（不包含type字段）
        await db.execute('''
          CREATE TABLE shop_items_temp(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            icon TEXT DEFAULT '🎁',
            price INTEGER NOT NULL,
            effect TEXT DEFAULT '{}',
            isLimited INTEGER DEFAULT 0,
            limitedUntil TEXT,
            createdBy TEXT DEFAULT 'user',
            createdTime TEXT NOT NULL
          )
        ''');
        
        // 复制现有数据（排除type字段）
        await db.execute('''
          INSERT INTO shop_items_temp (id, name, description, icon, price, effect, isLimited, limitedUntil, createdBy, createdTime)
          SELECT id, name, description, icon, price, effect, isLimited, limitedUntil, createdBy, createdTime
          FROM shop_items
        ''');
        
        // 删除旧表
        await db.execute('DROP TABLE shop_items');
        
        // 重命名新表
        await db.execute('ALTER TABLE shop_items_temp RENAME TO shop_items');
      } catch (e) {
        print('Error migrating shop_items table for type removal: $e');
        // 如果出错，忽略继续
      }
    }
    
    if (oldVersion < 7) {
      // 添加 isRepeatable 字段到 shop_items 表
      try {
        await db.execute('ALTER TABLE shop_items ADD COLUMN isRepeatable INTEGER DEFAULT 1');
      } catch (e) {
        print('Error adding isRepeatable column: $e');
        // 如果字段已存在，忽略错误
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

  // === 商店相关操作 ===
  
  // 保存购买记录
  Future<void> savePurchaseRecord(Map<String, dynamic> record) async {
    final db = await database;
    await db.insert(
      'purchase_records',
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取购买历史
  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    final db = await database;
    return await db.query('purchase_records', where: 'userId = ?', whereArgs: ['current_user']);
  }

  // 更新购买记录
  Future<void> updatePurchaseRecord(Map<String, dynamic> record) async {
    final db = await database;
    await db.update(
      'purchase_records',
      record,
      where: 'id = ?',
      whereArgs: [record['id']],
    );
  }

  // 添加到用户库存
  Future<void> addToInventory(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert(
      'user_inventory',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': 'current_user',
        'itemData': jsonEncode(item),
        'acquiredTime': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取用户库存
  Future<List<Map<String, dynamic>>> getUserInventory() async {
    final db = await database;
    final records = await db.query('user_inventory', where: 'userId = ?', whereArgs: ['current_user']);
    return records.map((record) {
      return jsonDecode(record['itemData'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // 保存激活的增益
  Future<void> saveActiveBoosts(Map<String, DateTime> boosts) async {
    final db = await database;
    
    // 先清除现有的增益
    await db.delete('active_boosts', where: 'userId = ?', whereArgs: ['current_user']);
    
    // 添加新的增益
    for (final entry in boosts.entries) {
      await db.insert('active_boosts', {
        'id': DateTime.now().millisecondsSinceEpoch.toString() + '_' + entry.key,
        'userId': 'current_user',
        'boostType': entry.key,
        'expiryTime': entry.value.toIso8601String(),
      });
    }
  }

  // 获取激活的增益
  Future<Map<String, dynamic>> getActiveBoosts() async {
    final db = await database;
    final records = await db.query('active_boosts', where: 'userId = ?', whereArgs: ['current_user']);
    
    final Map<String, dynamic> boosts = {};
    for (final record in records) {
      boosts[record['boostType'] as String] = record['expiryTime'] as String;
    }
    return boosts;
  }

  // === 商店商品管理 ===
  
  // 添加商店商品
  Future<void> addShopItem(Map<String, dynamic> item) async {
    final db = await database;
    
    // 将effect map转换为JSON字符串
    final itemData = Map<String, dynamic>.from(item);
    itemData['effect'] = jsonEncode(item['effect'] ?? {});
    itemData['createdTime'] = DateTime.now().toIso8601String();
    
    await db.insert(
      'shop_items',
      itemData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print('Shop item saved to database: ${item['name']}');
  }

  // 获取所有商店商品
  Future<List<Map<String, dynamic>>> getShopItems() async {
    final db = await database;
    final records = await db.query('shop_items');
    
    return records.map((record) {
      final item = Map<String, dynamic>.from(record);
      // 将JSON字符串转换回map
      try {
        item['effect'] = jsonDecode(record['effect'] as String? ?? '{}');
      } catch (e) {
        item['effect'] = {};
      }
      return item;
    }).toList();
  }

  // 更新商店商品
  Future<void> updateShopItem(Map<String, dynamic> item) async {
    final db = await database;
    
    final itemData = Map<String, dynamic>.from(item);
    itemData['effect'] = jsonEncode(item['effect'] ?? {});
    
    await db.update(
      'shop_items',
      itemData,
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }

  // 删除商店商品
  Future<void> deleteShopItem(String itemId) async {
    final db = await database;
    await db.delete(
      'shop_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
}
