part of 'biller_detail_view.dart';

class _InfoNoteCard extends StatelessWidget {
  const _InfoNoteCard({
    required this.text,
    this.showLogo = true,
  });

  final String text;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.lightBorder.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLogo) ...[
            Image.asset(FileConstants.bharatConnectColor, height: 18.h),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              text,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10.sp,
                    color: Colors.black,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GasPolicyBanner extends StatelessWidget {
  const _GasPolicyBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFDB0101),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Text(
        message.trim(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
      ),
    );
  }
}

class _GasErrorBanner extends StatelessWidget {
  const _GasErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFDB0101),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 18.r,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSummaryCard extends StatelessWidget {
  const _SubscriptionSummaryCard({
    required this.mobileNumber,
    required this.plan,
    required this.amount,
    required this.onChange,
  });

  final String mobileNumber;
  final String plan;
  final double amount;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final resolvedMobile = mobileNumber.trim().isEmpty ? '-' : mobileNumber;
    final resolvedPlan = plan.trim().isEmpty ? '-' : plan;
    final amountText = amount <= 0 ? '-' : '₹${amount.toStringAsFixed(2)}';

    Widget stackedField({
      required String label,
      required String value,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stackedField(label: 'Mobile Number', value: resolvedMobile),
          SizedBox(height: 16.h),
          stackedField(label: 'Plan', value: resolvedPlan),
          SizedBox(height: 20.h),
          Row(
            children: [
              Text(
                'Amount To Pay',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                amountText,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 24.sp,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isGasCylinderCategory(String? paymentType) {
  final value = (paymentType ?? '').trim().toLowerCase();
  if (value.isEmpty) return false;
  // Only LPG cylinder booking ("Book Gas") should use cylinder-specific UI
  // (bill sample/terms + registered mobile prefills). Exclude Piped Gas (PNG).
  final isPipedGas = value.contains('piped') ||
      value.contains('pipe') ||
      value.contains('png');
  if (isPipedGas) return false;

  return value.contains('lpg') ||
      value.contains('cylinder') ||
      (value.contains('book') && value.contains('gas'));
}

bool _isPipedGasCategory(String? paymentType) {
  final value = (paymentType ?? '').trim().toLowerCase();
  if (value.isEmpty) return false;
  return value.contains('piped') ||
      value.contains('pipe') ||
      value.contains('png') ||
      (value.contains('gas') && value.contains('pipe'));
}

bool _isGasBookingPolicyMessage(String message) {
  final text = message.trim().toLowerCase();
  if (text.isEmpty) return false;
  if (!text.contains('dear customer')) return false;
  return text.contains('booking policy') ||
      text.contains('eligible booking date') ||
      text.contains('lpg refill') ||
      text.contains('refill was delivered');
}

bool _isSubscriptionFlow({
  required String? paymentType,
  required String? detailCategory,
  required String? billerName,
}) {
  bool isSubscriptionText(String? value) {
    final text = (value ?? '').trim().toLowerCase();
    if (text.isEmpty) return false;
    return text == 'subscription' || text.contains('subscription');
  }

  if (isSubscriptionText(paymentType)) return true;
  if (isSubscriptionText(detailCategory)) return true;

  final name = (billerName ?? '').trim().toLowerCase();
  if (name.isEmpty) return false;
  const hints = [
    'subscription',
    'hotstar',
    'ott',
    'netflix',
    'prime',
    'sony',
    'zee',
  ];
  return hints.any(name.contains);
}

String _resolveSubscriptionMobile(Map<String, String> params) {
  if (params.isEmpty) return '';
  for (final entry in params.entries) {
    final key = entry.key.toLowerCase();
    if (key.contains('mobile') ||
        key.contains('phone') ||
        key.contains('contact')) {
      return entry.value.trim();
    }
  }
  return params.values.first.trim();
}

String _resolveSubscriptionPlan(Map<String, String> params) {
  if (params.isEmpty) return '';
  for (final entry in params.entries) {
    final key = entry.key.toLowerCase();
    if (key.contains('plan') ||
        key.contains('package') ||
        key.contains('product')) {
      return entry.value.trim();
    }
  }
  if (params.values.length >= 2) {
    return params.values.elementAt(1).trim();
  }
  return '';
}

double _resolveSubscriptionAmount(
  Map<String, String> params,
  String enteredAmountRaw,
  BillResponse? bill,
) {
  final entered = _parseEnteredAmount(enteredAmountRaw);
  if (entered != null && entered > 0) return entered;
  if (bill != null) return bill.amountInRupees;

  final plan = _resolveSubscriptionPlan(params);
  final parsed = _parseAmountFromPlan(plan);
  if (parsed != null && parsed > 0) return parsed;

  return 0;
}

double? _parseAmountFromPlan(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final explicit = RegExp(
    r'(?:₹|rs\.?|inr|@)\s*([0-9]+(?:\.[0-9]+)?)',
    caseSensitive: false,
  ).firstMatch(text);
  if (explicit != null) {
    return double.tryParse(explicit.group(1) ?? '');
  }

  final numbers = RegExp(r'([0-9]+(?:\.[0-9]+)?)').allMatches(text).toList();
  if (numbers.isEmpty) return null;
  return double.tryParse(numbers.last.group(1) ?? '');
}

class _MaskedPrefix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              letterSpacing: 1.2,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

bool _isNoBillDueMessage(String message) {
  return message.toLowerCase().contains('no bill due');
}

class _NoBillDueDialog extends StatelessWidget {
  const _NoBillDueDialog({
    required this.title,
    required this.message,
    required this.onContinue,
  });

  final String title;
  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F8EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF1BA13F),
                size: 44,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.75),
                  ),
            ),
            SizedBox(height: 22.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: onContinue,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillFetchFailedDialog extends StatelessWidget {
  const _BillFetchFailedDialog({
    required this.message,
    required this.onContinue,
  });

  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 65.r,
              height: 65.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2B9A6)),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 44.r,
              ),
            ),
            // SizedBox(height: 16.h),
            // Text(
            //   'Unable to fetch bill',
            //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //         fontWeight: FontWeight.bold,
            //         color: AppColors.textPrimary,
            //       ),
            // ),
            SizedBox(height: 8.h),
            Text(
              message.trim().isEmpty
                  ? 'We couldn\u2019t fetch your bill right now. Please recheck the details and try again in a moment.'
                  : message.trim(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.75),
                  ),
            ),
            SizedBox(height: 22.h),
            SizedBox(
              width: double.infinity,
              child: CustomElevatedButton(
                onPressed: onContinue,
                label: 'Got it',
                uppercaseLabel: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isLastFourParam(String name) {
  final normalized = name.toLowerCase();
  return normalized.contains('last 4') ||
      normalized.contains('last4') ||
      normalized.contains('last four') ||
      normalized.contains('last digits');
}

bool _isMobileParam(String name) {
  final normalized = name.toLowerCase();
  return normalized.contains('mobile') ||
      normalized.contains('phone') ||
      normalized.contains('contact');
}

bool _isIdentifierParam(String name, String dataType) {
  final normalized = name.toLowerCase();
  final isNumeric = dataType.toUpperCase() == 'NUMERIC';
  if (!isNumeric) return false;
  return normalized.contains('customer') ||
      normalized.contains('consumer') ||
      normalized.contains('account') ||
      normalized.contains('service') ||
      normalized.contains('subscriber') ||
      normalized.contains('ca') ||
      normalized.contains('connection');
}

String _sanitizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length > 10) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}

