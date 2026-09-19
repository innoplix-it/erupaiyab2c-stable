import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/error_message_utils.dart';
import '../models/digital_gold_preview.dart';
import '../models/digital_metal.dart';
import '../repo/digital_gold_repo.dart';

class DigitalGoldTradeArgs {
  const DigitalGoldTradeArgs({
    required this.mode,
    required this.metal,
    required this.validateRegistration,
  });

  final GoldTradeMode mode;
  final DigitalMetal metal;
  final bool validateRegistration;

  @override
  bool operator ==(Object other) {
    return other is DigitalGoldTradeArgs &&
        other.mode == mode &&
        other.metal == metal &&
        other.validateRegistration == validateRegistration;
  }

  @override
  int get hashCode => Object.hash(mode, metal, validateRegistration);
}

class DigitalGoldTradeState {
  const DigitalGoldTradeState({
    required this.isBuyingInRupees,
    required this.amountText,
    required this.isFetching,
    required this.preview,
    required this.errorMessage,
    required this.shouldRedirectToDetails,
  });

  factory DigitalGoldTradeState.initial({
    required GoldTradeMode mode,
  }) {
    return DigitalGoldTradeState(
      isBuyingInRupees: true,
      amountText: mode == GoldTradeMode.sell ? '2000' : '500',
      isFetching: true,
      preview: null,
      errorMessage: null,
      shouldRedirectToDetails: false,
    );
  }

  final bool isBuyingInRupees;
  final String amountText;
  final bool isFetching;
  final DigitalGoldPreview? preview;
  final String? errorMessage;
  final bool shouldRedirectToDetails;

  DigitalGoldTradeState copyWith({
    bool? isBuyingInRupees,
    String? amountText,
    bool? isFetching,
    DigitalGoldPreview? preview,
    Object? errorMessage = _sentinel,
    bool? shouldRedirectToDetails,
  }) {
    return DigitalGoldTradeState(
      isBuyingInRupees: isBuyingInRupees ?? this.isBuyingInRupees,
      amountText: amountText ?? this.amountText,
      isFetching: isFetching ?? this.isFetching,
      preview: preview ?? this.preview,
      errorMessage:
          errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
      shouldRedirectToDetails:
          shouldRedirectToDetails ?? this.shouldRedirectToDetails,
    );
  }

  static const _sentinel = Object();
}

final digitalGoldTradeControllerProvider = StateNotifierProvider.autoDispose
    .family<DigitalGoldTradeController, DigitalGoldTradeState, DigitalGoldTradeArgs>(
  (ref, args) => DigitalGoldTradeController(
    repository: ref.watch(digitalGoldRepoProvider),
    args: args,
  ),
);

class DigitalGoldTradeController extends StateNotifier<DigitalGoldTradeState> {
  DigitalGoldTradeController({
    required DigitalGoldRepo repository,
    required DigitalGoldTradeArgs args,
  })  : _repository = repository,
        _args = args,
        super(DigitalGoldTradeState.initial(mode: args.mode)) {
    _fetchPreview(silent: false);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchPreview(silent: true);
    });
  }

  final DigitalGoldRepo _repository;
  final DigitalGoldTradeArgs _args;
  Timer? _timer;
  bool _inFlight = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void setUnit({required bool buyInRupees}) {
    if (buyInRupees == state.isBuyingInRupees) return;
    state = state.copyWith(
      isBuyingInRupees: buyInRupees,
      amountText: buyInRupees
          ? (_args.mode == GoldTradeMode.sell ? '2000' : '500')
          : '0.5',
    );
    _fetchPreview(silent: false);
  }

  void setAmountText(String value) {
    final trimmed = value.trim();
    if (trimmed == state.amountText) return;
    state = state.copyWith(amountText: trimmed);
    _fetchPreview(silent: true);
  }

  Future<void> refresh() async {
    await _fetchPreview(silent: false);
  }

  void markRedirectHandled() {
    if (!state.shouldRedirectToDetails) return;
    state = state.copyWith(shouldRedirectToDetails: false);
  }

  String _formatAmount(String text) {
    final parsed = double.tryParse(text) ?? 0.0;
    return parsed.toStringAsFixed(2);
  }

  String _calculationType() => state.isBuyingInRupees ? 'A' : 'Q';

  String _metalType() => _args.metal == DigitalMetal.gold ? 'G' : 'S';

  String _quantityValue(String amountText) {
    if (state.isBuyingInRupees) return '1';
    return _formatAmount(amountText);
  }

  Future<void> _fetchPreview({required bool silent}) async {
    if (_inFlight) return;
    final amountText = state.amountText.trim();
    if (amountText.isEmpty) return;
    _inFlight = true;
    if (!silent) {
      state = state.copyWith(isFetching: true, errorMessage: null);
    }
    try {
      final response = await _repository.fetchProceedPreview(
        calculationType: _calculationType(),
        amount: _formatAmount(amountText),
        quantity: _quantityValue(amountText),
        metalType: _metalType(),
      );

      if (_args.validateRegistration && !response.isUserRegistered) {
        state = state.copyWith(
          preview: response,
          isFetching: false,
          shouldRedirectToDetails: true,
          errorMessage: null,
        );
        return;
      }

      state = state.copyWith(
        preview: response,
        isFetching: false,
        shouldRedirectToDetails: false,
        errorMessage: null,
      );
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          isFetching: false,
          errorMessage: ErrorMessageUtils.from(
            e,
            fallback: 'Unable to fetch preview. Please try again.',
          ),
        );
      }
    } finally {
      _inFlight = false;
    }
  }
}
