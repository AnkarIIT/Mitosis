class RankPredictor {
  /// Maps NEET Score (0-720) to an estimated All India Rank (AIR)
  /// Based on historical data (2023-2024 trends)
  static int predictRank(int score) {
    if (score >= 715) return 1;
    if (score >= 710) return 100;
    if (score >= 700) return 500;
    if (score >= 690) return 1500;
    if (score >= 680) return 3000;
    if (score >= 670) return 5000;
    if (score >= 660) return 8000;
    if (score >= 650) return 12000;
    if (score >= 640) return 18000;
    if (score >= 630) return 25000;
    if (score >= 620) return 35000;
    if (score >= 600) return 50000;
    if (score >= 580) return 75000;
    if (score >= 550) return 120000;
    if (score >= 500) return 200000;
    if (score >= 450) return 350000;
    if (score >= 400) return 500000;
    if (score >= 300) return 800000;
    return 1000000; // Above 1 million
  }

  static String getPercentile(int score) {
    if (score >= 700) return "99.9+";
    if (score >= 650) return "99.5+";
    if (score >= 600) return "98.0+";
    if (score >= 550) return "95.0+";
    if (score >= 500) return "90.0+";
    if (score >= 400) return "80.0+";
    return "Under 70";
  }
}
