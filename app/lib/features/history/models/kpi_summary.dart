class KPISummary {
  KPISummary({
    required this.fbkPercentage,
    required this.transitionPointPercentage,
    required this.attackEfficiency,
    required this.killPercentage,
    required this.blockEfficiency,
    required this.serveEfficiency,
    required this.winRate,
  });

  final double fbkPercentage;
  final double transitionPointPercentage;
  final double attackEfficiency;
  final double killPercentage;
  final double blockEfficiency;
  final double serveEfficiency;
  final double winRate;

  factory KPISummary.empty() {
    return KPISummary(
      fbkPercentage: 0.0,
      transitionPointPercentage: 0.0,
      attackEfficiency: 0.0,
      killPercentage: 0.0,
      blockEfficiency: 0.0,
      serveEfficiency: 0.0,
      winRate: 0.0,
    );
  }
}

