import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/theme.dart';
import 'providers/settings_provider.dart';

void main() {
  // Catch all uncaught Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[NovelShift] FlutterError: ${details.exception}');
  };

  // Catch errors from platform channels
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[NovelShift] PlatformError: $error\n$stack');
    return true; // handled
  };

  // Catch all uncaught async errors (prevents "Lost connection to device" crash)
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const ProviderScope(child: NovelShiftApp()));
  }, (error, stackTrace) {
    debugPrint('[NovelShift] Uncaught async error: $error\n$stackTrace');
  });
}

class NovelShiftApp extends ConsumerWidget {
  const NovelShiftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingTheme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'NovelShift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(readingTheme),
      routerConfig: appRouter,
    );
  }
}
