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
import '../components/education_tuition_request_popup.dart';
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
  bool _isResponding = false;

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

      final amount = double.tryParse(data.amount.trim());
      final requesterName =
          data.requesterName.trim().isEmpty ? null : data.requesterName.trim();

      if (!mounted) return;

      final resultFuture = showEducationTuitionRequestPopup(
        context,
        state: EducationTuitionPopupState.received,
        amount: amount,
        requesterName: requesterName,
        paymentPurpose:
            data.subject.trim().isEmpty ? null : data.subject.trim(),
        requestStatusLabel: data.requestStatus.trim().isEmpty
            ? null
            : data.requestStatus.trim(),
      );
      _hasAutoShownPopup = true;
      notificationService.markPopupPresented(requestReference);
      logger.info('NOTIFICATION_TAP_POPUP_PRESENTED: $requestReference');

      final result = await resultFuture;
      if (_isResponding) return;
      _isResponding = true;
      try {
        if (result == true) {
          await _repository.respondToTutorRequest(
            requestReference: requestReference,
            action: TutorNotificationConstants.statusAccepted,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request accepted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _fetchRequests();
          }
        } else if (result == false) {
          await _repository.respondToTutorRequest(
            requestReference: requestReference,
            action: TutorNotificationConstants.statusRejected,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request rejected'),
                backgroundColor: Colors.orange,
              ),
            );
            _fetchRequests();
          }
        }
      } finally {
        _isResponding = false;
        notificationService.markRequestHandled(requestReference);
      }
    } catch (e) {
      logger.error('NOTIFICATION_TAP_AUTO_POPUP_ERROR: $e', error: e);
      // Do not park the ref in awaiting without a broadcast event — that
      // would block the global listener from processing a later FCM/resume.
    }
  }

  Future<void> _showRequestDialog(String requestReference) async {
    final controllerState = ref.watch(tutorReceivedRequestsControllerProvider);
    final request = controllerState.requests.firstWhere(
      (r) => r['request_reference']?.toString() == requestReference,
      orElse: () => <String, dynamic>{},
    );
    
    final amount = double.tryParse(request['amount']?.toString().trim() ?? '');
    final requesterName = _firstText(request, const [
      'requester_name',
      'student_name',
    ]);
    final purpose = _firstText(request, const ['subject']);
    final statusLabel = _firstText(request, const [
      'request_status',
      'status',
    ]);

    final result = await showEducationTuitionRequestPopup(
      context,
      state: EducationTuitionPopupState.received,
      amount: amount,
      requesterName: requesterName,
      paymentPurpose: purpose,
      requestStatusLabel: statusLabel,
    );

    if (result == true) {
      // Request was accepted - call API
      try {
        final controller = ref.read(tutorReceivedRequestsControllerProvider.notifier);
        await controller.respondToRequest(
          requestReference: requestReference,
          action: 'ACCEPTED',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchRequests(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (result == false) {
      // Request was rejected - call API
      try {
        final controller = ref.read(tutorReceivedRequestsControllerProvider.notifier);
        await controller.respondToRequest(
          requestReference: requestReference,
          action: 'REJECTED',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          _fetchRequests(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
    final amountStr = amount?.toString().trim() ?? '';
    final amountValue = double.tryParse(amountStr);
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
