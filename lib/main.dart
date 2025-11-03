import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/profession_provider.dart';
import 'screens/home_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/profession_screen.dart';
import 'screens/profession_form_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProfessionProvider()),
        ChangeNotifierProxyProvider<ProfessionProvider, TaskProvider>(
          create: (context) => TaskProvider(),
          update: (context, professionProvider, taskProvider) {
            taskProvider?.setProfessionProvider(professionProvider);
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
        },
      ),
    );
  }
}