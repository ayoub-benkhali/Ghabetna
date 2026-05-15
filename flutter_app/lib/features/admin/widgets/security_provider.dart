import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/admin/providers/security_provider.dart';
import 'package:flutter_app/features/admin/data/security_repository.dart';
import 'package:intl/intl.dart';

class SecurityCard extends ConsumerWidget {
  const SecurityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(securitySummaryProvider);

    return summary.when(
      loading: () => const _SecurityCardShell(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _SecurityCardShell(
        child: Center(child: Text('Security data unavailable')),
      ),
      data: (s) => _SecurityCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.security, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _ThreatBadge(level: s.threatLevel),
              ],
            ),
            const SizedBox(height: 16),

            // ── Active alerts list ──────────────────────────────
            if (s.activeAlerts.isEmpty)
              Text(
                'No alerts in the last 24 hours.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...s.activeAlerts.map((a) => _AlertRow(alert: a)),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // ── AI Summary box ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.smart_toy_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI Summary',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.summaryText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last updated ${DateFormat('HH:mm').format(s.generatedAt.toLocal())}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SecurityCardShell extends StatelessWidget {
  final Widget child;
  const _SecurityCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _ThreatBadge extends StatelessWidget {
  final String level;
  const _ThreatBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      _ => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final SecurityAlert alert;
  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      _ => Colors.blue,
    };
    final icon = switch (alert.alertType) {
      'brute_force' => '🔴',
      'off_hours_admin_login' => '🟡',
      _ => '🔵',
    };
    final label = switch (alert.alertType) {
      'brute_force' => 'Brute force',
      'off_hours_admin_login' => 'Off-hours login',
      _ => alert.alertType.replaceAll('_', ' '),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label${alert.ip != null ? " — ${alert.ip}" : ""}${alert.detail != null ? " — ${alert.detail}" : ""}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('HH:mm').format(alert.firedAt.toLocal()),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
