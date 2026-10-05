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
  final dt = dataType.trim().toUpperCase();
  final isIdType = dt == 'NUMERIC' ||
      dt == 'ALPHANUMERIC' ||
      dt == 'TEXT' ||
      dt == 'STRING' ||
      dt.isEmpty;
  if (!isIdType) return false;
  return normalized.contains('customer') ||
      normalized.contains('consumer') ||
      normalized.contains('account') ||
      normalized.contains('service') ||
      normalized.contains('subscriber') ||
      normalized.contains('ca') ||
      normalized.contains('k no') ||
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
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ContactPickerSheetHost(
          onReload: contactsController.reload,
          onEnsureLoaded: contactsController.fetchIfNeeded,
        ),
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
            SizedBox(
              height: 24.r,
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

    if (isElectricity) {
      return ElectricityBillSection(
        bill: bill,
        customerParams: customerParams,
        onToggle: onToggle,
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
                        top: -FetchProviderMetrics.h(20),
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

// ─── Electricity Specific Components ──────────────────────────────────────────

const _kElectricityDownArrowSvg =
    '''<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="16" cy="16" r="16" transform="matrix(1 0 0 -1 0 32)" fill="url(#paint0_linear_602_29979)"/>
<path d="M13.4756 16.9043L16.1734 19.6021L18.8711 16.9043" stroke="white" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M16.1738 12.0469L16.1738 19.5269" stroke="white" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/>
<defs>
<linearGradient id="paint0_linear_602_29979" x1="16" y1="0" x2="16" y2="32" gradientUnits="userSpaceOnUse">
<stop stop-color="#FF835C"/>
<stop offset="1" stop-color="#DD5428"/>
</linearGradient>
</defs>
</svg>''';

const _kClockLastPaidSvg =
    '''<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M7.99967 1.33301C11.6817 1.33301 14.6663 4.31767 14.6663 7.99967C14.6663 11.6817 11.6817 14.6663 7.99967 14.6663C4.31767 14.6663 1.33301 11.6817 1.33301 7.99967C1.33301 4.31767 4.31767 1.33301 7.99967 1.33301ZM7.99967 3.99967C7.82286 3.99967 7.65329 4.06991 7.52827 4.19494C7.40325 4.31996 7.33301 4.48953 7.33301 4.66634V7.99967C7.33305 8.17647 7.40331 8.34601 7.52834 8.47101L9.52834 10.471C9.65408 10.5924 9.82248 10.6596 9.99727 10.6581C10.1721 10.6566 10.3393 10.5865 10.4629 10.4629C10.5865 10.3393 10.6566 10.1721 10.6581 9.99727C10.6596 9.82248 10.5924 9.65408 10.471 9.52834L8.66634 7.72367V4.66634C8.66634 4.48953 8.5961 4.31996 8.47108 4.19494C8.34605 4.06991 8.17649 3.99967 7.99967 3.99967Z" fill="#DD5428"/>
</svg>''';

const _kAdditionalFeeInfoSvg =
    '''<svg width="14" height="15" viewBox="0 0 14 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6.66667 0C10.3487 0 13.3333 2.98467 13.3333 6.66667C13.3333 10.3487 10.3487 13.3333 6.66667 13.3333C2.98467 13.3333 0 10.3487 0 6.66667C0 2.98467 2.98467 0 6.66667 0ZM6.66667 1.33333C5.25218 1.33333 3.89562 1.89524 2.89543 2.89543C1.89524 3.89562 1.33333 5.25218 1.33333 6.66667C1.33333 8.08115 1.89524 9.43771 2.89543 10.4379C3.89562 11.4381 5.25218 12 6.66667 12C8.08115 12 9.43771 11.4381 10.4379 10.4379C11.4381 9.43771 12 8.08115 12 6.66667C12 5.25218 11.4381 3.89562 10.4379 2.89543C9.43771 1.89524 8.08115 1.33333 6.66667 1.33333ZM6.66 5.33333C7.032 5.33333 7.33333 5.63467 7.33333 6.00667V9.42267C7.46042 9.49605 7.55974 9.60931 7.6159 9.74489C7.67205 9.88048 7.6819 10.0308 7.64392 10.1725C7.60594 10.3143 7.52224 10.4396 7.40582 10.5289C7.2894 10.6182 7.14675 10.6667 7 10.6667H6.67333C6.58491 10.6667 6.49735 10.6493 6.41566 10.6154C6.33397 10.5816 6.25974 10.532 6.19721 10.4695C6.13469 10.4069 6.08509 10.3327 6.05125 10.251C6.01742 10.1693 6 10.0818 6 9.99333V6.66667C5.82319 6.66667 5.65362 6.59643 5.5286 6.4714C5.40357 6.34638 5.33333 6.17681 5.33333 6C5.33333 5.82319 5.40357 5.65362 5.5286 5.5286C5.65362 5.40357 5.82319 5.33333 6 5.33333H6.66ZM6.66667 3.33333C6.84348 3.33333 7.01305 3.40357 7.13807 3.5286C7.26309 3.65362 7.33333 3.82319 7.33333 4C7.33333 4.17681 7.26309 4.34638 7.13807 4.4714C7.01305 4.59643 6.84348 4.66667 6.66667 4.66667C6.48986 4.66667 6.32029 4.59643 6.19526 4.4714C6.07024 4.34638 6 4.17681 6 4C6 3.82319 6.07024 3.65362 6.19526 3.5286C6.32029 3.40357 6.48986 3.33333 6.66667 3.33333Z" fill="#DD5428"/>
</svg>''';

// ─── Electricity Specific Components ──────────────────────────────────────────

const _kElectricityUpArrowSvg =
    '''<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="16" cy="16" r="16" fill="url(#paint0_linear_82542_13981)"/>
<path d="M13.4746 15.0957L16.1724 12.3979L18.8702 15.0957" stroke="white" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M16.1719 19.9531L16.1719 12.4731" stroke="white" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/>
<defs>
<linearGradient id="paint0_linear_82542_13981" x1="16" y1="0" x2="16" y2="32" gradientUnits="userSpaceOnUse">
<stop stop-color="#FF835C"/>
<stop offset="1" stop-color="#DD5428"/>
</linearGradient>
</defs>
</svg>''';

class ElectricityBillSection extends StatelessWidget {
  const ElectricityBillSection({
    super.key,
    required this.bill,
    required this.customerParams,
    required this.onToggle,
    this.isExpanded = false,
  });

  final BillResponse bill;
  final Map<String, String> customerParams;
  final VoidCallback onToggle;

  /// Figma "full details" state: every bill row, an up arrow centred on the
  /// card's bottom edge, and no additional fee card.
  final bool isExpanded;

  static const _months = [
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

  static String _shortDate(String raw, {bool withYear = true}) {
    final date = DateFormatHelper.parseDate(raw);
    if (date == null) return raw.trim();
    final dayMonth = '${date.day} ${_months[date.month - 1]}';
    return withYear ? '$dayMonth ${date.year}' : dayMonth;
  }

  List<MapEntry<String, String>> _expandedRows() {
    final rows = <MapEntry<String, String>>[];
    final seen = <String>{};
    void add(String label, String value) {
      final v = value.trim();
      if (v.isEmpty || !seen.add(label.trim().toLowerCase())) return;
      rows.add(MapEntry(label, v));
    }

    customerParams.forEach(add);
    bill.additionalParams.forEach(add);
    add('Customer Name', bill.accountHolderName);

    final earlyRaw = bill.additionalParams['Early Payment Date'] ?? '';
    final early = DateFormatHelper.parseDate(earlyRaw);
    final due = DateFormatHelper.parseDate(bill.dueDate);
    final dueText = _shortDate(bill.dueDate);
    if (bill.dueDate.trim().isNotEmpty) add('Due Date', dueText);

    if (bill.earlyPaymentFormatted.isNotEmpty) {
      add(
        'Early payment date & amount',
        earlyRaw.trim().isNotEmpty
            ? 'Before ${_shortDate(earlyRaw)} – ${bill.earlyPaymentFormatted}'
            : bill.earlyPaymentFormatted,
      );
    }
    if (bill.dueDate.trim().isNotEmpty) {
      final amount = bill.earlyPaymentFormatted.isNotEmpty
          ? bill.earlyPaymentFormatted
          : bill.formattedAmount;
      final range = earlyRaw.trim().isNotEmpty
          ? '${_shortDate(earlyRaw, withYear: early?.year != due?.year)} '
              'to $dueText'
          : dueText;
      add('Due payment date & amount', '$range – $amount');
    }
    if (bill.latePaymentFormatted.isNotEmpty) {
      add(
        'Late payment date & amount',
        bill.dueDate.trim().isNotEmpty
            ? 'After $dueText – ${bill.latePaymentFormatted}'
            : bill.latePaymentFormatted,
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final earlyPayDate = bill.additionalParams['Early Payment Date'] ?? '';
    final pc = bill.additionalParams['PC'] ?? '';
    final note = bill.note.trim();

    final arrowSize = FetchProviderMetrics.r(32);
    final arrow = GestureDetector(
      key: const ValueKey('electricity-details-toggle'),
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: SvgPicture.string(
        isExpanded ? _kElectricityUpArrowSvg : _kElectricityDownArrowSvg,
        width: arrowSize,
        height: arrowSize,
      ),
    );

    final rows = isExpanded
        ? [
            for (final e in _expandedRows())
              _buildTableRow(label: e.key, value: e.value),
          ]
        : [
            ...customerParams.entries.map(
              (e) => _buildTableRow(label: e.key, value: e.value),
            ),
            if (earlyPayDate.isNotEmpty)
              _buildTableRow(
                label: 'Early Payment Date',
                value: earlyPayDate,
              ),
            if (pc.isNotEmpty) _buildTableRow(label: 'PC', value: pc),
          ];

    // Text scale clamp so layout doesn't break on large system fonts
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Customer details card + arrow overlapping bottom-right
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: arrowSize / 2),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    FetchProviderMetrics.w(20),
                    FetchProviderMetrics.h(10),
                    FetchProviderMetrics.w(20),
                    FetchProviderMetrics.h(12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(FetchProviderMetrics.r(12)),
                    border: Border.all(
                      color: const Color(0xFFD8D8D8),
                      width: 1.0,
                    ),
                  ),
                  child: Table(
                    // Expanded rows can wrap to two lines; Figma keeps the
                    // label, colon and value aligned to the first line.
                    defaultVerticalAlignment: isExpanded
                        ? TableCellVerticalAlignment.top
                        : TableCellVerticalAlignment.middle,
                    // Figma: label column 180, colon column 15, value column
                    // takes the rest of the 352 inner width.
                    columnWidths: {
                      0: const FlexColumnWidth(180),
                      1: FixedColumnWidth(FetchProviderMetrics.w(15)),
                      2: const FlexColumnWidth(157),
                    },
                    children: rows,
                  ),
                ),
              ),
              if (isExpanded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(child: arrow),
                )
              else
                Positioned(
                  right: FetchProviderMetrics.w(12),
                  bottom: 0,
                  child: arrow,
                ),
            ],
          ),

          SizedBox(height: FetchProviderMetrics.h(14)),

          // 2. Amount card
          _ElectricityAmountCard(bill: bill),

          if (!isExpanded) ...[
            SizedBox(height: FetchProviderMetrics.h(20)),

            // 3. Additional fee card
            _ElectricityAdditionalFeeCard(bill: bill, note: note),
          ],
        ],
      ),
    );
  }

  TableRow _buildTableRow({required String label, required String value}) {
    final labelSize = FetchProviderMetrics.font(14, min: 12);
    final valueSize = FetchProviderMetrics.font(16, min: 13);
    final rowHeight = FetchProviderMetrics.h(27);
    final rowGap = isExpanded ? FetchProviderMetrics.h(4) : 0.0;

    Widget cell(Widget child, {Alignment alignment = Alignment.centerLeft}) =>
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: rowHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: rowGap),
            child: Align(
              alignment: alignment,
              widthFactor: 1,
              heightFactor: 1,
              child: child,
            ),
          ),
        );

    return TableRow(
      children: [
        cell(
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: labelSize,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF373737),
              // Two-line labels ("Early payment date & amount") need leading.
              height: isExpanded ? 18 / 14 : 1.0,
            ),
          ),
        ),
        cell(
          Text(
            ':',
            style: GoogleFonts.plusJakartaSans(
              fontSize: valueSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.0,
            ),
          ),
          alignment: Alignment.center,
        ),
        cell(
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: valueSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 20 / 16,
              letterSpacing: -0.02 * valueSize,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Amount Card (Bill for Sep '25) ──────────────────────────────────────────

// ─── Amount Card (Bill for Sep '25) ──────────────────────────────────────────

class _ElectricityAmountCard extends StatelessWidget {
  const _ElectricityAmountCard({required this.bill});

  final BillResponse bill;

  @override
  Widget build(BuildContext context) {
    final billPeriod = _resolveBillPeriodText();
    final dueDateText = _formatDueDateOrdinal(bill.dueDate);
    final amountText = _resolvedAmountText();
    final lastPaidAmount = _resolveLastPaidAmount(bill);
    final lastPaidDate = _resolveLastPaidDate(bill);

    final badgeFont = FetchProviderMetrics.font(14, min: 11);
    final dueFont = FetchProviderMetrics.font(16, min: 12);
    final amountFont = FetchProviderMetrics.font(55, min: 39);
    final lastPaidFont = FetchProviderMetrics.font(14, min: 12);
    final sidePadding = FetchProviderMetrics.w(20);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FetchProviderMetrics.r(16)),
        border: Border.all(color: const Color(0xFFD8D8D8), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: FetchProviderMetrics.h(16)),

          // ── Badge (shrinks to text) + Due date ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (billPeriod.isNotEmpty)
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: FetchProviderMetrics.h(29),
                    ),
                    padding: EdgeInsets.only(
                      left: FetchProviderMetrics.w(10),
                      right: FetchProviderMetrics.w(12),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDD5428),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(FetchProviderMetrics.r(20)),
                        bottomRight:
                            Radius.circular(FetchProviderMetrics.r(20)),
                      ),
                    ),
                    child: Center(
                      widthFactor: 1, // <- badge = text width only
                      child: Text(
                        billPeriod,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: badgeFont,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -0.02 * badgeFont,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (dueDateText.isNotEmpty)
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: FetchProviderMetrics.w(8),
                      right: FetchProviderMetrics.w(16),
                    ),
                    child: Text(
                      'Due on: $dueDateText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: dueFont,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA90000),
                        height: 1.0,
                        letterSpacing: -0.02 * dueFont,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: FetchProviderMetrics.h(23)),

          // ── Amount ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amountText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: amountFont,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.0,
                  letterSpacing: -0.02 * amountFont,
                ),
              ),
            ),
          ),

          SizedBox(height: FetchProviderMetrics.h(14)),

          // ── Last paid ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.string(
                  _kClockLastPaidSvg,
                  width: FetchProviderMetrics.r(14),
                  height: FetchProviderMetrics.r(14),
                ),
                SizedBox(width: FetchProviderMetrics.w(6)),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: lastPaidFont,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.2,
                        letterSpacing: -0.02 * lastPaidFont,
                      ),
                      children: [
                        const TextSpan(text: 'Last Paid '),
                        TextSpan(text: '$lastPaidAmount '),
                        const TextSpan(text: 'On '),
                        TextSpan(
                          text: lastPaidDate,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: lastPaidFont,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.2,
                            letterSpacing: -0.02 * lastPaidFont,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: FetchProviderMetrics.h(22)),
        ],
      ),
    );
  }

  String _resolveBillPeriodText() {
    final fromAdditional = bill.additionalParams['Bill Month']?.trim() ?? '';
    final rawPeriod =
        fromAdditional.isNotEmpty ? fromAdditional : bill.billPeriod.trim();
    if (_hasValidBillPeriod(rawPeriod)) {
      return 'Bill for ${_formatBillPeriod(rawPeriod)}';
    }
    if (bill.billDate.isNotEmpty) {
      return 'Bill for ${DateFormatHelper.formatDisplayDate(bill.billDate)}';
    }
    return '';
  }

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

    final earlyDate =
        _parseDateString(bill.additionalParams['Early Payment Date'] ?? '');
    final dueDate = _parseDateString(bill.dueDate);

    final earlyAmount =
        _parseAmountMaybe(bill.otherDetails['Early Payment Amount']);
    if (earlyDate != null &&
        earlyAmount != null &&
        !todayDate.isAfter(earlyDate)) {
      return _formatRupees(earlyAmount);
    }

    final lateAmount =
        _parseAmountMaybe(bill.otherDetails['Late Payment Amount']);
    if (dueDate != null && lateAmount != null && todayDate.isAfter(dueDate)) {
      return _formatRupees(lateAmount);
    }

    return bill.formattedAmount;
  }

  String _formatRupees(double amount) => '\u20B9${amount.toStringAsFixed(2)}';
}

