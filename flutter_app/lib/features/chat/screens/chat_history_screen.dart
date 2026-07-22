import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class _ConversationSummary {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;

  _ConversationSummary({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory _ConversationSummary.fromJson(Map<String, dynamic> json) {
    return _ConversationSummary(
      id: json['id'],
      title: json['title'],
      lastMessage: json['last_message'] ?? '',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Liste des conversations passées avec le chatbot, pour un rôle donné
/// (ex: /agent/chat, /admin/chat, /supervisor/chat). Permet de rouvrir
/// une ancienne conversation ou d'en démarrer une nouvelle.
class ChatHistoryScreen extends StatefulWidget {
  final String basePath;

  const ChatHistoryScreen({super.key, required this.basePath});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<_ConversationSummary>? _conversations;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await ApiClient.instance.dio.get('/api/chat/conversations');
      final list = (response.data as List)
          .map((e) => _ConversationSummary.fromJson(e))
          .toList();
      setState(() {
        _conversations = list;
        _isLoading = false;
      });
    } on DioException {
      setState(() {
        _error = 'Impossible de charger l\'historique.';
        _isLoading = false;
      });
    }
  }

  Future<void> _delete(_ConversationSummary conv) async {
    try {
      await ApiClient.instance.dio
          .delete('/api/chat/conversations/${conv.id}');
      setState(() {
        _conversations?.removeWhere((c) => c.id == conv.id);
      });
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression.')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday = now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
    if (isToday) {
      return DateFormat.Hm('fr').format(date.toLocal());
    }
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.chatHistoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: l.chatNewConversation,
            onPressed: () => context.go(widget.basePath),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(l, theme),
      ),
    );
  }

  Widget _buildBody(dynamic l, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Center(child: Text(_error!)),
        ],
      );
    }

    final conversations = _conversations ?? [];

    if (conversations.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.forum_outlined,
              size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Center(child: Text(l.chatHistoryEmpty)),
        ],
      );
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return Dismissible(
          key: ValueKey(conv.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: theme.colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _delete(conv),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.forest, color: Colors.white, size: 18),
            ),
            title: Text(
              conv.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              conv.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _formatDate(conv.updatedAt),
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            onTap: () => context.push('${widget.basePath}/${conv.id}'),
          ),
        );
      },
    );
  }
}
