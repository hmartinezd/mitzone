import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_providers.dart';
import '../domain/report_repository.dart';
import 'supabase_report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => SupabaseReportRepository(Supabase.instance.client));
