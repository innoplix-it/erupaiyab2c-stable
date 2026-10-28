import 'bill_pay_response_model.dart';
import 'bill_response_model.dart';
import 'biller_detail_model.dart';
import 'biller_model.dart';

class BillerDetailState {
  const BillerDetailState({
    this.selectedBiller,
    this.selectedCategoryName,
    this.billerDetail,
    this.isFetchingDetail = false,
    this.isFetchingBill = false,
    this.isPayingBill = false,
    this.isPaymentInFlight = false,
    this.billResponse,
    this.customerParamsInput,
    this.payResponse,
    this.payErrorMessage,
    this.showFullDetails = false,
    this.errorMessage,
    this.billFetchNote,
  });

  final Biller? selectedBiller;
  final String? selectedCategoryName;
  final BillerDetail? billerDetail;
  final bool isFetchingDetail;
  final bool isFetchingBill;
  final bool isPayingBill;
  final bool isPaymentInFlight;
  final BillResponse? billResponse;
  final Map<String, String>? customerParamsInput;
  final BillPayResponse? payResponse;
  final String? payErrorMessage;
  final bool showFullDetails;
  final String? errorMessage;
  final String? billFetchNote;

  static const _sentinel = Object();

  BillerDetailState copyWith({
    Object? selectedBiller = _sentinel,
    Object? selectedCategoryName = _sentinel,
    Object? billerDetail = _sentinel,
    bool? isFetchingDetail,
    bool? isFetchingBill,
    bool? isPayingBill,
    bool? isPaymentInFlight,
    Object? billResponse = _sentinel,
    Object? customerParamsInput = _sentinel,
    Object? payResponse = _sentinel,
    Object? payErrorMessage = _sentinel,
    bool? showFullDetails,
    Object? errorMessage = _sentinel,
    Object? billFetchNote = _sentinel,
  }) {
    return BillerDetailState(
      selectedBiller: selectedBiller == _sentinel
          ? this.selectedBiller
          : selectedBiller as Biller?,
      selectedCategoryName: selectedCategoryName == _sentinel
          ? this.selectedCategoryName
          : selectedCategoryName as String?,
      billerDetail: billerDetail == _sentinel
          ? this.billerDetail
          : billerDetail as BillerDetail?,
      isFetchingDetail: isFetchingDetail ?? this.isFetchingDetail,
      isFetchingBill: isFetchingBill ?? this.isFetchingBill,
      isPayingBill: isPayingBill ?? this.isPayingBill,
      isPaymentInFlight: isPaymentInFlight ?? this.isPaymentInFlight,
      billResponse: billResponse == _sentinel
          ? this.billResponse
          : billResponse as BillResponse?,
      customerParamsInput: customerParamsInput == _sentinel
          ? this.customerParamsInput
          : customerParamsInput as Map<String, String>?,
      payResponse: payResponse == _sentinel
          ? this.payResponse
          : payResponse as BillPayResponse?,
      payErrorMessage: payErrorMessage == _sentinel
          ? this.payErrorMessage
          : payErrorMessage as String?,
      showFullDetails: showFullDetails ?? this.showFullDetails,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      billFetchNote: billFetchNote == _sentinel
          ? this.billFetchNote
          : billFetchNote as String?,
    );
  }
}
