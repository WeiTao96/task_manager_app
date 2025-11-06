import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/profession_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/achievement_provider.dart';
import 'screens/home_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/profession_screen.dart';
import 'screens/profession_form_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/shop_item_form_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/achievement_management_screen.dart';

void main() {
  // 添加全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProfessionProvider()),
        ChangeNotifierProvider(create: (context) => ShopProvider()),
        ChangeNotifierProvider(create: (context) => AchievementProvider()),
        ChangeNotifierProxyProvider3<ProfessionProvider, ShopProvider, AchievementProvider, TaskProvider>(
          create: (context) => TaskProvider(),
          update: (context, professionProvider, shopProvider, achievementProvider, taskProvider) {
            taskProvider?.setProfessionProvider(professionProvider);
            taskProvider?.setShopProvider(shopProvider);
            taskProvider?.setAchievementProvider(achievementProvider);
            return taskProvider!;
          },
        ),
      ],
      child: MaterialApp(
        title: '个人成长RPG系统',
        theme: _buildPixelRPGTheme(),
        home: HomeScreen(),
        routes: {
          TaskFormScreen.routeName: (context) => TaskFormScreen(),
          TaskFormScreen.editRouteName: (context) => TaskFormScreen(),
          ProfessionScreen.routeName: (context) => ProfessionScreen(),
          ProfessionFormScreen.routeName: (context) => ProfessionFormScreen(),
          ProfessionFormScreen.editRouteName: (context) => ProfessionFormScreen(),
          ShopScreen.routeName: (context) => ShopScreen(),
          ShopItemFormScreen.routeName: (context) => ShopItemFormScreen(),
          ShopItemFormScreen.editRouteName: (context) => ShopItemFormScreen(),
          ProfileScreen.routeName: (context) => ProfileScreen(),
          AchievementManagementScreen.routeName: (context) => AchievementManagementScreen(),
        },
      ),
    );
  }

  // 像素风格RPG主题
  ThemeData _buildPixelRPGTheme() {
    const pixelPrimary = Color(0xFF2E4057); // 深蓝灰色
    const pixelSecondary = Color(0xFF048A81); // 青绿色
    const pixelAccent = Color(0xFFFF6B35); // 橙红色
    const pixelDark = Color(0xFF1A1A2E); // 深色
    
    return ThemeData(
      // 基础颜色方案
      primarySwatch: _createMaterialColor(pixelPrimary),
      primaryColor: pixelPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pixelPrimary,
        primary: pixelPrimary,
        secondary: pixelSecondary,
        tertiary: pixelAccent,
        surface: Colors.white,
        error: Color(0xFFB71C1C),
      ),
      
      // 应用栏主题
      appBarTheme: AppBarTheme(
        backgroundColor: pixelPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'monospace', // 像素字体效果
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0), // 保持像素风格的硬边
          ),
        ),
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Colors.white,
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pixelSecondary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // 文本主题
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: pixelDark,
          fontFamily: 'monospace',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: pixelDark,
          fontFamily: 'monospace',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: pixelDark,
          fontFamily: 'monospace',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: pixelDark,
          fontFamily: 'monospace',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: pixelDark,
          fontFamily: 'monospace',
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: pixelPrimary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: pixelPrimary.withOpacity(0.5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: pixelSecondary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(
          color: pixelPrimary,
          fontFamily: 'monospace',
        ),
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontFamily: 'monospace',
        ),
      ),
      
      // 图标主题
      iconTheme: IconThemeData(
        color: pixelPrimary,
        size: 24,
      ),
      
      // 浮动按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: pixelAccent,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // 其他设置
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
    );
  }

  // 创建MaterialColor
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}