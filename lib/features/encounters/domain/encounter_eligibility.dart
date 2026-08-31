import '../../../core/errors/domain_error.dart';
import '../../blocking/domain/block_repository.dart';
import 'encounter.dart';

enum EncounterEligibility { visible, actionable, unavailable }

/// Small, storage-neutral safety boundary shared by encounter presentation
/// and future interaction commands.
class EncounterEligibilityPolicy {
  const EncounterEligibilityPolicy(this.blocks);
  final BlockRepository blocks;

  Future<EncounterEligibility> evaluate(Encounter encounter) async {
    if (encounter.currentUserId == encounter.otherUserId ||
        encounter.overlapEnd.isBefore(DateTime.now().toUtc())) {
      return EncounterEligibility.unavailable;
    }
    try {
      if (await blocks.isPairBlocked(
        encounter.currentUserId,
        encounter.otherUserId,
      )) {
        return EncounterEligibility.unavailable;
      }
      return EncounterEligibility.actionable;
    } catch (_) {
      // Safety-sensitive decisions fail closed.
      return EncounterEligibility.unavailable;
    }
  }

  Future<void> requireActionable(Encounter encounter) async {
    if (await evaluate(encounter) != EncounterEligibility.actionable) {
      throw const DomainError(
        DomainErrorCode.interactionUnavailable,
        'This interaction is unavailable',
      );
    }
  }
}
