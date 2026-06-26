import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/realtime_service.dart';

late ProviderContainer _container;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize Local Notifications
  await LocalNotificationService.init();

  // Create a global ProviderContainer so we can start realtime
  _container = ProviderContainer();

  // Start global realtime listener immediately
  try {
    _container.read(realtimeServiceProvider).start();
    debugPrint('✅ [MAIN] Realtime service started successfully');
  } catch (e) {
    debugPrint('❌ [MAIN] Failed to start realtime service: $e');
  }

  runApp(UncontrolledProviderScope(
    container: _container,
    child: const MaautsApp(),
  ));
}

class MaautsApp extends ConsumerWidget {
  const MaautsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'E-Ticketing Helpdesk',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
