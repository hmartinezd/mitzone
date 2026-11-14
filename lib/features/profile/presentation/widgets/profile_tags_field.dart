import 'package:flutter/material.dart';
import '../../domain/profile_validation.dart';

/// A chip editor with suggestions and an optional custom entry. The controller
/// retains the repository's existing comma-separated form contract, including
/// an unfinished entry so Save never silently drops what the person typed.
class ProfileTagsField extends StatefulWidget {
  const ProfileTagsField({
    super.key,
    required this.controller,
    required this.label,
    required this.singular,
    required this.fieldKey,
    this.suggestions = const [],
  });
  final TextEditingController controller;
  final String label;
  final String singular;
  final Key fieldKey;
  final List<String> suggestions;
  @override
  State<ProfileTagsField> createState() => _ProfileTagsFieldState();
}

class _ProfileTagsFieldState extends State<ProfileTagsField> {
  final _entry = TextEditingController();
  late List<String> _values;
  @override
  void initState() {
    super.initState();
    _values = ProfileValidation.normalizeList(
      widget.controller.text.split(','),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  List<String> get _all =>
      ProfileValidation.normalizeList([..._values, ..._entry.text.split(',')]);
  void _sync() => widget.controller.text = _all.join(', ');
  String? _validate(String? _) {
    final values = _all;
    if (values.length > ProfileValidation.maxListItems) {
      return 'Add up to ${ProfileValidation.maxListItems} ${widget.label.toLowerCase()}.';
    }
    if (values.any((v) => v.length > ProfileValidation.maxListItemLength)) {
      return 'Each ${widget.singular} must be ${ProfileValidation.maxListItemLength} characters or fewer.';
    }
    return null;
  }

  void _add([String? suggestion]) {
    if (suggestion != null) _entry.text = suggestion;
    if (_validate(null) != null) {
      setState(() {});
      _sync();
      return;
    }
    setState(() {
      _values = _all;
      _entry.clear();
      _sync();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
      if (_values.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final value in _values)
                InputChip(
                  label: Text(value),
                  deleteButtonTooltipMessage: 'Remove $value',
                  onDeleted: () => setState(() {
                    _values.remove(value);
                    _sync();
                  }),
                ),
            ],
          ),
        ),
      TextFormField(
        key: widget.fieldKey,
        controller: _entry,
        decoration: InputDecoration(
          labelText: 'Add ${widget.singular}',
          helperText: 'Optional · up to ${ProfileValidation.maxListItems}',
          helperMaxLines: 2,
          errorMaxLines: 3,
          suffixIcon: IconButton(
            tooltip: 'Add ${widget.singular}',
            onPressed: () => _add(),
            icon: const Icon(Icons.add),
          ),
        ),
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(_sync),
        onFieldSubmitted: (_) => _add(),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: _validate,
      ),
      if (widget.suggestions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final suggestion in widget.suggestions.where(
                (s) =>
                    !_values.any((v) => v.toLowerCase() == s.toLowerCase()) &&
                    (_entry.text.trim().isEmpty ||
                        s.toLowerCase().contains(
                          _entry.text.trim().toLowerCase(),
                        )),
              ))
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => _add(suggestion),
                ),
            ],
          ),
        ),
    ],
  );
}