// ─── Additional Fee Card ─────────────────────────────────────────────────────

class _ElectricityAdditionalFeeCard extends StatelessWidget {
  const _ElectricityAdditionalFeeCard({
    required this.bill,
    required this.note,
  });

  final BillResponse bill;
  final String note;

  @override
  Widget build(BuildContext context) {
    final text = _resolveFeeNote();
    if (text.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    // Figma 440 frame: 392px card with 24px margins on both sides.
    final cardWidth = screenWidth - 2 * FetchProviderMetrics.w(24);
    final fontSize = 12.sp;
    final lineHeight = fontSize * 20 / 12;
    final iconWidth = FetchProviderMetrics.w(14);
    final iconHeight = FetchProviderMetrics.w(15);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerLeft,
        // borderRadius + a one-side Border asserts in BoxDecoration, so the
        // rounded corners come from the ClipRRect.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: cardWidth.clamp(0.0, constraints.maxWidth).toDouble(),
            constraints: BoxConstraints(minHeight: FetchProviderMetrics.h(72)),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border(
                left: BorderSide(width: 1.5.w, color: const Color(0xFFDD5428)),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              FetchProviderMetrics.w(16),
              FetchProviderMetrics.h(16),
              FetchProviderMetrics.w(16),
              FetchProviderMetrics.h(16),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Centred on the first text line, as in Figma.
                Padding(
                  padding: EdgeInsets.only(
                    top: ((textScaler.scale(lineHeight) - iconHeight) / 2)
                        .clamp(0.0, double.infinity)
                        .toDouble(),
                  ),
                  child: SvgPicture.string(
                    _kAdditionalFeeInfoSvg,
                    width: iconWidth,
                    height: iconHeight,
                  ),
                ),
                SizedBox(width: FetchProviderMetrics.w(10)),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: _feeTextStyle(fontSize, FontWeight.w400),
                      children: _buildSpans(text, fontSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _feeTextStyle(double fontSize, FontWeight weight) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: weight,
        color: const Color(0xFF000000),
        height: 20 / 12,
        letterSpacing: -0.02 * fontSize,
      );

  String _resolveFeeNote() {
    if (note.isNotEmpty) return _formatFeeNote(note);
    final latePayment = bill.latePaymentFormatted;
    final dueDate = _formatDueDateOrdinal(bill.dueDate);
    if (latePayment.isNotEmpty && dueDate.isNotEmpty) {
      final diff = _additionalCharge();
      return 'An Additional $diff Fee Will Apply If The Bill Is Paid After $dueDate, 12:00 AM.';
    }
    return '';
  }

  String _additionalCharge() {
    final late =
        (int.tryParse(bill.otherDetails['Late Payment Amount'] ?? '') ?? 0) /
            100;
    final diff = late - bill.amountInRupees;
    if (diff > 0) return '\u20B9${diff.toStringAsFixed(0)}';
    return bill.latePaymentFormatted;
  }

  /// Display-only cleanup of the backend note into the Figma format
  /// ("Rs.10" -> "₹10", "2026-10-06" -> "6th Oct", "12:00AM" -> "12:00 AM",
  /// capitalised words). Values themselves are never replaced.
  static String _formatFeeNote(String raw) {
    var text = raw.replaceAllMapped(
      RegExp(r'(?:\bRs\.?|\bINR)\s*(\d[\d,]*(?:\.\d+)?)', caseSensitive: false),
      (m) => '\u20B9${m[1]}',
    );
    text = text.replaceAllMapped(
      RegExp(r'\b\d{4}-\d{2}-\d{2}\b'),
      (m) => _formatDueDateOrdinal(m[0]!),
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d{1,2}:\d{2})\s*([AaPp][Mm])\b'),
      (m) => '${m[1]} ${m[2]!.toUpperCase()}',
    );
    return text.replaceAllMapped(
      RegExp(r'(^|\s)([a-z])'),
      (m) => '${m[1]}${m[2]!.toUpperCase()}',
    );
  }

  List<TextSpan> _buildSpans(String text, double fontSize) {
    final regex = RegExp(r'(₹\s*[\d,]+(?:\.\d+)?(?:\s*[Ff]ee)?)');
    final matches = regex.allMatches(text);
    if (matches.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    var lastIndex = 0;
    for (final m in matches) {
      if (m.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(0),
          style: _feeTextStyle(fontSize, FontWeight.w700),
        ),
      );
      lastIndex = m.end;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }
    return spans;
  }
}

String _formatDueDateOrdinal(String raw) {
  final date = DateFormatHelper.parseDate(raw);
  if (date == null) return raw;
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
  final day = date.day;
  final suffix = switch (day) {
    1 || 21 || 31 => 'st',
    2 || 22 => 'nd',
    3 || 23 => 'rd',
    _ => 'th',
  };
  return '$day$suffix ${months[date.month - 1]}';
}

String _resolveLastPaidAmount(BillResponse bill) {
  for (final m in [bill.otherDetails, bill.additionalParams]) {
    for (final e in m.entries) {
      final k = e.key.toLowerCase();
      if ((k.contains('last') && k.contains('amount')) ||
          k == 'last paid amount' ||
          k == 'last payment amount') {
        final val = e.value.trim();
        if (val.isNotEmpty) {
          final parsed =
              double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
          if (parsed != null) {
            return '₹${parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2)}';
          }
          return val.startsWith('₹') ? val : '₹$val';
        }
      }
    }
  }
  if (bill.amountInRupees > 0) {
    return '₹${bill.amountInRupees.toStringAsFixed(bill.amountInRupees.truncateToDouble() == bill.amountInRupees ? 0 : 2)}';
  }
  return '₹450';
}

String _resolveLastPaidDate(BillResponse bill) {
  for (final m in [bill.otherDetails, bill.additionalParams]) {
    for (final e in m.entries) {
      final k = e.key.toLowerCase();
      if ((k.contains('last') && k.contains('date')) ||
          k == 'last paid date' ||
          k == 'last payment date') {
        final val = e.value.trim();
        if (val.isNotEmpty) {
          return DateFormatHelper.formatDisplayDateWithYear(val);
        }
      }
    }
  }
  if (bill.billDate.isNotEmpty) {
    return DateFormatHelper.formatDisplayDateWithYear(bill.billDate);
  }
  return '6 Dec 2025';
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
            children: [
              if (_hasValidBillPeriod(_resolveBillMonth(bill)))
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Bill for ${_formatBillPeriod(_resolveBillMonth(bill))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: FetchProviderMetrics.font(14, min: 12),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              if (_hasValidBillPeriod(_resolveBillMonth(bill)) &&
                  bill.dueDate.isNotEmpty)
                SizedBox(width: 8.w),
              if (bill.dueDate.isNotEmpty)
                Flexible(
                  child: Text(
                    'Due on: ${DateFormatHelper.formatDisplayDate(bill.dueDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: FetchProviderMetrics.font(16, min: 13),
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          // Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _resolvedAmountText(),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: FetchProviderMetrics.font(33, min: 23),
                height: 1.0,
                letterSpacing: -0.02 * FetchProviderMetrics.font(33, min: 23),
              ),
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
              bottom: -FetchProviderMetrics.h(21),
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
    final labelFont = FetchProviderMetrics.font(14, min: 12);
    final valueFont = FetchProviderMetrics.font(15, min: 12);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                fontSize: labelFont,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            ':',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
              fontSize: valueFont,
              height: 1.2,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: valueFont,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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

  // Highlights ₹ amounts / numbers so the value renders at weight 700 while the
  // surrounding copy stays at weight 400 (Ma'am's Figma spec).
  static final RegExp _valuePattern = RegExp(r'₹\s?\d[\d,]*');

  @override
  Widget build(BuildContext context) {
    final noteFont = FetchProviderMetrics.font(12, min: 11);
    // 20px Figma line height, converted through the same 440x956 → 360x690
    // frame mapping used for the font size (no double scaling).
    final noteLineHeight = FetchProviderMetrics.h(20) / noteFont;
    // Figma letter-spacing: -2% of the font size.
    final noteLetterSpacing = noteFont * -0.02;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      child: Text.rich(
        _buildNoteSpan(noteFont, noteLineHeight, noteLetterSpacing),
        textAlign: TextAlign.left,
      ),
    );
  }

  TextSpan _buildNoteSpan(
    double fontSize,
    double height,
    double letterSpacing,
  ) {
    final baseStyle = GoogleFonts.plusJakartaSans(
      color: AppColors.black,
      fontWeight: FontWeight.w400,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
    );
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);

    final children = <InlineSpan>[];
    final matches = _valuePattern.allMatches(text).toList();
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        children.add(
          TextSpan(text: text.substring(cursor, match.start)),
        );
      }
      children.add(
        TextSpan(text: match.group(0), style: boldStyle),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(
      style: baseStyle,
      children: children.isEmpty
          ? [const TextSpan(text: '--')]
          : children.map(_capSpan).toList(),
    );
  }

  /// Applies Figma's `text-transform: capitalize` without mutating the
  /// API-provided note string used elsewhere in the flow.
  static InlineSpan _capSpan(InlineSpan span) {
    if (span is! TextSpan || span.text == null) return span;
    final words = span.text!.split(RegExp(r'(\s+)'));
    final capped = words.map((word) {
      if (word.isEmpty || RegExp(r'^\s+$').hasMatch(word)) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join();
    return TextSpan(text: capped, style: span.style);
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
    final labelFont = 12.sp;
    final valueFont = 14.sp;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
                fontSize: labelFont,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: valueFont,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

// ─── AutoPay Bottom Sheet (PART 3) ──────────────────────────────────────────

class AutoPayBottomSheet extends HookConsumerWidget {
  const AutoPayBottomSheet({
    super.key,
    required this.amount,
    required this.billerName,
    required this.providerIconUrl,
    required this.accountHolderName,
    required this.consumerNumber,
    required this.onPayAndSetAutoPay,
    this.paymentSchedule = 'Next day after bill generation',
    this.autoPayLimitAmount = 15000,
  });

  final double amount;
  final String billerName;
  final String? providerIconUrl;
  final String accountHolderName;
  final String consumerNumber;
  final VoidCallback onPayAndSetAutoPay;
  final String paymentSchedule;
  final double autoPayLimitAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final amountText = '₹${_formatAmountForInput(amount)}';
    final autoPayLimitText =
        'Bills up to ₹${(autoPayLimitAmount).toStringAsFixed(0)} will be paid automatically';
    final ctaLabel = 'Pay $amountText & Set AutoPay';
    final valueFont = FetchProviderMetrics.font(16, min: 13);
    final scheduleLabelFont = FetchProviderMetrics.font(15, min: 13);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: FetchProviderMetrics.h(340),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FetchProviderMetrics.r(24)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: FetchProviderMetrics.r(16),
            offset: Offset(0, -FetchProviderMetrics.h(4)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          FetchProviderMetrics.w(24),
          FetchProviderMetrics.h(20),
          FetchProviderMetrics.w(24),
          FetchProviderMetrics.h(16) + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Provider Header Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SimCardIconContainer(
                  url: providerIconUrl,
                  width: FetchProviderMetrics.r(49),
                  height: FetchProviderMetrics.r(49),
                  borderRadius: FetchProviderMetrics.r(19.5),
                  padding: FetchProviderMetrics.w(10),
                  borderWidth: 1,
                ),
                SizedBox(width: FetchProviderMetrics.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        billerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: FetchProviderMetrics.font(18, min: 15),
                          color: Colors.black,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: FetchProviderMetrics.h(6)),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              accountHolderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w500,
                                fontSize: FetchProviderMetrics.font(14, min: 12),
                                color: const Color(0xFF7A7A7A),
                                height: 1.0,
                              ),
                            ),
                          ),
                          if (accountHolderName.isNotEmpty &&
                              consumerNumber.isNotEmpty) ...[
                            SizedBox(width: FetchProviderMetrics.w(8)),
                            Container(
                              width: FetchProviderMetrics.r(5),
                              height: FetchProviderMetrics.r(5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFB9B9B9),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: FetchProviderMetrics.w(8)),
                          ],
                          if (consumerNumber.isNotEmpty)
                            Flexible(
                              child: Text(
                                consumerNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: FetchProviderMetrics.font(14, min: 12),
                                  color: const Color(0xFF7A7A7A),
                                  height: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: FetchProviderMetrics.w(8)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: FetchProviderMetrics.w(44),
                    height: FetchProviderMetrics.w(44),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        color: Colors.black,
                        size: FetchProviderMetrics.r(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: FetchProviderMetrics.h(20)),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFECECEC),
            ),
            SizedBox(height: FetchProviderMetrics.h(20)),

            // ── Bill Amount Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Bill Amount',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: FetchProviderMetrics.font(18, min: 15),
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: FetchProviderMetrics.font(24, min: 19),
                      color: Colors.black,
                      height: 1.0,
                      letterSpacing:
                          -0.02 * FetchProviderMetrics.font(24, min: 19),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: FetchProviderMetrics.h(20)),

            // ── AutoPay Settings Card ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                FetchProviderMetrics.w(18),
                FetchProviderMetrics.h(18),
                FetchProviderMetrics.w(18),
                FetchProviderMetrics.h(18),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius:
                    BorderRadius.circular(FetchProviderMetrics.r(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AutoPay Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: FetchProviderMetrics.font(20, min: 16),
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: FetchProviderMetrics.h(16)),
                  // Payment Schedule row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 180,
                        child: Text(
                          'Payment Schedule',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            fontSize: scheduleLabelFont,
                            color: const Color(0xFF373737),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: FetchProviderMetrics.w(10)),
                      Text(
                        ':',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: valueFont,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(width: FetchProviderMetrics.w(10)),
                      Expanded(
                        flex: 220,
                        child: Text(
                          paymentSchedule,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            fontSize: valueFont,
                            color: Colors.black,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FetchProviderMetrics.h(10)),
                  // AutoPay Limit row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 180,
                        child: Text(
                          'AutoPay Limit',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            fontSize: scheduleLabelFont,
                            color: const Color(0xFF373737),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: FetchProviderMetrics.w(10)),
                      SizedBox.shrink(),
                      SizedBox(width: FetchProviderMetrics.w(10)),
                      Expanded(
                        flex: 220,
                        child: Text(
                          autoPayLimitText,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: FetchProviderMetrics.font(16, min: 13),
                            color: Colors.black,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: FetchProviderMetrics.h(28)),

            // ── CTA: Pay & Set AutoPay ──
            LayoutBuilder(
              builder: (context, btnConstraints) => CustomElevatedButton(
                onPressed: onPayAndSetAutoPay,
                label: ctaLabel,
                showArrow: false,
                uppercaseLabel: false,
                width: btnConstraints.maxWidth
                    .clamp(
                      FetchProviderMetrics.w(74),
                      btnConstraints.maxWidth,
                    )
                    .toDouble(),
                height: FetchProviderMetrics.h(56),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),

            SizedBox(height: FetchProviderMetrics.h(20)),

            // ── UPI AUTOPAY Branding ──
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    FileConstants.upi,
                    height: FetchProviderMetrics.h(24),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: FetchProviderMetrics.w(8)),
                  Text(
                    'AUTOPAY',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: FetchProviderMetrics.font(22, min: 18),
                      color: Colors.black,
                      height: 1.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
