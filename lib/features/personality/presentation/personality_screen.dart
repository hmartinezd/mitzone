import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/current_user_provider.dart';
import '../data/personality_providers.dart';
import '../domain/personality_question.dart';
import '../domain/personality_scoring.dart';

class PersonalityScreen extends ConsumerStatefulWidget { const PersonalityScreen({super.key}); @override ConsumerState<PersonalityScreen> createState() => _PersonalityScreenState(); }
class _PersonalityScreenState extends ConsumerState<PersonalityScreen> {
  final answers = <String, int>{};
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Your social style'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip'))]), body: ListView(padding: const EdgeInsets.all(16), children: [const Text('A few friendly questions can help you discover people with a similar social style. There are no right answers.'), const SizedBox(height: 20), for (final question in personalityQuestions) _Question(question: question, value: answers[question.id], onChanged: (value) => setState(() => answers[question.id] = value)), const SizedBox(height: 12), FilledButton(onPressed: answers.length == personalityQuestions.length ? _save : null, child: const Text('Save my answers'))]));
  Future<void> _save() async { final userId = await ref.read(currentUserIdProvider.future); final profile = const PersonalityScoringService().score(userId: userId, answers: answers)!; await ref.read(personalityRepositoryProvider).save(profile); ref.invalidate(currentPersonalityProvider); if (mounted) Navigator.pop(context); }
}
class _Question extends StatelessWidget { const _Question({required this.question, required this.value, required this.onChanged}); final PersonalityQuestion question; final int? value; final ValueChanged<int> onChanged; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(question.text), for (var i = 1; i <= 4; i++) RadioListTile<int>(dense: true, title: Text(['Not like me', 'A little like me', 'Somewhat like me', 'Very much like me'][i - 1]), value: i, groupValue: value, onChanged: (v) { if (v != null) onChanged(v); })])); }
