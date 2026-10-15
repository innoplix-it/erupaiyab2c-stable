import '../../../constants/file_constants.dart';

class ZeroBalanceBank {
  const ZeroBalanceBank({
    required this.id,
    required this.name,
    required this.accountType,
    required this.description,
    required this.logoAsset,
    required this.logoAspectRatio,
    required this.logoFigmaWidth,
  });

  /// Shown until the offer API supplies the reward cap.
  static const num defaultRewardAmount = 100;

  final String id;
  final String name;
  final String accountType;
  final String description;
  final String logoAsset;

  /// Intrinsic width / height of [logoAsset].
  final double logoAspectRatio;

  /// Logo width inside the 62 px logo box, in Figma (440 frame) px.
  final double logoFigmaWidth;

  static final List<ZeroBalanceBank> partners = [
    ZeroBalanceBank(
      id: 'airtel_payments_bank',
      name: 'Airtel Payments Bank',
      accountType: 'Zero Balance Account',
      description: 'Convenient digital banking on the go.',
      logoAsset: FileConstants.airtelLogoSvg,
      logoAspectRatio: 131 / 20,
      logoFigmaWidth: 40,
    ),
    ZeroBalanceBank(
      id: 'kotak_811',
      name: 'Kotak 811',
      accountType: 'Zero Balance Account',
      description: 'Simple and convenient digital banking.',
      logoAsset: FileConstants.kotakLogoSvg,
      logoAspectRatio: 100 / 50,
      // The artwork carries ~8% transparent side padding, so 52 renders the
      // ~44 px visible wordmark from Figma.
      logoFigmaWidth: 52,
    ),
  ];
}
