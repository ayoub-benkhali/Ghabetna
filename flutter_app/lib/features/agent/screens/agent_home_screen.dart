import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AgentHomeScreen extends ConsumerWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: l.myProfile,
            onPressed: () => context.push('/agent/profile'),
          ),
          ...kAppBarActions,
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: l.disconnect,
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar circle with gradient
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(l.welcome, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                user?.fullName ?? '',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Image.asset(
                'assets/images/agent_home_screen.png',
                height: 280,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.push('/agent/report'),
                icon: const Icon(Icons.add_alert),
                label: Text(l.reportIncident),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/agent/incidents'),
                icon: const Icon(Icons.list_alt),
                label: Text(l.myReports),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
