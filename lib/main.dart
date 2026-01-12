import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'services/services.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/clips/clips_list_screen.dart';
import 'screens/editor/editor_screen.dart';
import 'screens/export/export_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage service
  try {
    await StorageService.initialize();
  } catch (e) {
    debugPrint('Warning: Storage initialization failed: $e');
    // App can still run, but projects won't persist
  }

  // Run the app
  runApp(
    const ProviderScope(
      child: ClipCutApp(),
    ),
  );
}

/// Main application widget
class ClipCutApp extends StatelessWidget {
  const ClipCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClipCut',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // Start with splash screen
      initialRoute: '/',

      // Route configuration
      onGenerateRoute: (settings) {
        Widget page;

        switch (settings.name) {
          case '/':
            page = const SplashScreen();
            break;
          case '/home':
            page = const HomeScreen();
            break;
          case '/clips':
            page = const ClipsListScreen();
            break;
          case '/editor':
            page = const EditorScreen();
            break;
          case '/export':
            page = const ExportScreen();
            break;
          default:
            page = const HomeScreen();
        }

        return MaterialPageRoute(
          builder: (context) => page,
          settings: settings,
        );
      },

      // Error handling for the entire app
      builder: (context, child) {
        // Catch errors and show error widget
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Color(0xFFE57373),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        };

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
