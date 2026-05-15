import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/admin/data/security_repository.dart';

final securityRepositoryProvider = Provider((_) => SecurityRepository());

final securitySummaryProvider = FutureProvider<SecuritySummary>((ref) {
  return ref.watch(securityRepositoryProvider).getSummary();
});
