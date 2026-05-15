import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/admin/data/security_repository.dart';

final securitySummaryProvider = FutureProvider.autoDispose<SecuritySummary>((
  ref,
) {
  // Poll every 2 minutes
  final timer = Timer.periodic(const Duration(minutes: 2), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);
  return ref.watch(securityRepositoryProvider).getSummary();
});
