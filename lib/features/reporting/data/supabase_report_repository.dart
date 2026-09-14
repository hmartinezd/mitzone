import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/report.dart';
import '../domain/report_repository.dart';

class SupabaseReportRepository implements ReportRepository {
  const SupabaseReportRepository(this.client);
  final SupabaseClient client;
  @override
  Future<void> submit({required String reportedUserId, required ReportReason reason, String? details}) async {
    final reporter = client.auth.currentUser?.id;
    if (reporter == null || reporter == reportedUserId) throw StateError('Invalid report subject');
    final value = details?.trim();
    if (value != null && value.length > 500) throw ArgumentError('Report details are too long');
    await client.from('reports').insert({
      'reporter_user_id': reporter,
      'reported_user_id': reportedUserId,
      'reason': reason.name,
      'details': value?.isEmpty == true ? null : value,
    });
  }
}
