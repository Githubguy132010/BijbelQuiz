import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io' show Platform;
import 'package:provider/single_child_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart' show Level;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/bible_provider.dart';
import 'utils/theme_utils.dart';
import 'services/logger.dart';
import 'services/bible_service.dart';
import 'services/connection_service.dart';
import 'services/offline_bible_service.dart';
import 'services/download_service.dart';
import 'screens/main_navigation_screen.dart';
import 'l10n/strings_nl.dart' as strings;

final bibleService = BibleService();

/// The main entry point of the BijbelRead application with performance optimizations.
void main() async {
  // Ensure that the Flutter binding is initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for desktop platforms
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    AppLogger.info('Initializing SQLite for desktop platform...');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppLogger.info('SQLite FFI initialized successfully');
  }

  // Initialize logging first
  AppLogger.init(level: Level.ALL);
  AppLogger.info('BijbelRead app starting up...');
  AppLogger.info('Logger initialized successfully');

  // Set preferred screen orientations. On web, this helps maintain a consistent layout.
  if (kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Initialize services
  final connectionService = ConnectionService();
  final offlineBibleService = OfflineBibleService();
  final downloadService = DownloadService(bibleService, offlineBibleService, connectionService);

  final bibleProvider = BibleProvider(bibleService, offlineBibleService, downloadService, connectionService);
  AppLogger.info('Bible provider initialized with offline support');

  AppLogger.info('Starting Flutter app with providers...');
  final appStartTime = DateTime.now();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: bibleProvider),
        Provider.value(value: bibleService),
        Provider.value(value: connectionService),
        Provider.value(value: offlineBibleService),
        Provider.value(value: downloadService),
      ],
      child: BijbelReadApp(),
    ),
  );
  final appStartDuration = DateTime.now().difference(appStartTime);
  AppLogger.info('Flutter app started successfully in ${appStartDuration.inMilliseconds}ms');
}

class BijbelReadApp extends StatefulWidget {
  const BijbelReadApp({super.key});

  @override
  State<BijbelReadApp> createState() => _BijbelReadAppState();
}

class _BijbelReadAppState extends State<BijbelReadApp> {
  ConnectionService? _connectionService;

  // Add mounted getter for older Flutter versions
  @override
  bool get mounted => _mounted;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    AppLogger.info('BijbelReadApp state initializing...');

    // Defer service initialization; don't block first render
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppLogger.info('Starting deferred service initialization...');
      final connectionService = ConnectionService();

      // Initialize connection service
      AppLogger.info('Initializing connection service...');
      await connectionService.initialize().catchError((e) {
        AppLogger.warning('Connection service initialization failed: $e');
        // Don't fail the entire app if connection service fails
        return null;
      });

      // Expose services immediately so UI can build without waiting
      AppLogger.info('Exposing services to providers...');
      setState(() {
        _connectionService = connectionService;
      });

      AppLogger.info('All services initialized successfully');
    });
  }

  /// Builds the MaterialApp with theme configuration
  Widget _buildMaterialApp() {
    return MaterialApp(
      title: strings.AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeUtils.getLightTheme(),
      darkTheme: ThemeUtils.getDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('nl', ''), // Dutch
      ],
      locale: const Locale('nl', ''), // Force Dutch locale
      home: const MainNavigationScreen(),
    );
  }

  /// Gets deferred providers that are ready
  List<SingleChildWidget> _getDeferredProviders() {
    return [
      if (_connectionService != null) Provider.value(value: _connectionService!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final app = _buildMaterialApp();
    final deferredProviders = _getDeferredProviders();

    return deferredProviders.isNotEmpty
        ? MultiProvider(providers: deferredProviders, child: app)
        : app;
  }

  @override
  void dispose() {
    AppLogger.info('BijbelReadApp disposing...');
    _mounted = false;
    _connectionService?.dispose();
    AppLogger.info('BijbelReadApp disposed successfully');
    super.dispose();
  }
}
