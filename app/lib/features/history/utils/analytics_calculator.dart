import '../models/kpi_summary.dart';

class AnalyticsCalculator {
  /// Calculate FBK Percentage: (FBK / Total Rallies) × 100
  static double calculateFBKPercentage(int fbk, int totalRallies) {
    if (totalRallies == 0) return 0.0;
    return (fbk / totalRallies) * 100;
  }

  /// Calculate Transition Point Percentage: (Transition Points / Total Rallies) × 100
  static double calculateTransitionPointPercentage(
    int transitionPoints,
    int totalRallies,
  ) {
    if (totalRallies == 0) return 0.0;
    return (transitionPoints / totalRallies) * 100;
  }

  /// Calculate Attack Efficiency: (Kills - Errors) / Total Attempts
  static double calculateAttackEfficiency(
    int kills,
    int errors,
    int attempts,
  ) {
    if (attempts == 0) return 0.0;
    return (kills - errors) / attempts;
  }

  /// Calculate Kill Percentage: Kills / Total Attempts
  static double calculateKillPercentage(int kills, int attempts) {
    if (attempts == 0) return 0.0;
    return kills / attempts;
  }

  /// Calculate Block Efficiency: Blocks / Total Rallies
  /// Approximates how often points are earned via blocks relative to total rallies
  static double calculateBlockEfficiency(int blocks, int totalRallies) {
    if (totalRallies == 0) return 0.0;
    return blocks / totalRallies;
  }

  /// Calculate Serve Efficiency: (Aces - Errors) / Total Serves
  static double calculateServeEfficiency(int aces, int errors, int totalServes) {
    if (totalServes == 0) return 0.0;
    return (aces - errors) / totalServes;
  }

  /// Calculate Win Rate: Matches Won / Total Matches
  static double calculateWinRate(int matchesWon, int totalMatches) {
    if (totalMatches == 0) return 0.0;
    return (matchesWon / totalMatches) * 100;
  }

  /// Calculate comprehensive KPIs from aggregated stats
  static KPISummary calculateKPIs({
    required int totalRallies,
    required int totalFBK,
    required int totalTransitionPoints,
    required int totalKills,
    required int totalErrors,
    required int totalAttempts,
    required int totalBlocks,
    required int totalAces,
    required int totalServeErrors,
    required int totalServes,
    required int matchesWon,
    required int totalMatches,
  }) {
    return KPISummary(
      fbkPercentage: calculateFBKPercentage(totalFBK, totalRallies),
      transitionPointPercentage: calculateTransitionPointPercentage(
        totalTransitionPoints,
        totalRallies,
      ),
      attackEfficiency: calculateAttackEfficiency(
        totalKills,
        totalErrors,
        totalAttempts,
      ),
      killPercentage: calculateKillPercentage(totalKills, totalAttempts),
      blockEfficiency: calculateBlockEfficiency(totalBlocks, totalRallies),
      serveEfficiency: calculateServeEfficiency(
        totalAces,
        totalServeErrors,
        totalServes,
      ),
      winRate: calculateWinRate(matchesWon, totalMatches),
    );
  }
}

