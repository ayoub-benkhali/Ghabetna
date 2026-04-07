import 'package:flutter_app/features/admin/data/assignment_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final assignmentRepositoryProvider = Provider((_) => AssignmentRepository());
