import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/auth/providers/locale_provider.dart';

class LanguageToggle extends ConsumerWidget {
  /// compact = icon-only for AppBar; compact=false = full tile for sidebar
  final bool compact;
  const LanguageToggle({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isFr = locale.languageCode == 'fr';

    if (compact) {
      return IconButton(
        icon: const Icon(Icons.language),
        tooltip: isFr ? 'العربية' : 'Français',
        onPressed: () => ref.read(localeProvider.notifier).toggle(),
      );
    }

    // Full sidebar tile version
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.language,
        color: AppColors.sidebarText.withValues(alpha: 0.7),
        size: 20,
      ),
      title: Text(
        isFr ? 'العربية' : 'Français',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.sidebarText),
      ),
      trailing: Text(
        isFr ? 'FR→ع' : 'ع→FR',
        style: TextStyle(
          color: AppColors.sidebarText.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      ),
      onTap: () => ref.read(localeProvider.notifier).toggle(),
    );
  }
}