Future<String?> _pickContactNumber(
    BuildContext context, PermissionService permissionService,
    {required ContactsCacheController contactsController}) async {
  final status = await Permission.contacts.status;
  if (status.isPermanentlyDenied) {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contacts permission'),
          content: const Text(
            'Contacts permission is required to pick a number.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
    if (openSettings == true) {
      await openAppSettings();
    }
    return null;
  }

  final granted = status.isGranted || await permissionService.requestContacts();
  if (!granted) {
    AppSnackbar.show(
      'Contacts permission is required.',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return null;
  }

  // Open the sheet immediately; contacts load inside via cache controller.
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (context) {
      return _ContactPickerSheetHost(
        onReload: contactsController.reload,
        onEnsureLoaded: contactsController.fetchIfNeeded,
      );
    },
  );
}

class _ContactPickerSheetHost extends HookConsumerWidget {
  const _ContactPickerSheetHost({
    required this.onReload,
    required this.onEnsureLoaded,
  });

  final Future<void> Function() onReload;
  final Future<void> Function() onEnsureLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactsCacheControllerProvider);

    useEffect(() {
      Future.microtask(onEnsureLoaded);
      return null;
    }, const []);

    final contacts = state.contacts;
    final isLoading = state.isLoading;
    final error = state.errorMessage;

    if (isLoading && contacts.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            SizedBox(height: 24.r,
              width: 24.r,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 10.h),
            Text('Loading contacts...'),
          ],
        ),
      );
    }

    if (error != null && error.isNotEmpty && contacts.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load contacts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReload,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      );
    }

    return _ContactPickerSheet(contacts: contacts);
  }
}

