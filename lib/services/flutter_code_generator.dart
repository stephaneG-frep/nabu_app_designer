import '../models/component_type.dart';
import '../models/project_model.dart';
import '../models/screen_model.dart';
import '../models/ui_component_model.dart';

class FlutterCodeGenerator {
  String generateProjectBundleV2(ProjectModel project) {
    final files = generateProjectFilesV2(project);
    final ordered = files.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ordered
        .map((entry) => '=== ${entry.key} ===\n${entry.value}')
        .join('\n\n');
  }

  String generateProjectBundlePro(ProjectModel project) {
    final files = generateProjectFilesPro(project);
    final ordered = files.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ordered
        .map((entry) => '=== ${entry.key} ===\n${entry.value}')
        .join('\n\n');
  }

  Map<String, String> generateProjectFilesPro(ProjectModel project) {
    if (project.screens.isEmpty) {
      return {'lib/main.dart': _emptyProjectTemplate(project.name)};
    }

    final classByScreenId = <String, String>{};
    final routeByScreenId = <String, String>{};
    final screenImportByScreenId = <String, String>{};

    for (var i = 0; i < project.screens.length; i++) {
      final screen = project.screens[i];
      final fileBase = '${_toSnakeCase(screen.name)}_${i + 1}';
      final className = '${_toPascalCase(screen.name)}Screen${i + 1}';
      final route = '/$fileBase';
      classByScreenId[screen.id] = className;
      routeByScreenId[screen.id] = route;
      screenImportByScreenId[screen.id] = "import '../screens/$fileBase.dart';";
    }

    final files = <String, String>{};

    for (var i = 0; i < project.screens.length; i++) {
      final screen = project.screens[i];
      final className = classByScreenId[screen.id]!;
      final fileName = 'lib/screens/${_toSnakeCase(screen.name)}_${i + 1}.dart';
      files[fileName] =
          "import 'package:flutter/material.dart';\n\n${_generateScreenClass(screen: screen, className: className, routeByScreenId: routeByScreenId)}";
    }

    final screenImports = project.screens
        .map((screen) => screenImportByScreenId[screen.id]!)
        .join('\n');
    final routes = project.screens
        .map(
          (screen) =>
              "    '${routeByScreenId[screen.id]!}': (_) => const ${classByScreenId[screen.id]!}(),",
        )
        .join('\n');
    final initialRoute = routeByScreenId[project.screens.first.id]!;

    files['lib/main.dart'] = '''
import 'app/app.dart';

void main() {
  runApp(const GeneratedApp());
}
''';

    files['lib/app/app.dart'] =
        '''
import 'package:flutter/material.dart';

import '../router/app_router.dart';
import '../theme/app_theme.dart';

class GeneratedApp extends StatelessWidget {
  const GeneratedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '${_escape(project.name)}',
      theme: AppTheme.light,
      initialRoute: AppRouter.initialRoute,
      routes: AppRouter.routes,
    );
  }
}
''';

    files['lib/theme/app_theme.dart'] = '''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2A9D8F));
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
''';

    files['lib/router/app_router.dart'] =
        '''
import 'package:flutter/material.dart';

$screenImports

class AppRouter {
  static const String initialRoute = '$initialRoute';

  static final Map<String, WidgetBuilder> routes = {
$routes
  };
}
''';

    return files;
  }

  Map<String, String> generateProjectFilesV2(ProjectModel project) {
    if (project.screens.isEmpty) {
      return {'lib/main.dart': _emptyProjectTemplate(project.name)};
    }

    final classByScreenId = <String, String>{};
    final routeByScreenId = <String, String>{};

    for (var i = 0; i < project.screens.length; i++) {
      final screen = project.screens[i];
      final className = '${_toPascalCase(screen.name)}Screen${i + 1}';
      final route = '/${_toSnakeCase(screen.name)}_${i + 1}';
      classByScreenId[screen.id] = className;
      routeByScreenId[screen.id] = route;
    }

    final screenImports = <String>[];
    final routes = <String>[];
    final files = <String, String>{};

    for (var i = 0; i < project.screens.length; i++) {
      final screen = project.screens[i];
      final className = classByScreenId[screen.id]!;
      final fileName = 'lib/screens/${_toSnakeCase(screen.name)}_${i + 1}.dart';
      screenImports.add(
        "import 'screens/${_toSnakeCase(screen.name)}_${i + 1}.dart';",
      );
      routes.add(
        "        '${routeByScreenId[screen.id]!}': (_) => const $className(),",
      );
      files[fileName] =
          "import 'package:flutter/material.dart';\n\n${_generateScreenClass(screen: screen, className: className, routeByScreenId: routeByScreenId)}";
    }

    files['lib/main.dart'] =
        '''
import 'package:flutter/material.dart';
${screenImports.join('\n')}

void main() {
  runApp(const Generated${_toPascalCase(project.name)}App());
}

class Generated${_toPascalCase(project.name)}App extends StatelessWidget {
  const Generated${_toPascalCase(project.name)}App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '${_escape(project.name)}',
      initialRoute: '${routeByScreenId[project.screens.first.id]!}',
      routes: {
${routes.join('\n')}
      },
    );
  }
}
''';

    return files;
  }

