import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/profession_provider.dart';
import 'providers/shop_provider.dart';
import 'screens/home_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/profession_screen.dart';
import 'screens/profession_form_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/shop_item_form_screen.dart';

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
        ChangeNotifierProxyProvider2<ProfessionProvider, ShopProvider, TaskProvider>(
          create: (context) => TaskProvider(),
          update: (context, professionProvider, shopProvider, taskProvider) {
            taskProvider?.setProfessionProvider(professionProvider);
            taskProvider?.setShopProvider(shopProvider);
            return taskProvider!;
          },
        ),
      ],
      child: MaterialApp(
        title: '个人成长RPG系统',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
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
        },
      ),
    );
  }
}