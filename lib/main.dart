import 'package:flutter/material.dart';
import 'logic/star_manager.dart';
import 'logic/theme_manager.dart';
import 'models/theme_model.dart';
import 'screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StarManager.init();
  await ThemeManager.init(); // Tema yöneticisini başlatıyoruz
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'Sudoku Game',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: currentTheme.primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: currentTheme.primaryColor,
              primary: currentTheme.primaryColor,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: currentTheme.backgroundColor,
          ),
          home: const MainMenuScreen(),
        );
      },
    );
  }
}