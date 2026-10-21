import 'biller_model.dart';

class BillerDetailArgs {
  const BillerDetailArgs({
    required this.biller,
    this.isCreditCard = false,
    this.paymentType,
    this.mobileNumber,
    this.cardLast4,
    this.autoFetchBill = false,
    this.autoOpenPaymentSheet = false,
    this.creditCardPayNowEntry = false,
  });

  final Biller biller;
  final bool isCreditCard;
  final String? paymentType;
  final String? mobileNumber;
  final String? cardLast4;
  final bool autoFetchBill;
  final bool autoOpenPaymentSheet;
  /// Entered from [RouteConstants.creditCardPayNow] (skip bill entry form).
  final bool creditCardPayNowEntry;
}