  String generateProjectCode(ProjectModel project) {
    if (project.screens.isEmpty) {
      return _emptyProjectTemplate(project.name);
    }

    final classByScreenId = <String, String>{};
    final routeByScreenId = <String, String>{};

    for (var i = 0; i < project.screens.length; i++) {
      final screen = project.screens[i];
      final className = '${_toPascalCase(screen.name)}Screen${i + 1}';
      final route = '/${_toSnakeCase(screen.name)}_${i + 1}';
      classByScreenId[screen.id] = className;
      routeByScreenId[screen.id] = route;
    }

    final initialRoute = routeByScreenId[project.screens.first.id]!;
    final routes = project.screens
        .map((screen) {
          final route = routeByScreenId[screen.id]!;
          final className = classByScreenId[screen.id]!;
          return "        '$route': (_) => const $className(),";
        })
        .join('\n');

    final screensCode = project.screens
        .map(
          (screen) => _generateScreenClass(
            screen: screen,
            className: classByScreenId[screen.id]!,
            routeByScreenId: routeByScreenId,
          ),
        )
        .join('\n\n');

    return '''
import 'package:flutter/material.dart';

void main() {
  runApp(const Generated${_toPascalCase(project.name)}App());
}

class Generated${_toPascalCase(project.name)}App extends StatelessWidget {
  const Generated${_toPascalCase(project.name)}App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '${_escape(project.name)}',
      initialRoute: '$initialRoute',
      routes: {
$routes
      },
    );
  }
}

$screensCode
''';
  }

  String _generateScreenClass({
    required ScreenModel screen,
    required String className,
    required Map<String, String> routeByScreenId,
  }) {
    final components = List<UIComponentModel>.from(screen.components);
    UIComponentModel? appBarComponent;

    for (final c in components) {
      if (c.type == ComponentType.appBar) {
        appBarComponent = c;
        break;
      }
    }

    if (appBarComponent != null) {
      components.removeWhere((c) => c.id == appBarComponent!.id);
    }

    final rows = _groupRows(components);
    final rowsCode = rows
        .map(
          (row) => row.length == 1
              ? '              ${_generateComponent(row.first, routeByScreenId)},'
              : '''              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
${row.map((c) => '                    ${_generateComponent(c, routeByScreenId)},').join('\n')}
                  ],
                ),
              ),''',
        )
        .join('\n');

    final bgColor = _hexColor(screen.backgroundColor);
    final appBarCode = appBarComponent == null
        ? ''
        : '''
      appBar: AppBar(
        title: Text('${_escape((appBarComponent.properties['text'] as String?) ?? screen.name)}'),
        backgroundColor: ${_hexColor((appBarComponent.properties['backgroundColor'] as int?) ?? 0xFFE8F4F2)},
        foregroundColor: ${_hexColor((appBarComponent.properties['color'] as int?) ?? 0xFF2A9D8F)},
      ),''';

    return '''
class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
$appBarCode
      backgroundColor: $bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
$rowsCode
            ],
          ),
        ),
      ),
    );
  }
}
''';
  }

  List<List<UIComponentModel>> _groupRows(List<UIComponentModel> components) {
    final rows = <String>[];
    final grouped = <String, List<UIComponentModel>>{};

    for (var i = 0; i < components.length; i++) {
      final component = components[i];
      final row = ((component.properties['row'] as num?) ?? -1).round();
      final key = row >= 0 ? 'row_$row' : 'single_${component.id}_$i';
      if (!grouped.containsKey(key)) {
        rows.add(key);
        grouped[key] = <UIComponentModel>[];
      }
      grouped[key]!.add(component);
    }

    return rows.map((key) => grouped[key]!).toList();
  }

