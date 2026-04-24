class LotteryResult {
  const LotteryResult({
    required this.company,
    required this.firstPrize,
    required this.secondPrize,
    required this.thirdPrize,
    required this.specialPrizes,
    required this.consolationPrizes,
    required this.date,
  });

  final String company;
  final String firstPrize;
  final String secondPrize;
  final String thirdPrize;
  final List<String> specialPrizes;
  final List<String> consolationPrizes;
  final String date;
}
