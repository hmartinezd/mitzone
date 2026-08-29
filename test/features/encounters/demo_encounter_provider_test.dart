import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/identity/mock_identity_repository.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/domain/event_check_in.dart';

void main() {
  test(
    'fresh demo check-in immediately uses simulated elapsed presence',
    () async {
      final checkedInAt = DateTime.utc(2028, 2, 10, 18);
      final container = ProviderContainer(
        overrides: [
          utcNowProvider.overrideWithValue(() => checkedInAt),
          eventCheckInsProvider.overrideWithValue(
            AsyncValue.data([
              EventCheckIn(
                eventId: 'urban-art-opening',
                identityId: MockUsers.joseId,
                checkedInAt: checkedInAt,
                method: EventCheckInMethod.localDemo,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final encounters = await container.read(
        encountersForCurrentUserProvider.future,
      );

      expect(
        encounters.map((item) => item.otherUserId),
        containsAll([MockUsers.sofiaId, MockUsers.emmaId]),
      );
      expect(
        encounters
            .singleWhere((item) => item.otherUserId == MockUsers.sofiaId)
            .overlapDuration,
        const Duration(minutes: 45),
      );
      expect(
        encounters
            .singleWhere((item) => item.otherUserId == MockUsers.emmaId)
            .overlapDuration,
        const Duration(minutes: 15),
      );
      expect(
        encounters.any((item) => item.otherUserId == MockUsers.danielId),
        isFalse,
      );
      expect(
        encounters.every((item) => item.overlapStart.year == 2028),
        isTrue,
      );
    },
  );
}
