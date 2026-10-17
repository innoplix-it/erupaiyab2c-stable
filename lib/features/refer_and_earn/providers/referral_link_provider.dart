import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../repositories/referral_repository.dart';

/// Loads the authenticated user's referral code + share link from
/// `POST /api/referral/generate-link`. Used by the Refer & Earn QR card.
final referralLinkProvider =
    FutureProvider.autoDispose<ReferralLinkResponse>((ref) async {
  return ReferralRepository().generateLink();
});
