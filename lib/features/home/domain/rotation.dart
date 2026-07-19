/// Index of the next rotation day, given the number of days in the program and
/// the index of the last completed day (null = fresh start -> day 0).
///
/// Purely a function of history, not the calendar — so a session logged on an
/// off-schedule day still advances the rotation.
int nextDayIndex(int dayCount, int? lastCompletedIndex) =>
    lastCompletedIndex == null ? 0 : (lastCompletedIndex + 1) % dayCount;
