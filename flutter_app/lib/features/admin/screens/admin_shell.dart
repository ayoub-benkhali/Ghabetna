import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return isWide ? _WideLayout(child: child) : _NarrowLayout(child: child);
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

const _navItems = [
  _NavItem('Tableau de bord', Icons.dashboard_outlined, '/admin/dashboard'),
  _NavItem('Forêts', Icons.forest_outlined, '/admin/forests'),
  _NavItem('Utilisateurs', Icons.people_outline, '/admin/users'),
  _NavItem('Rôles', Icons.shield_outlined, '/admin/roles'),
  _NavItem('Services', Icons.account_tree_outlined, '/admin/services'),
  _NavItem('Profil', Icons.person_outline, '/admin/profile'),
];

class _WideLayout extends ConsumerWidget {
  final Widget child;
  const _WideLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _navItems.indexWhere(
      (n) => location.startsWith(n.route),
    );

    return Scaffold(
      body: Row(
        children: [
          // ── Custom sidebar using sidebarBg / sidebarActive / sidebarText ──
          SizedBox(
            width: 240,
            child: Container(
              color: AppColors.sidebarBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / brand area with gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.forest, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Ghabetna',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          'Administration',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nav items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      itemCount: _navItems.length,
                      itemBuilder: (_, i) {
                        final item = _navItems[i];
                        final isActive = i == selectedIndex;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.sidebarActive
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              item.icon,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.sidebarText.withValues(
                                      alpha: 0.7,
                                    ),
                              size: 20,
                            ),
                            title: Text(
                              item.label,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.sidebarText,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                            onTap: () => context.go(item.route),
                          ),
                        );
                      },
                    ),
                  ),
                  // Divider + Logout
                  Divider(
                    color: AppColors.sidebarText.withValues(alpha: 0.15),
                    height: 1,
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    leading: Icon(
                      Icons.logout,
                      color: AppColors.sidebarText.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    title: Text(
                      'Déconnexion',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.sidebarText.withValues(alpha: 0.7),
                      ),
                    ),
                    onTap: () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ),
          // ── Content area ──
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  final Widget child;
  const _NarrowLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghabetna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.sidebarBg,
        indicatorColor: AppColors.sidebarActive,
        destinations: _navItems
            .map(
              (n) => NavigationDestination(
                icon: Icon(
                  n.icon,
                  color: AppColors.sidebarText.withValues(alpha: 0.6),
                ),
                selectedIcon: Icon(n.icon, color: Colors.white),
                label: n.label,
              ),
            )
            .toList(),
        onDestinationSelected: (i) => context.go(_navItems[i].route),
      ),
    );
  }
}