// double _resolvedPayAmount(
//   TextEditingController controller,
//   BillResponse bill,
// ) {
//   final entered = _parseEnteredAmount(controller.text);
//   if (entered != null && entered > 0) return entered;
//   return bill.amountInRupees;
// }

double? _parseEnteredAmount(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

class _ContactPickerSheet extends StatefulWidget {
  const _ContactPickerSheet({required this.contacts});

  final List<Contact> contacts;

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = widget.contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phone =
          contact.phones.isNotEmpty ? contact.phones.first.number : '';
      return name.contains(query) || phone.contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44.w,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Select Contact',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: 12.h),
          SearchTextfield(
            hintText: 'Search contacts',
            controller: _searchController,
            onChange: (value) => setState(() => _query = value),
          ),
          SizedBox(height: 12.h),
          Flexible(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No contacts found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.6),
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.textPrimary.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final contact = filtered[index];
                      final phone = contact.phones.isNotEmpty
                          ? contact.phones.first.number
                          : '';
                      return ListTile(
                        title: Text(contact.displayName),
                        subtitle: Text(phone),
                        onTap: phone.isEmpty
                            ? null
                            : () => Navigator.of(context)
                                .pop(_sanitizePhone(phone)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompactBillSection extends StatelessWidget {
  const _CompactBillSection({
    required this.bill,
    required this.customerParams,
    required this.billAmountController,
    required this.onToggle,
    required this.selectedAmountType,
    required this.onAmountTypeChanged,
    required this.totalOutstanding,
    required this.minimumDue,
    required this.isCreditCardFlow,
    required this.isPipedGas,
    this.allowCustomAmount = false,
    this.minimumCustomAmount,
    this.maximumCustomAmount,
    this.isElectricity = false,
    this.showFullDetailsInline = false,
    this.hideAmountDisplayCard = false,
  });

  final BillResponse bill;
  final Map<String, String> customerParams;
  final TextEditingController billAmountController;
  final VoidCallback onToggle;
  final _PaymentAmountType selectedAmountType;
  final ValueChanged<_PaymentAmountType> onAmountTypeChanged;
  final double? totalOutstanding;
  final double? minimumDue;
  final bool isCreditCardFlow;
  final bool isPipedGas;
  final bool allowCustomAmount;
  final double? minimumCustomAmount;
  final double? maximumCustomAmount;
  final bool isElectricity;
  final bool showFullDetailsInline;
  final bool hideAmountDisplayCard;

  @override
  Widget build(BuildContext context) {
    if (isCreditCardFlow) {
      final total = totalOutstanding ?? bill.amountInRupees;
      return CreditCardPayNowSection(
        bill: bill,
        totalOutstanding: total,
        minimumDue: minimumDue,
        selected: switch (selectedAmountType) {
          _PaymentAmountType.totalOutstanding =>
            CreditCardPayNowAmountType.total,
          _PaymentAmountType.minimumDue => CreditCardPayNowAmountType.minimum,
          _PaymentAmountType.custom => CreditCardPayNowAmountType.custom,
        },
        onChanged: (next) {
          onAmountTypeChanged(
            switch (next) {
              CreditCardPayNowAmountType.total =>
                _PaymentAmountType.totalOutstanding,
              CreditCardPayNowAmountType.minimum =>
                _PaymentAmountType.minimumDue,
              CreditCardPayNowAmountType.custom => _PaymentAmountType.custom,
            },
          );
        },
        amountController: billAmountController,
      );
    }

    if (isPipedGas) {
      return PipedGasBillSection(
        bill: bill,
        customerParams: customerParams,
        amountController: billAmountController,
      );
    }

    // Pick "Early Payment Date" from additionalParams if available
    final earlyPayDate = bill.additionalParams['Early Payment Date'] ?? '';
    final pc = bill.additionalParams['PC'] ?? '';
    final note = bill.note.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Details card (Electricity: white + arrow on card)
        (showFullDetailsInline && !isCreditCardFlow && !isPipedGas)
            ? _FullDetailsSection(
                bill: bill,
                customerParams: customerParams,
                onToggle: () {},
                showToggle: false,
              )
            : isElectricity
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE2E2E2)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 14.r,
                              offset: Offset(0.w, 6.h),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ...customerParams.entries.map(
                              (entry) => _ColonInfoRow(
                                label: entry.key,
                                value: entry.value,
                              ),
                            ),
                            if (earlyPayDate.isNotEmpty)
                              _ColonInfoRow(
                                label: 'Early Payment Date',
                                value: earlyPayDate,
                              ),
                            if (pc.isNotEmpty)
                              _ColonInfoRow(
                                label: 'PC',
                                value: pc,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: -20,
                        child: _ToggleArrowButton(
                          isExpanded: false,
                          onTap: onToggle,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Column(
                          children: [
                            ...customerParams.entries.map(
                              (entry) => _InfoRow(
                                  label: entry.key, value: entry.value),
                            ),
                            if (earlyPayDate.isNotEmpty)
                              _InfoRow(
                                label: 'Early Payment Date',
                                value: earlyPayDate,
                              ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: _ToggleArrowButton(
                            isExpanded: false,
                            onTap: onToggle,
                          ),
                        ),
                      ),
                    ],
                  ),

        // Amount card (orange border)
        if (!hideAmountDisplayCard)
          Padding(
            padding: EdgeInsets.only(top: isElectricity ? 22 : 0),
            child: _AmountDisplayCard(bill: bill),
          ),

        SizedBox(height: 16.h),

        // Additional fee note (prefer API `note` for Electricity)
        if (isElectricity && note.isNotEmpty) ...[
          _AdditionalNoteCard(text: note),
          SizedBox(height: 20.h),
        ] else if (!isElectricity && bill.latePaymentFormatted.isNotEmpty) ...[
          Text(
            'Payments made after ${bill.dueDate} will incur an additional charge of ${_additionalCharge()}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  height: 1.5,
                ),
          ),
          SizedBox(height: 20.h),
        ],

        SizedBox(height: 8.h),

        // Bill Amount field
        Text(
          'Bill Amount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8.h),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: billAmountController,
          builder: (context, value, _) {
            final amountError = allowCustomAmount
                ? _validateCustomAmount(
                    value.text,
                    minimumCustomAmount: minimumCustomAmount,
                    maximumCustomAmount: maximumCustomAmount,
                  )
                : null;
            return TextField(
              controller: billAmountController,
              keyboardType: TextInputType.number,
              readOnly: !allowCustomAmount,
              onTap: () {
                billAmountController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: billAmountController.text.length,
                );
              },
              inputFormatters: [
                if (allowCustomAmount)
                  FilteringTextInputFormatter.digitsOnly
                else
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (nextValue) {
                if (selectedAmountType != _PaymentAmountType.custom) {
                  onAmountTypeChanged(_PaymentAmountType.custom);
                }
                if (!allowCustomAmount) return;
                final parsed = _parseEnteredAmount(nextValue);
                if (maximumCustomAmount != null &&
                    parsed != null &&
                    parsed > maximumCustomAmount!) {
                  final trimmed = nextValue.substring(
                    0,
                    nextValue.length - 1,
                  );
                  billAmountController.value = TextEditingValue(
                    text: trimmed,
                    selection: TextSelection.collapsed(
                      offset: trimmed.length,
                    ),
                  );
                }
              },
              onEditingComplete: () {
                if (selectedAmountType != _PaymentAmountType.custom) {
                  onAmountTypeChanged(_PaymentAmountType.custom);
                }
              },
              decoration: InputDecoration(
                prefixText: '\u20B9  ',
                errorText: amountError,
                prefixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              ),
            );
          },
        ),
        if (allowCustomAmount &&
            (minimumCustomAmount != null || maximumCustomAmount != null)) ...[
          SizedBox(height: 8.h),
          Text(
            [
              if (minimumCustomAmount != null)
                'Minimum recharge amount: ₹${_formatAmountForInput(minimumCustomAmount!)}',
              if (maximumCustomAmount != null)
                'Maximum recharge amount: ₹${_formatAmountForInput(maximumCustomAmount!)}',
            ].join('  •  '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
          ),
        ],
      ],
    );
  }

  String _additionalCharge() {
    // late payment amount – bill amount
    final late =
        (int.tryParse(bill.otherDetails['Late Payment Amount'] ?? '') ?? 0) /
            100;
    final base = bill.amountInRupees;
    final diff = late - base;
    if (diff > 0) {
      return '\u20B9${diff.toStringAsFixed(0)}';
    }
    return bill.latePaymentFormatted;
  }
}

// ─── Amount Display Card ─────────────────────────────────────────────────────

class _AmountDisplayCard extends StatelessWidget {
  const _AmountDisplayCard({required this.bill});

  final BillResponse bill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: bill period chip + due date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_hasValidBillPeriod(_resolveBillMonth(bill)))
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Bill for ${_formatBillPeriod(_resolveBillMonth(bill))}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              if (bill.dueDate.isNotEmpty)
                Text(
                  'Due on: ${DateFormatHelper.formatDisplayDate(bill.dueDate)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.red,
                        fontWeight: FontWeight.w700,
                      ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          // Amount
          Text(
            _resolvedAmountText(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  /// Turn "2509" → "Sep '25", or return as-is
  String _formatBillPeriod(String period) {
    if (period.length == 4) {
      final yy = period.substring(0, 2);
      final mm = int.tryParse(period.substring(2));
      if (mm != null && mm >= 1 && mm <= 12) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return "${months[mm - 1]} '$yy";
      }
    }
    return period;
  }

  String _resolveBillMonth(BillResponse bill) {
    final fromAdditional = bill.additionalParams['Bill Month']?.trim() ?? '';
    if (fromAdditional.isNotEmpty) return fromAdditional;
    return bill.billPeriod.trim();
  }

  bool _hasValidBillPeriod(String period) {
    final value = period.trim().toLowerCase();
    if (value.isEmpty) return false;
    if (value == 'na' || value == 'n/a' || value == 'null') return false;
    if (value == '-' || value == '--') return false;
    return true;
  }

  String _resolvedAmountText() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final earlyDate = _parseDueDate(
      bill.additionalParams['Early Payment Date'] ?? '',
    );
    final dueDate = _parseDueDate(bill.dueDate);

    // On or before early payment date → show early payment amount
    final earlyAmount =
        _parseAmountMaybe(bill.otherDetails['Early Payment Amount']);
    if (earlyDate != null &&
        earlyAmount != null &&
        !todayDate.isAfter(earlyDate)) {
      return _formatRupees(earlyAmount);
    }

    // After due date → show late payment amount
    final lateAmount =
        _parseAmountMaybe(bill.otherDetails['Late Payment Amount']);
    if (dueDate != null && lateAmount != null && todayDate.isAfter(dueDate)) {
      return _formatRupees(lateAmount);
    }

    // Between early payment date and due date → regular amount
    return bill.formattedAmount;
  }

  DateTime? _parseDueDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) {
      return iso.isUtc ? iso.toLocal() : iso;
    }

    final numeric = RegExp(r'^(\\d{1,2})[./-](\\d{1,2})[./-](\\d{2,4})$');
    final match = numeric.firstMatch(value);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      var year = int.tryParse(match.group(3) ?? '');
      if (day == null || month == null || year == null) return null;
      if (year < 100) year += 2000;
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    }
    return null;
  }

  String _formatRupees(double amount) {
    return '\u20B9${amount.toStringAsFixed(2)}';
  }
}

