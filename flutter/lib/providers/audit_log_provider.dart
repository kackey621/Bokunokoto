import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log.dart';
import 'api_client_provider.dart';
import 'auth_provider.dart';

/// Fetches the most recent audit log entries for the user's active vault.
/// Returns an empty list when the user has no vault yet (server replies 409
/// "active_vault_required") so the UI can show an empty state instead of an
/// error.
final auditLogProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final bkUser = ref.watch(authNotifierProvider).bkUser;
  if (bkUser == null || !bkUser.hasVault) return const [];

  final dio = ref.watch(apiClientProvider);
  try {
    final response = await dio.get(
      '/my/audit_logs',
      queryParameters: {'limit': 20},
    );
    final data = response.data as Map<String, dynamic>;
    final logs = (data['audit_logs'] as List?) ?? const [];
    return logs
        .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    if (e.response?.statusCode == 409) return const [];
    rethrow;
  }
});
