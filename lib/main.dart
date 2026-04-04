import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/project_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.instance.init();

  runApp(const NabuAppDesignerApp());
}

class NabuAppDesignerApp extends StatelessWidget {
  const NabuAppDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ProjectProvider(LocalStorageService.instance)..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Nabu App Designer',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.theme,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
