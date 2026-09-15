import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'observability.dart';

final observabilityProvider = Provider<AnalyticsReporter>((ref) => const NoopAnalyticsReporter());
