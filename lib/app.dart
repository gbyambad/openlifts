import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/app_bootstrap.dart';
import 'package:openlifts/core/router/app_router.dart';
import 'package:openlifts/core/theme/app_theme.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';

/// Root widget. Configures theme + routing, and gates the UI behind startup
/// seeding (a splash while the bundled data seeds).
class OpenLiftsApp extends ConsumerWidget {
  const OpenLiftsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapProvider);
    return MaterialApp.router(
      title: 'OpenLifts',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider), // defaults to dark until set
      routerConfig: appRouter,
      builder: (context, child) => boot.when(
        data: (_) => child!,
        loading: () => const _Splash(),
        error: (_, __) => const _Splash(failed: true),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.failed = false});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: failed
            ? const Text('Startup failed. Please restart.')
            : const CircularProgressIndicator(),
      ),
    );
  }
}
