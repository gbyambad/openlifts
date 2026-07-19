import 'package:drift/drift.dart' show Value;
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/date/date_labels.dart';
import 'package:openlifts/features/home/application/today_providers.dart';
import 'package:openlifts/features/programs/application/program_providers.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'programs_view.g.dart';

/// A program row reduced to what the list needs (easy to build in tests).
class ProgramCard {
  const ProgramCard({
    required this.id,
    required this.name,
    required this.scheduleSummary,
    required this.isActive,
    required this.isBuiltIn,
    this.tags = const [],
    this.weekdays = const [1, 3, 5],
    this.nextWorkout,
  });

  final String id;
  final String name;
  final String scheduleSummary;
  final bool isActive;
  final bool isBuiltIn;
  final List<String> tags;

  /// Current training weekdays (1 = Mon … 7 = Sun) — pre-fills the schedule
  /// picker so "change schedule" starts from the program's real days.
  final List<int> weekdays;

  /// The active program's next scheduled session, e.g. "Workout A · Today".
  /// Null for non-active programs.
  final String? nextWorkout;
}

/// The Programs tab, split so the UI can surface the active program and group
/// the rest: the user's own programs above the built-in templates.
class ProgramsView {
  const ProgramsView({
    this.active,
    this.custom = const [],
    this.templates = const [],
  });

  /// The currently-active program, pinned to the top. Null when none is active.
  final ProgramCard? active;

  /// The user's own (custom) programs, excluding the active one.
  final List<ProgramCard> custom;

  /// Built-in templates, excluding the active one.
  final List<ProgramCard> templates;

  bool get isEmpty => active == null && custom.isEmpty && templates.isEmpty;
}

String _scheduleSummary(Program p) {
  switch (p.scheduleMode) {
    case ScheduleMode.timesPerWeek:
      return '${p.timesPerWeek ?? 3}×/week';
    case ScheduleMode.everyNDays:
      return 'every ${p.everyNDays ?? 2} days';
    case ScheduleMode.fixedWeekdays:
      final days = p.weekdays;
      if (days == null || days.isEmpty) return 'set days';
      return days.map((d) => weekdayLabels[d - 1]).join(' · ');
  }
}

@riverpod
Future<ProgramsView> programsView(Ref ref) async {
  final all = await ref.watch(programRepositoryProvider).all();
  final settings = await ref.watch(settingsRepositoryProvider).get();
  final activeId = settings.activeProgramId;

  // The active program's next session, reusing the Today computation.
  String? nextWorkout;
  if (activeId != null) {
    final today = await ref.watch(todayProvider.future);
    if (today != null && today.workouts.isNotEmpty) {
      final w = today.workouts.first;
      nextWorkout = '${w.dayName} · ${w.dateLabel}';
    }
  }

  ProgramCard toCard(Program p) => ProgramCard(
        id: p.id,
        name: p.name,
        scheduleSummary: _scheduleSummary(p),
        isActive: p.id == activeId,
        isBuiltIn: p.isBuiltIn,
        tags: p.tags,
        weekdays: p.weekdays ?? const [1, 3, 5],
        nextWorkout: p.id == activeId ? nextWorkout : null,
      );

  ProgramCard? active;
  final custom = <ProgramCard>[];
  final templates = <ProgramCard>[];
  for (final p in all) {
    final card = toCard(p);
    if (card.isActive) {
      active = card;
    } else if (p.isBuiltIn) {
      templates.add(card);
    } else {
      custom.add(card);
    }
  }
  return ProgramsView(active: active, custom: custom, templates: templates);
}

/// Actions for the Programs screen. Built-ins fork on schedule edit.
///
/// Kept alive: this is an action-only controller reached via
/// `ref.read(...notifier)` with no listener. An auto-dispose controller is torn
/// down before its async action (select/duplicate/delete) finishes, so its
/// `Ref` throws `UnmountedRefException` mid-write and the tap silently fails.
@Riverpod(keepAlive: true)
class ProgramsController extends _$ProgramsController {
  @override
  void build() {}

  Future<void> selectActive(String programId) async {
    await ref.read(settingsRepositoryProvider).save(
          SettingsCompanion(activeProgramId: Value(programId)),
        );
    // Refresh both this list and the Today tab (a snapshot provider that
    // won't otherwise notice the active-program change).
    ref
      ..invalidate(programsViewProvider)
      ..invalidate(todayProvider);
  }

  /// Deep-copy [programId] into a fresh editable custom program (copy-on-edit)
  /// and return the new id, so the caller can open it in the builder.
  Future<String> duplicate(String programId) async {
    final repo = ref.read(programRepositoryProvider);
    final program = await repo.findById(programId);
    if (program == null) throw StateError('No program with id $programId');
    final newId = 'custom-${DateTime.now().millisecondsSinceEpoch}';
    await repo.copyAsCustom(
      programId,
      newId: newId,
      newName: '${program.name} (Copy)',
    );
    ref.invalidate(programsViewProvider);
    return newId;
  }

  /// Delete a custom program. If it was the active one, the active program is
  /// cleared so the app falls back to the empty state.
  Future<void> deleteProgram(String programId) async {
    final settings = ref.read(settingsRepositoryProvider);
    final current = await settings.get();
    if (current.activeProgramId == programId) {
      await settings
          .save(const SettingsCompanion(activeProgramId: Value(null)));
    }
    await ref.read(programRepositoryProvider).deleteProgram(programId);
    ref
      ..invalidate(programsViewProvider)
      ..invalidate(todayProvider);
  }

  Future<void> setTimesPerWeek(String programId, int times) async {
    await ref.read(programRepositoryProvider).setSchedule(
          programId,
          mode: ScheduleMode.timesPerWeek,
          timesPerWeek: times,
        );
    await selectActive(programId);
  }

  /// Makes [programId] the active program, scheduled on the chosen [weekdays]
  /// (1 = Mon … 7 = Sun).
  ///
  /// Activation and schedule changes edit the program in place — no fork. Only
  /// a *structure* edit (changing exercises or set schemes) forks a built-in
  /// into a custom copy, so the Programs list isn't flooded with "(Custom)"
  /// clones just from picking a template or tweaking training days.
  Future<void> useProgram(String programId, List<int> weekdays) async {
    await ref.read(programRepositoryProvider).setSchedule(
          programId,
          mode: ScheduleMode.fixedWeekdays,
          weekdays: weekdays,
        );
    await selectActive(programId);
  }
}
