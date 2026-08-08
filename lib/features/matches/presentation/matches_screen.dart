import 'package:flutter/material.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_body.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MitzonePageBody(
      title: 'Matches',
      child: MitzoneEmptyState(
        title: 'No matches yet',
        message:
            'When you connect with people from shared experiences, they\'ll appear here.',
        icon: Icons.people_outline,
      ),
    );
  }
}