// ─── Full Details Section ────────────────────────────────────────────────────

class _FullDetailsSection extends StatelessWidget {
  const _FullDetailsSection({
    required this.bill,
    required this.customerParams,
    required this.onToggle,
    this.showToggle = true,
  });

  final BillResponse bill;
  final Map<String, String> customerParams;
  final VoidCallback onToggle;
  final bool showToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E2E2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12.r,
                    offset: Offset(0.w, 4.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Customer params
                  ...customerParams.entries.map(
                    (entry) =>
                        _ColonInfoRow(label: entry.key, value: entry.value),
                  ),

                  // All additional params
                  ...bill.additionalParams.entries.map(
                    (e) => _ColonInfoRow(label: e.key, value: e.value),
                  ),

                  // Account holder / Customer Name
                  if (bill.accountHolderName.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Customer Name',
                      value: bill.accountHolderName,
                    ),

                  // Due Date
                  if (bill.dueDate.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Due Date',
                      value: DateFormatHelper.formatDisplayDate(bill.dueDate),
                    ),

                  // Early payment date & amount
                  if (bill.earlyPaymentFormatted.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Early payment date & amount',
                      value: _earlyPaymentText(),
                    ),

                  // Due payment date & amount
                  if (bill.dueDate.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Due payment date & amount',
                      value: _duePaymentText(),
                    ),

                  // Late payment date & amount
                  if (bill.latePaymentFormatted.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Late payment date & amount',
                      value: _latePaymentText(),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -21,
              child: showToggle
                  ? Center(
                      child: _ToggleArrowButton(
                        isExpanded: true,
                        onTap: onToggle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        SizedBox(height: showToggle ? 24 : 0),
      ],
    );
  }

  String _earlyPaymentText() {
    final earlyDate = bill.additionalParams['Early Payment Date'] ?? '';
    if (earlyDate.isNotEmpty) {
      return 'Before $earlyDate - ${bill.earlyPaymentFormatted}';
    }
    return bill.earlyPaymentFormatted;
  }

  String _duePaymentText() {
    final earlyDate = bill.additionalParams['Early Payment Date'] ?? '';
    final dueDate = bill.dueDate;
    final amount = bill.earlyPaymentFormatted.isNotEmpty
        ? bill.earlyPaymentFormatted
        : bill.formattedAmount;
    if (earlyDate.isNotEmpty && dueDate.isNotEmpty) {
      return '$earlyDate to $dueDate - $amount';
    }
    return '$dueDate - $amount';
  }

  String _latePaymentText() {
    final dueDate = bill.dueDate;
    if (dueDate.isNotEmpty) {
      return 'After $dueDate - ${bill.latePaymentFormatted}';
    }
    return bill.latePaymentFormatted;
  }
}

// ─── Toggle Arrow Button ─────────────────────────────────────────────────────

class _ToggleArrowButton extends StatelessWidget {
  const _ToggleArrowButton({
    required this.isExpanded,
    required this.onTap,
  });

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38.r,
          height: 38.r,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF835C),
                Color(0xFFDD5428),
              ],
            ),
          ),
          child: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 24.r,
          ),
        ));
  }
}

