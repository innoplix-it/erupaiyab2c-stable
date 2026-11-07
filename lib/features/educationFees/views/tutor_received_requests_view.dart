import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../constants/app_colors.dart';
import '../../../widgets/my_app_bar.dart';
import '../constants/tutor_notification_constants.dart';
import '../controllers/education_fees_controller.dart';
import '../controllers/tutor_received_requests_controller.dart';
import '../components/bank_details_request_popup.dart';
import '../repositories/education_fees_repository.dart';
import '../services/tutor_request_notification_service.dart';
import '../../../services/logger_service.dart';

/// Screen displaying pending tutor payment requests received by the tutor.
///
/// This screen shows a list of PENDING requests that the tutor can ACCEPT or REJECT.
/// It supports pagination and pull-to-refresh.
class TutorReceivedRequestsView extends ConsumerStatefulWidget {
  const TutorReceivedRequestsView({
    super.key,
    this.autoShowRequestReference,
  });

  /// Optional request reference to automatically show the popup for.
  /// When provided via notification tap, the popup will display automatically
  /// if the request is still PENDING.
  final String? autoShowRequestReference;

  @override
  ConsumerState<TutorReceivedRequestsView> createState() =>
      _TutorReceivedRequestsViewState();
}

class _TutorReceivedRequestsViewState
    extends ConsumerState<TutorReceivedRequestsView> {
  final ScrollController _scrollController = ScrollController();
  bool _hasAutoShownPopup = false;

  EducationFeesRepository get _repository =>
      ref.read(educationFeesRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRequests();
      if (widget.autoShowRequestReference != null &&
          widget.autoShowRequestReference!.isNotEmpty) {
        _autoShowPopupIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref
          .read(tutorReceivedRequestsControllerProvider.notifier)
          .loadMoreRequests();
    }
  }

  Future<void> _fetchRequests() async {
    await ref
        .read(tutorReceivedRequestsControllerProvider.notifier)
        .fetchPendingRequests(refresh: true);
  }

  /// "₹2,000.00" / "2000" / "2000.00" -> 2000.0 (null when not a number).
  double? _parseAmount(String? raw) {
    final cleaned = (raw ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String? _nonEmpty(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty || v.toLowerCase() == 'null') return null;
    return v;
  }

  Future<void> _autoShowPopupIfNeeded() async {
    if (_hasAutoShownPopup) return;
    final requestReference = widget.autoShowRequestReference;
    if (requestReference == null || requestReference.isEmpty) return;

    // Global FCM listener owns popup presentation for refs it already
    // verified / queued / presented. Avoid a second GET + duplicate dialog.
    final notificationService = TutorRequestNotificationService();
    if (notificationService.shownRequestReferences.contains(requestReference) ||
        notificationService.isShowingPopup) {
      logger.info(
        'NOTIFICATION_TAP_AUTO_POPUP_SKIPPED_GLOBAL_OWNS: $requestReference',
      );
      _hasAutoShownPopup = true;
      return;
    }

    logger.info('NOTIFICATION_TAP_AUTO_POPUP_CHECK: $requestReference');

    try {
      final response =
      await _repository.fetchTutorRequestStatus(requestReference);

      if (!response.status || response.data == null) {
        logger.warning('NOTIFICATION_TAP_STATUS_API_FAILED: $requestReference');
        return;
      }

      final data = response.data!;

      if (data.requestReference != requestReference) {
        logger.warning(
          'NOTIFICATION_TAP_REFERENCE_MISMATCH: requested=$requestReference, returned=${data.requestReference}',
        );
        return;
      }

      final status = data.requestStatus.trim().toUpperCase();
      if (status != TutorNotificationConstants.statusPending ||
          !data.isPending ||
          data.isAccepted ||
          data.isRejected) {
        logger.info(
          'NOTIFICATION_TAP_NOT_PENDING: $requestReference, status=$status',
        );
        return;
      }

      logger.info('NOTIFICATION_TAP_PENDING_CONFIRMED: $requestReference');

      if (!mounted) return;

      // Same fields as the list-tap popup so both behave identically.
      final purpose = _nonEmpty(data.subject);
      final resultFuture = showBankDetailsRequestPopup(
        context,
        requesterName: _nonEmpty(data.requesterName), // Sender name from API
        feeType: purpose, // Fee type / subject from API
        amount: _parseAmount(data.amount), // Payment amount from API
        paymentPurpose: purpose, // Payment purpose (same as feeType)
        paymentMethod: _nonEmpty(data.paymentMethod), // Payment method from API
        paymentStatus: _nonEmpty(data.requestStatus), // Payment status from API
        requestReference: requestReference, // Request reference ID
      );
      _hasAutoShownPopup = true;
      notificationService.markPopupPresented(requestReference);
      logger.info('NOTIFICATION_TAP_POPUP_PRESENTED: $requestReference');

      final result = await resultFuture;
      // Popup now handles Respond API and notification deletion internally.
      // Just refresh the list after the popup closes.
      if (result == true || result == false) {
        _fetchRequests();
      }
    } catch (e) {
      logger.error('NOTIFICATION_TAP_AUTO_POPUP_ERROR: $e', error: e);
      // Do not park the ref in awaiting without a broadcast event — that
      // would block the global listener from processing a later FCM/resume.
    }
  }

  Future<void> _showRequestDialog(String requestReference) async {
    // ref.read (not watch): this runs from a tap callback, not from build.
    final controllerState = ref.read(tutorReceivedRequestsControllerProvider);
    final request = controllerState.requests.firstWhere(
          (r) => r['request_reference']?.toString() == requestReference,
      orElse: () => <String, dynamic>{},
    );

    var requesterName = _firstText(request, const [
      'requester_name',
      'requesterName',
      'sender_name',
      'tutor_name',
      'tutorName',
      'student_name',
      'parent_name',
      'name',
    ]);
    var purpose = _firstText(request, const [
      'subject',
      'fee_type',
      'purpose',
    ]);
    var statusLabel = _firstText(request, const [
      'request_status',
      'status',
    ]);
    var paymentMethod = _firstText(request, const [
      'payment_method',
      'paymentMethod',
      'method',
    ]);
    var amount = _parseAmount(request['amount']?.toString());

    // The list payload can miss some fields. Fill the blanks from the same
    // status API the notification-tap flow uses, so the popup shows the same
    // content in both behaviours.
    final missing = requesterName == null ||
        purpose == null ||
        statusLabel == null ||
        paymentMethod == null ||
        amount == null;
    if (missing && requestReference.isNotEmpty) {
      try {
        final response =
        await _repository.fetchTutorRequestStatus(requestReference);
        final data = response.data;
        if (response.status && data != null) {
          requesterName ??= _nonEmpty(data.requesterName);
          purpose ??= _nonEmpty(data.subject);
          statusLabel ??= _nonEmpty(data.requestStatus);
          paymentMethod ??= _nonEmpty(data.paymentMethod);
          amount ??= _parseAmount(data.amount);
        }
      } catch (e) {
        logger.error('LIST_TAP_STATUS_FALLBACK_ERROR: $e', error: e);
      }
    }

    if (!mounted) return;

    final result = await showBankDetailsRequestPopup(
      context,
      requesterName: requesterName, // Sender name from API
      feeType: purpose, // Fee type / subject from API
      amount: amount, // Payment amount from API
      paymentPurpose: purpose, // Payment purpose (same as feeType)
      paymentMethod: paymentMethod, // Payment method from API
      paymentStatus: statusLabel, // Payment status from API
      requestReference: requestReference, // Request reference ID
    );

    // Popup now handles Respond API and notification deletion internally.
    // Just refresh the list after the popup closes.
    if (result == true || result == false) {
      _fetchRequests();
    }
  }

  String? _firstText(Map<String, dynamic> request, List<String> keys) {
    for (final key in keys) {
      final value = request[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return null;
  }

  String _formatAmount(dynamic amount) {
    final amountValue = _parseAmount(amount?.toString());
    if (amountValue == null) return '';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amountValue);
  }

  @override
  Widget build(BuildContext context) {
    final u = educationTutorUnit(context);
    final state = ref.watch(tutorReceivedRequestsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MyAppBar(
        title: 'Received Requests',
        showHelp: false,
        showBharatConnect: false,
        showDivider: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: state.isLoading && state.requests.isEmpty
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : state.requests.isEmpty
            ? _buildEmptyState(u)
            : _buildRequestList(u, state),
      ),
    );
  }

  Widget _buildEmptyState(double u) {
    // RefreshIndicator requires a scrollable child; keep empty content
    // scrollable so layout cannot overflow in short viewports/tests.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32 * u),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Color(0xFFD1D5DB),
                    ),
                    SizedBox(height: 16 * u),
                    Text(
                      'No Pending Requests',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18 * u,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8 * u),
                    Text(
                      'You don\'t have any pending tuition payment requests at the moment.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14 * u,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestList(double u, TutorReceivedRequestsState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16 * u),
      itemCount: state.requests.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.requests.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16 * u),
              child: const CircularProgressIndicator(),
            ),
          );
        }

        final request = state.requests[index];
        return _buildRequestCard(u, request);
      },
    );
  }

  Widget _buildRequestCard(double u, Map<String, dynamic> request) {
    final requestReference = request['request_reference']?.toString() ?? '';
    final amount = request['amount']?.toString().trim() ?? '';
    final subject = request['subject']?.toString().trim() ?? '';
    final statusLabel = _firstText(request, const [
      'request_status',
      'status',
    ]) ??
        '';
    final createdAt = request['created_at']?.toString() ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 12 * u),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12 * u),
      ),
      child: InkWell(
        onTap: () => _showRequestDialog(requestReference),
        borderRadius: BorderRadius.circular(12 * u),
        child: Padding(
          padding: EdgeInsets.all(16 * u),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject.isEmpty ? requestReference : subject,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16 * u,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (statusLabel.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * u,
                        vertical: 4 * u,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12 * u),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11 * u,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                ],
              ),
              if (_formatAmount(amount).isNotEmpty) ...[
                SizedBox(height: 12 * u),
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 20 * u,
                      color: const Color(0xFF71717A),
                    ),
                    SizedBox(width: 8 * u),
                    Text(
                      _formatAmount(amount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18 * u,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 8 * u),
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16 * u,
                    color: const Color(0xFF71717A),
                  ),
                  SizedBox(width: 8 * u),
                  Expanded(
                    child: Text(
                      'Ref: $requestReference',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12 * u,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ),
                ],
              ),
              if (createdAt.isNotEmpty) ...[
                SizedBox(height: 8 * u),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16 * u,
                      color: const Color(0xFF71717A),
                    ),
                    SizedBox(width: 8 * u),
                    Text(
                      createdAt,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12 * u,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

double educationTutorUnit(BuildContext context) {
  return ScreenUtil().scaleWidth;
}