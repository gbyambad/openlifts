/// Suggested welcome-back deload percent for a layoff, by days since the last
/// workout. Short breaks need none (little strength is lost under ~2 weeks);
/// longer gaps scale the cut to rebuild form and avoid soreness.
int layoffDeloadPercent(int daysAway) {
  if (daysAway < 14) return 0; // under two weeks: train as normal
  if (daysAway < 30) return 10; // 2–4 weeks
  if (daysAway < 60) return 20; // 1–2 months
  return 30; // 2+ months
}