class _ColonInfoRow extends StatelessWidget {
  const _ColonInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            ':',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdditionalNoteCard extends StatelessWidget {
  const _AdditionalNoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F4),
        borderRadius: BorderRadius.circular(14.r),
        border:
            Border.all(color: const Color(0xFFE85A2C).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.info_outline,
              color: Color(0xFFE85A2C),
              size: 18,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PaymentAmountType {
  totalOutstanding,
  minimumDue,
  custom,
}

/// Returns the amount to display/pay based on today's date vs early/due dates.
double _resolveDateBasedAmount(BillResponse bill) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  final earlyDate = _parseDateString(
    bill.additionalParams['Early Payment Date'] ?? '',
  );
  final dueDate = _parseDateString(bill.dueDate);

  final earlyAmount =
      _parseAmountMaybe(bill.otherDetails['Early Payment Amount']);
  if (earlyDate != null &&
      earlyAmount != null &&
      !todayDate.isAfter(earlyDate)) {
    return earlyAmount;
  }

  final lateAmount =
      _parseAmountMaybe(bill.otherDetails['Late Payment Amount']);
  if (dueDate != null && lateAmount != null && todayDate.isAfter(dueDate)) {
    return lateAmount;
  }

  return bill.amountInRupees;
}

String _formatAmountForInput(double amount) {
  final fixed = amount.toStringAsFixed(2);
  return fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

DateTime? _parseDateString(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final iso = DateTime.tryParse(value);
  if (iso != null) return iso.isUtc ? iso.toLocal() : iso;
  final numeric = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})$');
  final match = numeric.firstMatch(value);
  if (match != null) {
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    var year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }
  return null;
}

