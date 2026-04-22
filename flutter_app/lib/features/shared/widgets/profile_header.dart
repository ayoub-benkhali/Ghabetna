import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/admin/models/user_model.dart';

/// Displays the avatar, name, role badge and service badge at the top of
/// every profile screen. Reused by Agent, Supervisor and Admin.
class ProfileHeader extends StatelessWidget {
  final UserModel user;
  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(user.fullName);
    final l = context.l10n;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              initials,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _Badge(label: user.roleName, icon: Icons.shield_outlined),
              if (user.serviceId != null)
                _Badge(
                  label: '${l.services} #${user.serviceId}',
                  icon: Icons.business_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Badge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
