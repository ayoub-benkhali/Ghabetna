import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SupervisorShell extends ConsumerWidget {
  final Widget child;
  const SupervisorShell({super.key, required this.child});

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

List<_NavItem> _buildNavItems(BuildContext context) {
  final l = context.l10n;
  return [
    _NavItem(l.incidents, Icons.list_alt_outlined, '/supervisor/incidents'),
    _NavItem(l.map, Icons.map_outlined, '/supervisor/map'),
    _NavItem(l.chat, Icons.smart_toy_outlined, '/supervisor/chat'),
  ];
}

class _WideLayout extends ConsumerWidget {
  final Widget child;
  const _WideLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(authProvider).user;
    final navItems = _buildNavItems(context);

    // Match active nav item — startsWith handles sub-routes like /supervisor/incidents/42
    final selectedIndex = navItems.indexWhere(
      (n) => location.startsWith(n.route),
    );

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──
          SizedBox(
            width: 240,
            child: Container(
              color: AppColors.sidebarBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo-ghabetna.jpeg',
                          height: 75,
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l.appTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              l.administration,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // User info chip
                  if (user != null)
                    InkWell(
                      onTap: () => context.go('/supervisor/profile'),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.sidebarActive
                                  .withValues(alpha: 0.3),
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.sidebarText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    l.supervisor,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.sidebarText
                                              .withValues(alpha: 0.6),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Divider(
                    color: AppColors.sidebarText.withValues(alpha: 0.1),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      itemCount: navItems.length,
                      itemBuilder: (_, i) {
                        final item = navItems[i];
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

                  // Logout
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
                      l.disconnect,
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
    final l = context.l10n;
    final navItems = _buildNavItems(context);
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = navItems.indexWhere(
      (n) => location.startsWith(n.route),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle), actions: kAppBarActions),
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.sidebarBg,
        indicatorColor: AppColors.sidebarActive,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (i) => context.go(navItems[i].route),
        destinations: navItems
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
      ),
    );
  }
}
