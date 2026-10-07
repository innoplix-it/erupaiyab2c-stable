enum SpinRewardType {
  coins,
  extraSpin,
  jackpot,
  betterLuck, surprise,
}

class SpinReward {
  const SpinReward({
    required this.label,
    required this.type,
    this.coins,
  });

  final String label;
  final SpinRewardType type;
  final int? coins;
}
