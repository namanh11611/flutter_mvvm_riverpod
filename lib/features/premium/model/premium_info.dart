class PremiumInfo {
  final bool isPremium;
  final DateTime? expiryDate;
  final bool? isLifetime;

  const PremiumInfo({
    required this.isPremium,
    this.expiryDate,
    this.isLifetime,
  });
}
