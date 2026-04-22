import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/async_value_widget.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';

class ForestListScreen extends ConsumerWidget {
  const ForestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final forestsAsync = ref.watch(forestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.forestManagement), actions: kAppBarActions),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.forest_outlined),
        label: Text(l.newForest),
        onPressed: () => context.go('/admin/forests/new'),
      ),
      body: AsyncValueWidget(
        value: forestsAsync,
        builder: (forests) => forests.isEmpty
            ? const _EmptyState()
            : _ForestGrid(
                forests: forests,
                onRefresh: () => ref.invalidate(forestsProvider),
              ),
      ),
    );
  }
}

// ── Grid layout ───────────────────────────────────────────────────────────────

class _ForestGrid extends StatelessWidget {
  final List<ForestModel> forests;
  final VoidCallback onRefresh;
  const _ForestGrid({required this.forests, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${forests.length} ${l.forests}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              _totalAreaBadge(context, forests),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: forests
                .map((f) => _ForestCard(forest: f, onRefresh: onRefresh))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _totalAreaBadge(BuildContext context, List<ForestModel> forests) {
    final l = context.l10n;
    final total = forests
        .where((f) => f.areaHectares != null)
        .fold<double>(0, (sum, f) => sum + f.areaHectares!);
    if (total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.straighten_outlined,
            color: AppColors.primaryGreen,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '${l.total} : ${total.toStringAsFixed(0)} ${l.ha}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Forest card ───────────────────────────────────────────────────────────────

class _ForestCard extends ConsumerWidget {
  final ForestModel forest;
  final VoidCallback onRefresh;
  const _ForestCard({required this.forest, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hasBoundary = forest.boundaryGeojson != null;

    return SizedBox(
      width: 280,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.darkForest,
                    AppColors.primaryGreen.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.forest, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forest.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (forest.region != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white60,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                forest.region!,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: Colors.white60),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten_outlined,
                        label: forest.areaHectares != null
                            ? '${forest.areaHectares!.toStringAsFixed(1)} ${l.ha}'
                            : l.unknownArea,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: hasBoundary
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        label: hasBoundary ? l.delimited : l.noLimit,
                        color: hasBoundary
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ],
                  ),
                  if (forest.description != null &&
                      forest.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      forest.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.info,
                            side: BorderSide(
                              color: AppColors.info.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.map_outlined, size: 16),
                          label: Text(
                            l.parcelles,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () => context.go(
                            '/admin/forests/${forest.id}/parcelles',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: l.edit,
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          backgroundColor: AppColors.primaryGreen.withValues(
                            alpha: 0.08,
                          ),
                        ),
                        onPressed: () =>
                            context.go('/admin/forests/${forest.id}/edit'),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: l.delete,
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          backgroundColor: AppColors.danger.withValues(
                            alpha: 0.08,
                          ),
                        ),
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${l.delete} "${forest.name}" ?'),
        content: Text(l.deleteForestWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(forestRepositoryProvider).deleteForest(forest.id);
      onRefresh();
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forest_outlined,
            size: 72,
            color: AppColors.primaryGreen.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 20),
          Text(
            l.noForestsRegistered,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l.noForestsHint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            icon: const Icon(Icons.forest_outlined),
            label: Text(l.createForest),
            onPressed: () => context.go('/admin/forests/new'),
          ),
        ],
      ),
    );
  }
}
