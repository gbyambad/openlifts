import 'package:go_router/go_router.dart';
import 'package:openlifts/features/exercises/presentation/exercise_detail_screen.dart';
import 'package:openlifts/features/history/presentation/history_screen.dart';
import 'package:openlifts/features/home/presentation/today_screen.dart';
import 'package:openlifts/features/programs/presentation/program_builder_screen.dart';
import 'package:openlifts/features/programs/presentation/program_detail_screen.dart';
import 'package:openlifts/features/programs/presentation/programs_screen.dart';
import 'package:openlifts/features/progress/presentation/progress_screen.dart';
import 'package:openlifts/features/sessions/presentation/active_workout_screen.dart';
import 'package:openlifts/features/settings/presentation/settings_screen.dart';
import 'package:openlifts/features/shell/presentation/app_shell.dart';

/// Bottom-nav shell with five tabs; detail screens (Active Workout, Exercise
/// detail) are pushed on top of their tab.
final GoRouter appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (c, s) => const TodayScreen(),
              routes: [
                GoRoute(
                  path: 'workout/:dayId',
                  builder: (c, s) => ActiveWorkoutScreen(
                    dayId: s.pathParameters['dayId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (c, s) => const ProgressScreen(),
              routes: [
                GoRoute(
                  path: 'exercises/:id',
                  builder: (c, s) => ExerciseDetailScreen(
                    exerciseId: s.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/programs',
              builder: (c, s) => const ProgramsScreen(),
              routes: [
                // Literal 'new' must precede the ':id' param route.
                GoRoute(
                  path: 'new',
                  builder: (c, s) => const ProgramBuilderScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (c, s) => ProgramDetailScreen(
                    programId: s.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (c, s) => ProgramBuilderScreen(
                        editProgramId: s.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (c, s) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
