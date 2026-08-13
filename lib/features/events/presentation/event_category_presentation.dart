import 'package:flutter/material.dart';

IconData eventCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'networking':
      return Icons.people_outline;
    case 'art':
      return Icons.palette_outlined;
    case 'wellness':
      return Icons.spa_outlined;
    case 'music':
      return Icons.music_note_outlined;
    default:
      return Icons.event_outlined;
  }
}
