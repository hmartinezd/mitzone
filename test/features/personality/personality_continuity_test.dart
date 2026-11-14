import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/features/personality/data/personality_draft_store.dart';
import 'package:mitzone/features/personality/data/personality_providers.dart';
import 'package:mitzone/features/personality/data/personality_repository.dart';
import 'package:mitzone/features/personality/domain/personality_profile.dart';
import 'package:mitzone/features/personality/domain/personality_question.dart';
import 'package:mitzone/features/personality/presentation/personality_screen.dart';

import '../../support/memory_local_storage.dart';

class _Repository implements PersonalityRepository {
  PersonalityProfile? profile;
  bool failLoad = false;
  bool failSave = false;
  int saves = 0;
  Completer<void>? pendingSave;
  @override
  Future<PersonalityProfile?> getForUser(String userId) async {
    if (failLoad) throw StateError('unavailable');
    return profile;
  }

  @override
  Future<PersonalityProfile> save(PersonalityProfile value) async {
    saves++;
    await pendingSave?.future;
    if (failSave) throw StateError('unavailable');
    return profile = value;
  }

  @override
  Future<Map<String, double>> getCompatibilityWith(Set<String> ids) async => {};
}

class _FailingStorage extends MemoryLocalStorage {
  bool fail = true;
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('disk full');
    await super.setString(key, value);
  }
}

class _DelayedStorage extends MemoryLocalStorage {
  final gate = Completer<void>();
  bool first = true;
  @override
  Future<void> setString(String key, String value) async {
    if (first) {
      first = false;
      await gate.future;
    }
    await super.setString(key, value);
  }
}