  String _generateComponent(
    UIComponentModel component,
    Map<String, String> routeByScreenId,
  ) {
    final p = component.properties;
    final text = _escape((p['text'] as String?) ?? '');
    final subtitle = _escape((p['subtitle'] as String?) ?? '');
    final color = _hexColor((p['color'] as int?) ?? 0xFF2A9D8F);
    final backgroundColor = _hexColor(
      (p['backgroundColor'] as int?) ?? 0xFFE8F4F2,
    );
    final width = ((p['width'] as num?) ?? 220).toDouble();
    final height = ((p['height'] as num?) ?? 60).toDouble();
    final padding = ((p['padding'] as num?) ?? 12).toDouble();
    final borderRadius = ((p['borderRadius'] as num?) ?? 12).toDouble();
    final fontSize = ((p['fontSize'] as num?) ?? 16).toDouble();
    final borderWidth = ((p['borderWidth'] as num?) ?? 0).toDouble();
    final borderColor = _hexColor((p['borderColor'] as int?) ?? 0xFF2A9D8F);
    final visible = (p['visible'] as bool?) ?? true;
    final margin = ((p['margin'] as num?) ?? 0).toDouble();
    final actionType = (p['actionType'] as String?) ?? 'none';
    final targetScreenId = (p['targetScreenId'] as String?) ?? '';
    final targetRoute = routeByScreenId[targetScreenId];

    if (!visible) {
      return 'const SizedBox.shrink()';
    }

    final actionCode = actionType == 'navigate' && targetRoute != null
        ? "() => Navigator.of(context).pushNamed('$targetRoute')"
        : 'null';

    final decoration =
        '''
decoration: BoxDecoration(
        color: $backgroundColor,
        borderRadius: BorderRadius.circular($borderRadius),
        border: Border.all(color: $borderColor, width: $borderWidth),
      ),''';

    String wrapped(String child) =>
        '''
Padding(
        padding: const EdgeInsets.all($margin),
        child: SizedBox(
          width: $width,
          height: $height,
          child: $child,
        ),
      )''';

    switch (component.type) {
      case ComponentType.text:
        return wrapped('''Container(
      $decoration
      padding: const EdgeInsets.all($padding),
      alignment: Alignment.center,
      child: Text(
        '$text',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: $color,
          fontSize: $fontSize,
        ),
      ),
    )''');
      case ComponentType.button:
        return wrapped('''ElevatedButton(
      onPressed: $actionCode,
      style: ElevatedButton.styleFrom(
        backgroundColor: $backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular($borderRadius),
          side: const BorderSide(color: $borderColor, width: $borderWidth),
        ),
      ),
      child: const Text('$text', style: TextStyle(color: $color)),
    )''');
      case ComponentType.card:
        return wrapped('''Card(
      color: $backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular($borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all($padding),
        child: const Text('$text', style: TextStyle(color: $color)),
      ),
    )''');
      case ComponentType.imagePlaceholder:
        return wrapped('''Container(
      $decoration
      alignment: Alignment.center,
      child: const Icon(Icons.image_rounded, color: $color),
    )''');
      case ComponentType.textField:
        return wrapped('''TextField(
      decoration: InputDecoration(
        labelText: '$text',
        filled: true,
        fillColor: $backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular($borderRadius),
        ),
      ),
    )''');
      case ComponentType.chip:
        return wrapped('''Center(
      child: Chip(
        label: const Text('$text'),
        backgroundColor: $backgroundColor,
      ),
    )''');
      case ComponentType.avatar:
        return wrapped(
          '''Center(child: CircleAvatar(backgroundColor: $backgroundColor, child: const Text('${text.isEmpty ? 'A' : text[0]}')))''',
        );
      case ComponentType.divider:
        return wrapped('const Divider()');
      case ComponentType.icon:
        return wrapped('''Center(
      child: Icon(Icons.star_rounded, color: $color, size: ${fontSize + 20}),
    )''');
      case ComponentType.appBar:
        return 'const SizedBox.shrink()';
      case ComponentType.switchTile:
        return wrapped(
          '''SwitchListTile(value: true, onChanged: (_) {}, title: const Text('$text'))''',
        );
      case ComponentType.checkboxTile:
        return wrapped(
          '''CheckboxListTile(value: true, onChanged: (_) {}, title: const Text('$text'))''',
        );
      case ComponentType.progressBar:
        final progress = ((p['progress'] as num?) ?? 0.6).toDouble();
        return wrapped('''LinearProgressIndicator(
      value: $progress,
      color: $color,
      backgroundColor: ${_withOpacity(color, 0.2)},
    )''');
      case ComponentType.badge:
        return wrapped('''Container(
      $decoration
      alignment: Alignment.center,
      child: const Text('$text', style: TextStyle(color: $color)),
    )''');
      case ComponentType.containerBox:
        return wrapped('''Container(
      $decoration
      alignment: Alignment.center,
      child: const Text('$text'),
    )''');
      case ComponentType.iconButton:
        return wrapped(
          '''IconButton(onPressed: $actionCode, icon: const Icon(Icons.favorite_border_rounded, color: $color))''',
        );
      case ComponentType.floatingActionButton:
        return wrapped(
          '''FloatingActionButton(onPressed: $actionCode, backgroundColor: $backgroundColor, child: const Text('$text'))''',
        );
      case ComponentType.bottomNav:
        return wrapped('''Container(
      $decoration
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [Text('Accueil'), Text('Recherche'), Text('Profil')],
      ),
    )''');
      case ComponentType.tabBar:
        return wrapped('''Container(
      $decoration
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [Text('Tab 1'), Text('Tab 2'), Text('Tab 3')],
      ),
    )''');
      case ComponentType.banner:
        return wrapped('''Container(
      $decoration
      padding: const EdgeInsets.all(8),
      child: const Row(
        children: [Icon(Icons.campaign_rounded), SizedBox(width: 8), Expanded(child: Text('$text'))],
      ),
    )''');
      case ComponentType.statCard:
        return wrapped('''Card(
      child: ListTile(
        title: const Text('$text'),
        subtitle: const Text('$subtitle'),
      ),
    )''');
      case ComponentType.circularProgress:
        final progress = ((p['progress'] as num?) ?? 0.6).toDouble();
        return wrapped('''Center(
      child: CircularProgressIndicator(value: $progress, color: $color),
    )''');
      case ComponentType.sliderControl:
        final progress = ((p['progress'] as num?) ?? 0.5).toDouble();
        return wrapped('''Slider(
      value: $progress,
      onChanged: (_) {},
    )''');
      case ComponentType.radioGroup:
        return wrapped('''Column(
      children: const [
        ListTile(leading: Icon(Icons.radio_button_checked), title: Text('Option A')),
        ListTile(leading: Icon(Icons.radio_button_off), title: Text('Option B')),
      ],
    )''');
      case ComponentType.dropdownField:
        return wrapped('''DropdownButtonFormField<String>(
      initialValue: 'Choix 1',
      items: const [
        DropdownMenuItem(value: 'Choix 1', child: Text('Choix 1')),
        DropdownMenuItem(value: 'Choix 2', child: Text('Choix 2')),
      ],
      onChanged: (_) {},
    )''');
      case ComponentType.listTile:
        return wrapped('''ListTile(
      onTap: $actionCode,
      title: const Text('$text'),
      subtitle: const Text('$subtitle'),
      trailing: const Icon(Icons.chevron_right_rounded),
    )''');
      case ComponentType.searchBar:
        return wrapped('''TextField(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search_rounded),
        hintText: '$text',
      ),
    )''');
      case ComponentType.ratingStars:
        return wrapped('''const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded), Icon(Icons.star_rounded), Icon(Icons.star_rounded),
        Icon(Icons.star_border_rounded), Icon(Icons.star_border_rounded),
      ],
    )''');
    }
  }

  String _emptyProjectTemplate(String name) =>
      '''
import 'package:flutter/material.dart';

void main() {
  runApp(const Generated${_toPascalCase(name)}App());
}

class Generated${_toPascalCase(name)}App extends StatelessWidget {
  const Generated${_toPascalCase(name)}App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Projet vide')),
      ),
    );
  }
}
''';

  String _toPascalCase(String input) {
    final chunks = input
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((c) => c.isNotEmpty)
        .toList();
    if (chunks.isEmpty) {
      return 'Generated';
    }
    return chunks
        .map((c) => '${c[0].toUpperCase()}${c.substring(1).toLowerCase()}')
        .join();
  }

  String _toSnakeCase(String input) {
    final raw = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return raw.isEmpty ? 'screen' : raw;
  }

  String _hexColor(int value) {
    return 'Color(0x${value.toRadixString(16).padLeft(8, '0').toUpperCase()})';
  }

  String _withOpacity(String colorExpr, double opacity) {
    return '$colorExpr.withValues(alpha: $opacity)';
  }

  String _escape(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll(r'$', r'\$')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n');
  }
}