double _resolveTotalOutstanding(BillResponse bill) {
  final amount = _extractAmountFromDetails(
    bill,
    const [
      'Total Outstanding',
      'Total Outstanding Amount',
      'Total Amount Due',
      'Total Due',
      'Outstanding Amount',
      'Total Amount',
    ],
  );
  return amount ?? bill.amountInRupees;
}

double? _resolveMinimumDue(BillResponse bill) {
  return _extractAmountFromDetails(
    bill,
    const [
      'Minimum Amount Due',
      'Minimum Payable Amount',
      'MinimumDueAmount',
      'Minimum Due',
      'Minimum Payment',
      'Min Payable Amount',
      'Min Amount Due',
      'Min Due',
    ],
  );
}

double? _resolveFastTagMinAmount(BillResponse bill) {
  return _extractAmountFromDetails(
    bill,
    const [
      'MinimumRechargeAmount',
      'Minimum Recharge Amount',
      'Minimum Recharge',
      'Min Recharge Amount',
    ],
  );
}

double? _resolveFastTagMaxAmount(BillResponse bill) {
  return _extractAmountFromDetails(
    bill,
    const [
      'Maximum Permissible Recharge Amount',
      'MaximumPermissibleRechargeAmount',
      'Maximum Recharge Amount',
      'Max Recharge Amount',
    ],
  );
}