Widget _app(
  _Repository repo,
  PersonalityDraftStore drafts, {
  String id = 'alice',
  double scale = 1,
}) => ProviderScope(
  overrides: [
    currentUserIdProvider.overrideWith((ref) async => id),
    personalityRepositoryProvider.overrideWithValue(repo),
    personalityDraftStoreProvider.overrideWithValue(drafts),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const PersonalityScreen(),
              ),
            ),
            child: const Text('Open questionnaire'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open questionnaire'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'device drafts roundtrip, isolate accounts, clear and filter corrupt values',
    () async {
      final storage = MemoryLocalStorage();
      final store = PersonalityDraftStore(storage);
      final at = DateTime.utc(2026);
      await store.save(
        'alice',
        PersonalityAnswerDraft(
          answers: {'o1': 2},
          savedAnswers: {},
          savedAt: at,
        ),
      );
      expect((await store.load('alice'))!.answers, {'o1': 2});
      expect((await store.load('alice'))!.savedAt, at);
      expect(await store.load('bob'), isNull);
      await store.clear('alice');
      expect(await store.load('alice'), isNull);
      await storage.setString('personality_answers.v1.alice', '{bad json');
      expect(await store.load('alice'), isNull);
      await storage.setString(
        'personality_answers.v1.alice',
        '{"version":1,"answers":{"o1":9,"o2":2,"bogus":1,"o3":"3"}}',
      );
      expect((await store.load('alice'))!.answers, {'o2': 2});
    },
  );

  test('clear is ordered after pending draft writes', () async {
    final storage = _DelayedStorage();
    final store = PersonalityDraftStore(storage);
    final write = store.save(
      'alice',
      const PersonalityAnswerDraft(answers: {'o1': 2}, savedAnswers: {}),
    );
    final clear = store.clear('alice');
    storage.gate.complete();
    await Future.wait([write, clear]);
    expect(await store.load('alice'), isNull);
  });

  testWidgets('sections retain answers when moving forward and back', (
    tester,
  ) async {
    final store = PersonalityDraftStore(MemoryLocalStorage());
    await tester.pumpWidget(_app(_Repository(), store));
    await _open(tester);
    final first = find.byType(RadioListTile<int>).first;
    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Next section'), 250);
    await tester.tap(find.text('Next section'));
    await tester.pumpAndSettle();
    expect(find.text('Section 2 of 5'), findsOneWidget);
    expect(find.text('1 of 15 answered'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Previous section'), 250);
    await tester.tap(find.text('Previous section'));
    await tester.pumpAndSettle();
    expect(find.text('Section 1 of 5'), findsOneWidget);
    expect(
      tester
          .widget<RadioListTile<int>>(find.byType(RadioListTile<int>).first)
          // ignore: deprecated_member_use
          .groupValue,
      1,
    );
    expect((await store.load('alice'))!.answers, {'o1': 1});
  });

  testWidgets('failed device storage preserves editing and supports retry', (
    tester,
  ) async {
    final storage = _FailingStorage();
    final store = PersonalityDraftStore(storage);
    await tester.pumpWidget(_app(_Repository(), store));
    await _open(tester);
    final firstRadio = find.byType(RadioListTile<int>).first;
    await tester.ensureVisible(firstRadio);
    await tester.tap(firstRadio);
    await tester.pumpAndSettle();
    expect(find.text('1 of 15 answered'), findsOneWidget);
    expect(find.textContaining("We couldn't keep your draft"), findsOneWidget);
    storage.fail = false;
    final retry = find.text('Retry keeping draft');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect((await store.load('alice'))!.answers, {'o1': 1});
    expect(find.textContaining("We couldn't keep your draft"), findsNothing);
  });

  testWidgets(
    'preloads local draft and progress, keeps it on close and reopen',
    (tester) async {
      final store = PersonalityDraftStore(MemoryLocalStorage());
      await store.save(
        'alice',
        const PersonalityAnswerDraft(answers: {'o1': 2}, savedAnswers: {}),
      );
      await tester.pumpWidget(_app(_Repository(), store));
      await _open(tester);
      expect(find.text('1 of 15 answered'), findsOneWidget);
      final radio = tester.widget<RadioListTile<int>>(
        find.byType(RadioListTile<int>).first,
      );
      // ignore: deprecated_member_use
      expect(radio.groupValue, 2);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep draft and leave'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalityScreen), findsNothing);
      await _open(tester);
      expect(find.text('1 of 15 answered'), findsOneWidget);
    },
  );

  testWidgets(
    'discard restores saved answers rather than deleting saved style',
    (tester) async {
      final store = PersonalityDraftStore(MemoryLocalStorage());
      await store.save(
        'alice',
        const PersonalityAnswerDraft(answers: {'o1': 2}, savedAnswers: {}),
      );
      await tester.pumpWidget(_app(_Repository(), store));
      await _open(tester);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect((await store.load('alice'))!.answers, isEmpty);
      await _open(tester);
      expect(find.text('0 of 15 answered'), findsOneWidget);
    },
  );

  testWidgets('prior aggregate score does not fabricate old answers', (
    tester,
  ) async {
    final repo = _Repository()
      ..profile = PersonalityProfile(
        userId: 'alice',
        traits: {PersonalityTrait.openness: .5},
        version: 1,
        completedAt: DateTime.utc(2026),
      );
    await tester.pumpWidget(
      _app(repo, PersonalityDraftStore(MemoryLocalStorage())),
    );
    await _open(tester);
    expect(
      find.textContaining('Previous individual answers are not available'),
      findsOneWidget,
    );
    expect(find.text('0 of 15 answered'), findsOneWidget);
  });

  testWidgets('load error has retry and does not overwrite stored draft', (
    tester,
  ) async {
    final repo = _Repository()..failLoad = true;
    final store = PersonalityDraftStore(MemoryLocalStorage());
    await store.save(
      'alice',
      const PersonalityAnswerDraft(answers: {'o1': 2}, savedAnswers: {}),
    );
    await tester.pumpWidget(_app(repo, store));
    await _open(tester);
    expect(
      find.text("We couldn't load your social style and saved draft."),
      findsOneWidget,
    );
    repo.failLoad = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 15 answered'), findsOneWidget);
  });

  testWidgets(
    'save failure retains answers, prevents double submission, retry saves and reopens',
    (tester) async {
      final repo = _Repository()
        ..failSave = true
        ..pendingSave = Completer<void>();
      final store = PersonalityDraftStore(MemoryLocalStorage());
      final answers = {for (final q in personalityQuestions) q.id: 2};
      await store.save(
        'alice',
        PersonalityAnswerDraft(answers: answers, savedAnswers: {}),
      );
      await tester.pumpWidget(_app(repo, store));
      await _open(tester);
      await tester.tap(find.text('Save my answers'));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Saving…'))
            .onPressed,
        isNull,
      );
      expect(repo.saves, 1);
      repo.pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your answers are still here'),
        findsOneWidget,
      );
      expect(find.text('15 of 15 answered'), findsOneWidget);
      repo
        ..pendingSave = null
        ..failSave = false;
      await tester.tap(find.text('Try saving again'));
      await tester.pumpAndSettle();
      expect(repo.saves, 2);
      expect(find.byType(PersonalityScreen), findsNothing);
      expect((await store.load('alice'))!.savedAnswers, answers);
      await _open(tester);
      expect(find.text('15 of 15 answered'), findsOneWidget);
      expect(
        find.textContaining('Previous individual answers are not available'),
        findsNothing,
      );
    },
  );

  testWidgets('updating answers preserves existing matching visibility', (
    tester,
  ) async {
    final at = DateTime.utc(2026);
    final repo = _Repository()
      ..profile = PersonalityProfile(
        userId: 'alice',
        traits: {},
        version: 1,
        completedAt: at,
        visibility: 'matching',
      );
    final store = PersonalityDraftStore(MemoryLocalStorage());
    await store.save(
      'alice',
      PersonalityAnswerDraft(
        answers: {for (final question in personalityQuestions) question.id: 3},
        savedAnswers: {},
        savedAt: at,
      ),
    );
    await tester.pumpWidget(_app(repo, store));
    await _open(tester);
    await tester.tap(find.text('Save my answers'));
    await tester.pumpAndSettle();
    expect(repo.profile!.visibility, 'matching');
  });

  testWidgets('a newer remote score does not preload stale saved answers', (
    tester,
  ) async {
    final repo = _Repository()
      ..profile = PersonalityProfile(
        userId: 'alice',
        traits: {},
        version: 1,
        completedAt: DateTime.utc(2026, 11),
      );
    final store = PersonalityDraftStore(MemoryLocalStorage());
    await store.save(
      'alice',
      PersonalityAnswerDraft(
        answers: const {'o1': 2},
        savedAnswers: const {'o1': 2},
        savedAt: DateTime.utc(2026),
      ),
    );
    await tester.pumpWidget(_app(repo, store));
    await _open(tester);
    expect(find.text('0 of 15 answered'), findsOneWidget);
    expect(
      find.textContaining('Previous individual answers are not available'),
      findsOneWidget,
    );
  });

  testWidgets('large text retains progress and action without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(822, 1828);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        _Repository(),
        PersonalityDraftStore(MemoryLocalStorage()),
        scale: 2,
      ),
    );
    await _open(tester);
    expect(find.text('0 of 15 answered'), findsOneWidget);
    expect(find.text('Save my answers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
