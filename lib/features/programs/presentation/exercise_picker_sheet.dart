import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/exercises/application/exercises_providers.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/async_view.dart';

/// A searchable catalog picker. Resolves to the chosen [Exercise], or null if
/// the sheet is dismissed.
Future<Exercise?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ExercisePicker(),
  );
}

class _ExercisePicker extends ConsumerStatefulWidget {
  const _ExercisePicker();

  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: loc.searchExercisesHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: AsyncView(
              value: ref.watch(exercisesProvider),
              data: (all) {
                final matches = _query.isEmpty
                    ? all
                    : all
                        .where((e) => e.name.toLowerCase().contains(_query))
                        .toList();
                if (matches.isEmpty) {
                  return Center(child: Text(loc.noMatchingExercises));
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: matches.length,
                  itemBuilder: (context, i) {
                    final e = matches[i];
                    return ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.equipment.name),
                      onTap: () => Navigator.pop(context, e),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
