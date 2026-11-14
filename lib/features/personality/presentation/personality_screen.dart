import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/current_user_provider.dart';
import '../data/personality_draft_store.dart';
import '../data/personality_providers.dart';
import '../domain/personality_profile.dart';
import '../domain/personality_question.dart';
import '../domain/personality_scoring.dart';

class PersonalityScreen extends ConsumerStatefulWidget {
  const PersonalityScreen({super.key});
  @override
  ConsumerState<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends ConsumerState<PersonalityScreen> {
  final _answers = <String, int>{};
  static const _questionsPerSection = 3;
  int _section = 0;
  int get _sectionCount =>
      (personalityQuestions.length / _questionsPerSection).ceil();
  Map<String, int> _savedAnswers = {};
  PersonalityProfile? _profile;
  String? _userId;
  bool _loading = true;
  bool _saving = false;
  bool _leaving = false;
  bool _allowPop = false;
  bool _loadFailed = false;
  bool _storageFailed = false;
  String? _saveError;
  Future<void> _writes = Future.value();

  bool get _dirty => !mapEquals(_answers, _savedAnswers);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final id = await ref.read(currentUserIdProvider.future);
      final profile = await ref
          .read(personalityRepositoryProvider)
          .getForUser(id);
      final draft = await ref.read(personalityDraftStoreProvider).load(id);
      if (!mounted) return;
      final sameSavedVersion = draft?.savedAt == profile?.completedAt;
      // A remote score is not enough to reconstruct individual answers. Never
      // manufacture answers, or silently treat stale device answers as current.
      final hasLocalEdits =
          draft != null && !mapEquals(draft.answers, draft.savedAnswers);
      setState(() {
        _userId = id;
        _profile = profile;
        _savedAnswers = sameSavedVersion ? {...?draft?.savedAnswers} : {};
        _answers
          ..clear()
          ..addAll(
            sameSavedVersion || hasLocalEdits ? {...?draft?.answers} : {},
          );
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _persistDraft() {
    final id = _userId;
    if (id == null) return Future.value();
    final store = ref.read(personalityDraftStoreProvider);
    final snapshot = PersonalityAnswerDraft(
      answers: Map.of(_answers),
      savedAnswers: Map.of(_savedAnswers),
      savedAt: _profile?.completedAt,
    );
    // The store serializes these snapshots with sign-out cleanup as well.
    _writes = store
        .save(id, snapshot)
        .then(
          (_) {
            if (mounted) setState(() => _storageFailed = false);
          },
          onError: (Object _) {
            if (mounted) setState(() => _storageFailed = true);
          },
        );
    return _writes;
  }

  Future<void> _leave() async {
    if (_saving || _leaving) return;
    setState(() => _leaving = true);
    if (_dirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Keep your answers?'),
          content: const Text(
            'You can keep this draft on this device and finish later. '
            'It will not update your social style until you save.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Discard changes'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'keep'),
              child: const Text('Keep draft and leave'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == null) {
        setState(() => _leaving = false);
        return;
      }
      if (choice == 'discard') {
        _answers
          ..clear()
          ..addAll(_savedAnswers);
      }
      await _persistDraft();
      if (!mounted) return;
      if (_storageFailed) {
        setState(() => _leaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "We couldn't keep your draft on this device. Try again before leaving.",
            ),
          ),
        );
        return;
      }
    } else {
      await _writes;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving ||
        _leaving ||
        _userId == null ||
        _answers.length != personalityQuestions.length) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final currentId = await ref.read(currentUserIdProvider.future);
      if (currentId != _userId) throw StateError('Account changed');
      final scored = const PersonalityScoringService().score(
        userId: currentId,
        answers: Map.of(_answers),
      )!;
      final result = await ref
          .read(personalityRepositoryProvider)
          .save(
            PersonalityProfile(
              userId: scored.userId,
              traits: scored.traits,
              version: scored.version,
              completedAt: scored.completedAt,
              visibility: _profile?.visibility ?? scored.visibility,
            ),
          );
      if (!mounted) return;
      _profile = result;
      _savedAnswers = Map.of(_answers);
      await _persistDraft();
      if (!mounted) return;
      ref.invalidate(currentPersonalityProvider);
      if (_storageFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Social style saved. We could not keep a copy of your answers on this device.',
            ),
          ),
        );
      }
      setState(() => _allowPop = true);
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError =
              "We couldn't save your social style. Your answers are still here. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Your social style'),
        leading: BackButton(onPressed: _saving || _leaving ? null : _leave),
        actions: [
          TextButton(
            onPressed: _saving || _leaving ? null : _leave,
            child: const Text('Close'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "We couldn't load your social style and saved draft.",
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              key: ValueKey('section-$_section'),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Optional: 15 questions in 5 short sections. Take your time; there are no right answers.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your answers are kept on this device until you sign out. Only your social-style scores are sent when you save.',
                ),
                if (_profile != null && _savedAnswers.isEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'You already have a saved social style. Previous individual answers are not available on this device. Answer again only if you want to update it.',
                  ),
                ],
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text(
                    'Section ${_section + 1} of $_sectionCount',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                for (
                  var index = _section * _questionsPerSection;
                  index < (_section + 1) * _questionsPerSection &&
                      index < personalityQuestions.length;
                  index++
                )
                  _Question(
                    question: personalityQuestions[index],
                    number: index + 1,
                    value: _answers[personalityQuestions[index].id],
                    onChanged: _saving || _leaving
                        ? null
                        : (value) {
                            setState(() {
                              _answers[personalityQuestions[index].id] = value;
                              _saveError = null;
                            });
                            _persistDraft();
                          },
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (_section > 0)
                      OutlinedButton.icon(
                        onPressed: _saving || _leaving
                            ? null
                            : () => setState(() => _section--),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous section'),
                      ),
                    if (_section < _sectionCount - 1)
                      FilledButton.icon(
                        onPressed: _saving || _leaving
                            ? null
                            : () => setState(() => _section++),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next section'),
                      ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: _loading || _loadFailed
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_storageFailed) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          "We couldn't keep your draft on this device. Your answers are still on this screen.",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _persistDraft,
                        child: const Text('Retry keeping draft'),
                      ),
                    ],
                    Text(
                      '${_answers.length} of ${personalityQuestions.length} answered',
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _answers.length / personalityQuestions.length,
                      semanticsLabel:
                          'Questionnaire progress, ${_answers.length} of ${personalityQuestions.length} answered',
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _saveError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed:
                          _answers.length == personalityQuestions.length &&
                              !_saving &&
                              !_leaving
                          ? _save
                          : null,
                      child: Text(
                        _saving
                            ? 'Saving…'
                            : _saveError != null
                            ? 'Try saving again'
                            : 'Save my answers',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}

class _Question extends StatelessWidget {
  const _Question({
    required this.question,
    required this.number,
    required this.value,
    required this.onChanged,
  });
  final PersonalityQuestion question;
  final int number;
  final int? value;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey(question.id),
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text('$number. ${question.text}')),
        for (var i = 1; i <= 4; i++)
          // ignore: deprecated_member_use
          RadioListTile<int>(
            title: Text(
              [
                'Not like me',
                'A little like me',
                'Somewhat like me',
                'Very much like me',
              ][i - 1],
            ),
            value: i,
            // ignore: deprecated_member_use
            groupValue: value,
            // ignore: deprecated_member_use
            onChanged: onChanged == null
                ? null
                : (value) {
                    if (value != null) onChanged!(value);
                  },
          ),
      ],
    ),
  );
}
