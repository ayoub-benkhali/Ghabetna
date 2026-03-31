import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/async_value_widget.dart';
import 'package:flutter_app/features/admin/models/service_model.dart';
import 'package:flutter_app/features/admin/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _serviceTypes = [
  'administratif',
  'informatique',
  'juridique',
  'financier',
  'terrain',
];

// Each service type gets a distinct color + icon from AppColors
const _typeConfig = {
  'administratif': (color: AppColors.info, icon: Icons.business_outlined),
  'informatique': (color: AppColors.teal, icon: Icons.computer_outlined),
  'juridique': (color: AppColors.warning, icon: Icons.gavel_outlined),
  'financier': (color: AppColors.sage, icon: Icons.account_balance_outlined),
  'terrain': (color: AppColors.primaryGreen, icon: Icons.terrain_outlined),
};

class ServiceListScreen extends ConsumerWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Services Administratifs')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nouveau service'),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => const _ServiceFormDialog(),
          );
          ref.invalidate(servicesProvider);
        },
      ),
      body: AsyncValueWidget(
        value: servicesAsync,
        builder: (services) => services.isEmpty
            ? _EmptyState(
                onAdd: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => const _ServiceFormDialog(),
                  );
                  ref.invalidate(servicesProvider);
                },
              )
            : _ServiceGrid(
                services: services,
                onRefresh: () => ref.invalidate(servicesProvider),
              ),
      ),
    );
  }
}

class _ServiceGrid extends ConsumerWidget {
  final List<ServiceModel> services;
  final VoidCallback onRefresh;
  const _ServiceGrid({required this.services, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: services
            .map((s) => _ServiceCard(service: s, onRefresh: onRefresh))
            .toList(),
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final ServiceModel service;
  final VoidCallback onRefresh;
  const _ServiceCard({required this.service, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg =
        _typeConfig[service.type] ??
        (color: AppColors.primaryGreen, icon: Icons.folder_outlined);
    final color = cfg.color;
    final icon = cfg.icon;

    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  // Actions
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Modifier',
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => _ServiceFormDialog(service: service),
                      );
                      onRefresh();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    tooltip: 'Supprimer',
                    onPressed: () async {
                      final confirm = await _confirmDelete(
                        context,
                        service.name,
                      );
                      if (confirm == true) {
                        await ref
                            .read(serviceRepositoryProvider)
                            .deleteService(service.id);
                        onRefresh();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                service.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service.type,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (service.description != null &&
                  service.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  service.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer ce service ?'),
        content: Text(
          'Le service "$name" sera supprimé. Les utilisateurs rattachés '
          'n\'auront plus de service assigné.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ServiceFormDialog extends ConsumerStatefulWidget {
  final ServiceModel? service;
  const _ServiceFormDialog({this.service});

  @override
  ConsumerState<_ServiceFormDialog> createState() => _State();
}

class _State extends ConsumerState<_ServiceFormDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'terrain';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameCtrl.text = widget.service!.name;
      _descCtrl.text = widget.service!.description ?? '';
      _type = widget.service!.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.service != null;
    final cfg =
        _typeConfig[_type] ??
        (color: AppColors.primaryGreen, icon: Icons.folder_outlined);

    return AlertDialog(
      title: Text(isEdit ? 'Modifier le service' : 'Nouveau service'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du service *',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 12),
            // Type selector — visual chips instead of plain dropdown
            Text(
              'Type',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _serviceTypes.map((t) {
                final tcfg = _typeConfig[t]!;
                final isSelected = t == _type;
                return ChoiceChip(
                  avatar: Icon(
                    tcfg.icon,
                    size: 16,
                    color: isSelected ? Colors.white : tcfg.color,
                  ),
                  label: Text(t),
                  selected: isSelected,
                  selectedColor: tcfg.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            // Live preview of how the card will look
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(cfg.icon, color: cfg.color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _nameCtrl.text.isEmpty
                          ? 'Nom du service'
                          : _nameCtrl.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEdit ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Le nom est obligatoire')));
      return;
    }
    setState(() => _loading = true);
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      };
      final repo = ref.read(serviceRepositoryProvider);
      widget.service == null
          ? await repo.createService(body)
          : await repo.updateService(widget.service!.id, body);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: AppColors.primaryGreen.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun service créé',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Créez les services administratifs de la Direction\nGénérale des Forêts.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Créer un service'),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
