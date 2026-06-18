import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/theme.dart';
import 'providers/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NovelShiftApp()));
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
