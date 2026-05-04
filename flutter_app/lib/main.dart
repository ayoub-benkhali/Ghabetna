import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_app/features/auth/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('ar', null);
  usePathUrlStrategy();
  runApp(const ProviderScope(child: GhabetnaApp()));
}

class GhabetnaApp extends ConsumerStatefulWidget {
  const GhabetnaApp({super.key});

  @override
  ConsumerState<GhabetnaApp> createState() => _GhabetnaAppState();
}

class _GhabetnaAppState extends ConsumerState<GhabetnaApp> {
  @override
  void initState() {
    super.initState();
    // Restore saved locale from SharedPreferences
    Future.microtask(() => ref.read(localeProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Ghabetna',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, languageCode: locale.languageCode),
      darkTheme: buildTheme(Brightness.dark, languageCode: locale.languageCode),
      themeMode: ThemeMode.system,
      routerConfig: router,

      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
