import 'dart:convert';

import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/programs/domain/program_repository.dart';

/// Seeds the built-in programs from a JSON string (bundled
/// `assets/seed/programs.json`, or a fixture in tests) via [ProgramRepository].
/// Idempotent: insert-or-replace on stable slug IDs.
Future<void> seedProgramsFromJson(
  ProgramRepository repo,
  String jsonStr,
) async {
  final programs = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
  for (final p in programs) {
    await repo.insertProgram(_toNewProgram(p));
  }
}

NewProgram _toNewProgram(Map<String, dynamic> p) => NewProgram(
      id: p['id'] as String,
      name: p['name'] as String,
      description: p['description'] as String?,
      isBuiltIn: p['isBuiltIn'] as bool? ?? false,
      progressionStyle:
          ProgressionStyle.values.byName(p['progressionStyle'] as String),
      progressionPercent: (p['progressionPercent'] as num?)?.toDouble(),
      scheduleMode: ScheduleMode.values.byName(p['scheduleMode'] as String),
      timesPerWeek: p['timesPerWeek'] as int?,
      everyNDays: p['everyNDays'] as int?,
      weekdays: (p['weekdays'] as List?)?.cast<int>(),
      tags: (p['tags'] as List?)?.cast<String>() ?? const [],
      days: (p['days'] as List)
          .cast<Map<String, dynamic>>()
          .map(_toNewDay)
          .toList(),
    );

NewDay _toNewDay(Map<String, dynamic> d) => NewDay(
      id: d['id'] as String,
      name: d['name'] as String,
      orderIndex: d['orderIndex'] as int,
      prescriptions: (d['prescriptions'] as List)
          .cast<Map<String, dynamic>>()
          .map(_toNewPrescription)
          .toList(),
    );

NewPrescription _toNewPrescription(Map<String, dynamic> p) => NewPrescription(
      exerciseId: p['exerciseId'] as String,
      orderIndex: p['orderIndex'] as int,
      section: Section.values.byName(p['section'] as String? ?? 'main'),
      optional: p['optional'] as bool? ?? false,
      setGroups: (p['setGroups'] as List)
          .cast<Map<String, dynamic>>()
          .map(_toNewSetGroup)
          .toList(),
    );

NewSetGroup _toNewSetGroup(Map<String, dynamic> g) => NewSetGroup(
      orderIndex: g['orderIndex'] as int,
      sets: g['sets'] as int,
      reps: g['reps'] as int,
      weightRule: WeightRule.values.byName(g['weightRule'] as String),
      weightParam: (g['weightParam'] as num?)?.toDouble(),
    );
