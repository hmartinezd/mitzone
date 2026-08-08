import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/profile_providers.dart';
import '../domain/user_profile.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _interestsController;
  late TextEditingController _languagesController;
  ConnectionGoal? _connectionGoal;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).value;
    _bioController = TextEditingController(text: profile?.bio);
    _cityController = TextEditingController(text: profile?.city);
    _interestsController = TextEditingController(
      text: profile?.interests.join(', '),
    );
    _languagesController = TextEditingController(
      text: profile?.languages.join(', '),
    );
    _connectionGoal = profile?.connectionGoal;
  }

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _interestsController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  List<String> _normalizeList(
    String value, {
    int maxItems = 10,
    int maxCharPerItem = 30,
  }) {
    if (value.trim().isEmpty) return [];
    final rawItems = value.split(',');
    final uniqueItems = <String>{};

    for (var item in rawItems) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      if (uniqueItems.length >= maxItems) break;

      final normalized = trimmed.length > maxCharPerItem
          ? trimmed.substring(0, maxCharPerItem)
          : trimmed;

      if (!uniqueItems.any(
        (existing) => existing.toLowerCase() == normalized.toLowerCase(),
      )) {
        uniqueItems.add(normalized);
      }
    }
    return uniqueItems.toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final profile = ref.read(currentProfileProvider).value!;

      final updatedProfile = UserProfile(
        id: profile.id,
        displayName: profile.displayName,
        avatarUri: profile.avatarUri,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        languages: _normalizeList(_languagesController.text),
        interests: _normalizeList(_interestsController.text),
        connectionGoal: _connectionGoal,
      );

      await ref.read(profileRepositoryProvider).saveProfile(updatedProfile);

      ref.invalidate(currentProfileProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("We couldn't save your details. Please try again."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).value;

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Profile not found.')));
    }

    return MitzonePageBody(
      title: 'Profile Details',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'These details are optional and help shape better connections.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Bio
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself',
                helperText: '${_bioController.text.length}/240',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 240,
              onChanged: (text) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Where are you based?',
              ),
              maxLength: 80,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Interests
            TextFormField(
              controller: _interestsController,
              decoration: const InputDecoration(
                labelText: 'Interests',
                hintText: 'Music, Technology, Travel...',
                helperText: 'Separate with commas (max 10)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Languages
            TextFormField(
              controller: _languagesController,
              decoration: const InputDecoration(
                labelText: 'Languages',
                hintText: 'English, Spanish...',
                helperText: 'Separate with commas (max 10)',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Connection Goal
            Text(
              'Connection Goal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<ConnectionGoal?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Not set')),
                ButtonSegment(
                  value: ConnectionGoal.social,
                  label: Text('Social'),
                ),
                ButtonSegment(
                  value: ConnectionGoal.professional,
                  label: Text('Professional'),
                ),
                ButtonSegment(value: ConnectionGoal.both, label: Text('Both')),
              ],
              selected: {_connectionGoal},
              onSelectionChanged: (newSelection) {
                setState(() => _connectionGoal = newSelection.first);
              },
              showSelectedIcon: false,
            ),

            const SizedBox(height: AppSpacing.xxxl),
            MitzoneButton(
              text: 'Save Details',
              onPressed: _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: AppSpacing.md),
            MitzoneButton(
              text: 'Cancel',
              onPressed: () => context.pop(),
              variant: MitzoneButtonVariant.secondary,
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