String? _validateCustomAmount(
  String rawValue, {
  double? minimumCustomAmount,
  double? maximumCustomAmount,
}) {
  final amount = _parseEnteredAmount(rawValue);
  if (amount == null) return null;
  if (minimumCustomAmount != null && amount < minimumCustomAmount) {
    return 'Minimum recharge amount is ₹${_formatAmountForInput(minimumCustomAmount)}';
  }
  if (maximumCustomAmount != null && amount > maximumCustomAmount) {
    return 'Maximum recharge amount is ₹${_formatAmountForInput(maximumCustomAmount)}';
  }
  return null;
}

double? _extractAmountFromDetails(BillResponse bill, List<String> keys) {
  double? scanMap(Map<String, String> source) {
    for (final key in keys) {
      final direct = source[key];
      final parsed = _parseAmountMaybe(direct);
      if (parsed != null) return parsed;
    }
    for (final entry in source.entries) {
      final normalized = entry.key.trim().toLowerCase();
      for (final key in keys) {
        if (normalized == key.toLowerCase()) {
          final parsed = _parseAmountMaybe(entry.value);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  final fromOther = scanMap(bill.otherDetails);
  if (fromOther != null) return fromOther;

  final fromAdditional = scanMap(bill.additionalParams);
  if (fromAdditional != null) return fromAdditional;

  return null;
}

double? _parseAmountMaybe(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null) return null;
  if (raw.contains('.')) return value;
  if (cleaned.length > 4) return value / 100;
  return value;
}
