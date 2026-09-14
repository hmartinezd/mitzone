import 'report.dart';

abstract interface class ReportRepository {
  Future<void> submit({required String reportedUserId, required ReportReason reason, String? details});
}
