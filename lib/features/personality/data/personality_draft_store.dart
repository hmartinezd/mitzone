import 'dart:convert';

import '../../../core/storage/local_storage.dart';
import '../domain/personality_question.dart';

/// Device-local answers, never sent to the personality scoring backend.
/// Keys are account scoped; the account settings flow clears them on sign-out.
class PersonalityDraftStore {
  PersonalityDraftStore(this.storage);
  final LocalStorage storage;
  final _writes = <String, Future<void>>{};

  String _key(String userId) => 'personality_answers.v1.$userId';

  Future<PersonalityAnswerDraft?> load(String userId) async {
    await _writes[userId];
    final raw = await storage.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map || json['version'] != 1) return null;
      return PersonalityAnswerDraft(
        answers: _validAnswers(json['answers']),
        savedAnswers: _validAnswers(json['savedAnswers']),
        savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? ''),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> save(String userId, PersonalityAnswerDraft draft) {
    final payload = jsonEncode({
      'version': 1,
      'answers': draft.answers,
      'savedAnswers': draft.savedAnswers,
      'savedAt': draft.savedAt?.toUtc().toIso8601String(),
    });
    return _write(userId, payload);
  }

  Future<void> clear(String userId) => _write(userId, '');

  // All writes, including sign-out cleanup, share one account-scoped queue.
  // A pending older save therefore cannot recreate a cleared draft.
  Future<void> _write(String userId, String payload) {
    final result = (_writes[userId] ?? Future<void>.value()).then(
      (_) => storage.setString(_key(userId), payload),
    );
    _writes[userId] = result.catchError((Object _) {});
    return result;
  }

  Map<String, int> _validAnswers(dynamic raw) {
    if (raw is! Map) return {};
    return {
      for (final question in personalityQuestions)
        if (raw[question.id] is int &&
            raw[question.id] >= 1 &&
            raw[question.id] <= 4)
          question.id: raw[question.id] as int,
    };
  }
}

class PersonalityAnswerDraft {
  const PersonalityAnswerDraft({
    required this.answers,
    required this.savedAnswers,
    this.savedAt,
  });
  final Map<String, int> answers;
  final Map<String, int> savedAnswers;
  final DateTime? savedAt;
}
