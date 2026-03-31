import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child:GhabetnaApp()));
}

class GhabetnaApp extends ConsumerWidget {
  const GhabetnaApp({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final router=ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Ghabetna',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
