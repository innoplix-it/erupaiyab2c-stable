// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../helpers/kyc_helpers.dart';
import '../../../helpers/kyc_input_formatters.dart';
import '../../../services/logger_service.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/education_account_type_sheet.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../helpers/education_pay_now.dart';
import '../models/education_account_type.dart';
import '../models/education_fees_state.dart';
import 'education_tutor_profile_view.dart';

class EducationFeesRecipientView extends HookConsumerWidget {
  const EducationFeesRecipientView({
    super.key,
    this.unverifiedFlow = false,
  });

  /// When true (the unverified "Add Details" flow), a successful Proceed opens
  /// the tutor review screen instead of the payment screen.
  final bool unverifiedFlow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(educationFeesControllerProvider);
    final controller = ref.read(educationFeesControllerProvider.notifier);

    final showFields = state.showRecipientFields || unverifiedFlow;

    final mobileController = useTextEditingController(text: state.mobileInput);
    final nameController = useTextEditingController(text: state.recipientName);
    final panController = useTextEditingController(text: state.pan);
    final panFocus = useFocusNode();
    final accountNoController =
        useTextEditingController(text: state.accountNumber);
    final ifscController = useTextEditingController(text: state.ifsc);
    final subjectController = useTextEditingController();

    useEffect(() {
      if (mobileController.text != state.mobileInput) {
        mobileController.text = state.mobileInput;
      }
      return null;
    }, [state.mobileInput]);

    useEffect(() {
      if (nameController.text != state.recipientName) {
        nameController.text = state.recipientName;
      }
      return null;
    }, [state.recipientName]);

    // Don't sync PAN controller from state to allow keyboard switching to work
    // The controller is the source of truth during typing

    // PAN keyboard switching: letters (0-4) -> numbers (5-8) -> letter (9)
    final panKeyboardSegment =
        useState(panKeyboardSegmentForLength(panController.text.length));
    final lastPanSegment = useRef(panKeyboardSegment.value);

    final switchPanKeyboard = useCallback((String value) {
      final seg = panKeyboardSegmentForLength(value.length);
      if (seg == lastPanSegment.value) return;
      lastPanSegment.value = seg;
      panKeyboardSegment.value = seg;
      if (!panFocus.hasFocus) return;
      panFocus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        panFocus.requestFocus();
      });
    }, [panFocus]);

    useEffect(() {
      if (accountNoController.text != state.accountNumber) {
        accountNoController.text = state.accountNumber;
      }
      return null;
    }, [state.accountNumber]);

    useEffect(() {
      if (ifscController.text != state.ifsc) {
        ifscController.text = state.ifsc;
      }
      return null;
    }, [state.ifsc]);

    // Starting a new beneficiary entry must open with empty PAN / Account
    // Number / IFSC. Both add-beneficiary entry points push a fresh route, so
    // this runs exactly once per new form. The shared controller is persistent
    // (not auto-dispose), so the previous beneficiary's values are cleared
    // here; mobile and name are intentionally preserved.
    useEffect(() {
      // Deferred to a microtask like the other provider-mutating effects in
      // this view: mutating the Riverpod StateNotifier synchronously during
      // the build pass throws "modify a provider while building".
      Future.microtask(() {
        controller.clearBeneficiaryDetails();
        // The PAN field is owned by the keyboard-switch logic (not state-synced),
        // so clear its controller and reset the keyboard segment directly. The
        // account/IFSC fields are cleared here too to avoid a one-frame flash of
        // the previous values before their state-sync effects run.
        panController.clear();
        accountNoController.clear();
        ifscController.clear();
        panKeyboardSegment.value = panKeyboardSegmentForLength(0);
        lastPanSegment.value = panKeyboardSegment.value;
      });
      return null;
    }, const []);

    final lastCheckedMobile = useRef<String?>(null);

    useEffect(() {
      // The unverified "Add Details" flow shows the form directly and its
      // tutor is by definition not registered; running the registration
      // check here would only reset the verified state it must not gate on.
      if (unverifiedFlow) return null;
      final digits = state.mobileInput.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 10) {
        lastCheckedMobile.value = null;
        return null;
      }
      if (digits == lastCheckedMobile.value) {
        return null;
      }
      lastCheckedMobile.value = digits;
      Future.microtask(controller.checkMobile);
      return null;
    }, [state.mobileInput]);

    // Unverified flow: the Account Type picker is hidden and Figma shows the
    // bank fields directly, so keep accountType pinned to Bank. The
    // controller resets it to none whenever the name/PAN changes, so re-seed
    // on every reset instead of seeding only once.
    useEffect(() {
      if (!unverifiedFlow) return null;
      if (state.accountType != EducationAccountType.none) return null;
      Future.microtask(
        () => controller.updateAccountType(EducationAccountType.bankDetails),
      );
      return null;
    }, [unverifiedFlow, state.accountType]);

    final lastVerifiedBankKey = useRef<String?>(null);

    useEffect(() {
      if (state.accountType != EducationAccountType.bankDetails) {
        lastVerifiedBankKey.value = null;
        return null;
      }
      final accountNo = state.accountNumber.trim();
      final ifsc = state.ifsc.trim().toUpperCase();
      final recipientName = state.recipientName.trim();
      if (accountNo.isEmpty || ifsc.isEmpty || recipientName.isEmpty) {
        lastVerifiedBankKey.value = null;
        return null;
      }
      final key = '$accountNo|$ifsc|$recipientName';
      if (key == lastVerifiedBankKey.value) {
        return null;
      }
      lastVerifiedBankKey.value = key;
      Future.microtask(controller.verifyBank);
      return null;
    }, [
      state.accountNumber,
      state.ifsc,
      state.accountType,
      state.recipientName
    ]);

    final lastVerifiedPanKey = useRef<String?>(null);

    useEffect(() {
      if (!showFields) {
        lastVerifiedPanKey.value = null;
        return null;
      }
      final name = state.recipientName.trim();
      final pan = state.pan.trim().toUpperCase();
      if (name.isEmpty || !isValidPanFormat(pan)) {
        lastVerifiedPanKey.value = null;
        return null;
      }
      final key = '$name|$pan';
      if (key == lastVerifiedPanKey.value) {
        return null;
      }
      lastVerifiedPanKey.value = key;
      Future.microtask(controller.verifyPan);
      return null;
    }, [state.recipientName, state.pan, showFields]);

    void openContacts() {
      context.push(RouteConstants.educationSearchRecipient);
    }

    void openAccountTypeSheet() {
      KDialog.instance.openSheet(
        dialog: EducationAccountTypeSheet(
          selected: state.accountType,
          onSelect: controller.updateAccountType,
        ),
      );
    }

    final showBankFields =
        state.accountType == EducationAccountType.bankDetails;

    // Check if all required details are filled for button background color
    final allDetailsFilled = state.mobileInput.isNotEmpty &&
        state.recipientName.isNotEmpty &&
        state.pan.isNotEmpty &&
        state.accountNumber.isNotEmpty &&
        state.ifsc.isNotEmpty;

    return EducationFeesTheme(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MyAppBar(
          title: '',
          showHelp: true,
          showDivider: true,
          fitTitle: true,
          titleStyle: MyAppBar.sharedTitleStyle(context),
          bharatConnectWidth: 52,
          bharatConnectHeight: 25,
          helpIconSize: 20,
          onBack: () {
            controller.reset();
            Navigator.of(context).maybePop();
          },
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ───────────── PERSONAL DETAILS ─────────────
                      const _SectionHeader(text: 'PERSONAL DETAILS'),
                      SizedBox(height: 12.h),

                      const _Label(text: "Tutor's Mobile Number"),
                      SizedBox(height: 6.h),
                      _FieldShell(
                        child: TextField(
                          key: const Key('mobile_field'),
                          controller: mobileController,
                          keyboardType: TextInputType.phone,
                          style: _fieldInputStyle(),
                          cursorColor: AppColors.primary,
                          decoration: _inputDecoration(
                            'Enter mobile number',
                            suffix: state.isCheckingMobile
                                ? SizedBox(
                                    height: 18.r,
                                    width: 18.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : _ContactIconButton(onTap: openContacts),
                          ),
                          onChanged: controller.updateMobileInput,
                        ),
                      ),
                      if (state.mobileErrorMessage != null &&
                          !unverifiedFlow) ...[
                        SizedBox(height: 6.h),
                        _ErrorText(text: state.mobileErrorMessage!),
                      ],

                      if (showFields) ...[
                        SizedBox(height: 14.h),
                        const _Label(text: "Tutor's Name (as per PAN)"),
                        SizedBox(height: 6.h),
                        _FieldShell(
                          child: TextField(
                            key: const Key('name_field'),
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            style: _fieldInputStyle(),
                            cursorColor: AppColors.primary,
                            decoration: _inputDecoration(
                              'Enter tutor name',
                              borderColor:
                                  state.panVerified ? AppColors.green : null,
                              suffix: state.panVerified
                                  ? _VerifyBadge(size: 18.r)
                                  : null,
                            ),
                            onChanged: controller.updateRecipientName,
                          ),
                        ),

                        SizedBox(height: 14.h),
                        const _Label(text: 'PAN Number'),
                        SizedBox(height: 6.h),
                        _FieldShell(
                          child: TextField(
                            key: const Key('pan_field'),
                            controller: panController,
                            focusNode: panFocus,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType: panKeyboardSegment.value == 1
                                ? TextInputType.number
                                : TextInputType.text,
                            inputFormatters: const [PanInputFormatter()],
                            style: _fieldInputStyle().copyWith(
                              letterSpacing: 0.5,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: _inputDecoration(
                              'Enter PAN',
                              borderColor:
                                  state.panVerified ? AppColors.green : null,
                              suffix: _PanAction(
                                verifying: state.isVerifyingPan,
                                verified: state.panVerified,
                                canVerify:
                                    state.recipientName.trim().isNotEmpty &&
                                        isValidPanFormat(state.pan),
                                onVerify: controller.verifyPan,
                              ),
                            ),
                            onSubmitted: (_) =>
                                FocusScope.of(context).unfocus(),
                            onChanged: (value) {
                              controller.updatePan(value);
                              switchPanKeyboard(value);
                            },
                          ),
                        ),
                        if (state.isVerifyingPan) ...[
                          SizedBox(height: 6.h),
                          const _StatusRow(text: 'Verifying PAN...'),
                        ] else if (state.panErrorMessage != null) ...[
                          SizedBox(height: 6.h),
                          _ErrorText(text: state.panErrorMessage!),
                        ],

                        SizedBox(height: 14.h),
                        const _Label(text: 'Subject (Optional)'),
                        SizedBox(height: 6.h),
                        _FieldShell(
                          child: TextField(
                            key: const Key('subject_field'),
                            controller: subjectController,
                            style: _fieldInputStyle(),
                            cursorColor: AppColors.primary,
                            decoration: _inputDecoration('Enter subject'),
                          ),
                        ),

                        // ───────────── BANK DETAILS ─────────────
                        SizedBox(height: 22.h),
                        const _SectionHeader(text: 'BANK DETAILS'),
                        SizedBox(height: 12.h),
                        if (!unverifiedFlow) ...[
                          const _Label(text: 'Account Type'),
                          SizedBox(height: 6.h),
                          _FieldShell(
                            child: InkWell(
                              onTap: openAccountTypeSheet,
                              borderRadius: BorderRadius.circular(10.r),
                              child: InputDecorator(
                                decoration: _inputDecoration('').copyWith(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 14.h,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      state.accountType ==
                                              EducationAccountType.bankDetails
                                          ? Icons.account_balance_outlined
                                          : Icons.qr_code,
                                      size: 20.r,
                                      color: AppColors.textPrimary
                                          .withOpacity(0.6),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        state.accountType.label,
                                        style: _fieldInputStyle().copyWith(
                                          color: state.accountType ==
                                                  EducationAccountType.none
                                              ? AppColors.textPrimary
                                                  .withOpacity(0.4)
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppColors.textPrimary
                                          .withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (showBankFields) ...[
                          if (!unverifiedFlow) SizedBox(height: 14.h),
                          const _Label(text: 'Account Number'),
                          SizedBox(height: 6.h),
                          _FieldShell(
                            child: TextField(
                              key: const Key('account_field'),
                              controller: accountNoController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: _fieldInputStyle(),
                              cursorColor: AppColors.primary,
                              decoration:
                                  _inputDecoration('Enter account number'),
                              onChanged: controller.updateAccountNumber,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          const _Label(text: 'IFSC Code'),
                          SizedBox(height: 6.h),
                          _FieldShell(
                            child: TextField(
                              key: const Key('ifsc_field'),
                              controller: ifscController,
                              textCapitalization: TextCapitalization.characters,
                              autocorrect: false,
                              enableSuggestions: false,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]'),
                                ),
                                _UpperCaseFormatter(),
                                LengthLimitingTextInputFormatter(11),
                              ],
                              style: _fieldInputStyle(),
                              cursorColor: AppColors.primary,
                              decoration: _inputDecoration(
                                'Enter IFSC code',
                                borderColor: state.bankErrorMessage != null &&
                                        !state.isVerifyingBank
                                    ? Colors.red
                                    : (state.bankVerified
                                        ? AppColors.green
                                        : null),
                                suffix: state.bankVerified
                                    ? _VerifyBadge(size: 18.r)
                                    : null,
                              ),
                              onChanged: controller.updateIfsc,
                            ),
                          ),
                          if (state.isVerifyingBank) ...[
                            SizedBox(height: 6.h),
                            const _StatusRow(
                              text: 'Verifying bank details...',
                            ),
                          ] else if (state.bankErrorMessage != null) ...[
                            SizedBox(height: 6.h),
                            _ErrorText(text: state.bankErrorMessage!),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              // ───────────── BOTTOM: info banner + Proceed ─────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showFields)
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFFFE9E2),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16.r,
                              color: AppColors.textPrimary,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'We will notify the recipient via SMS to onboard '
                                'and start receiving payments via ERupaiya',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.saveErrorMessage != null) ...[
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Text(
                                state.saveErrorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          CustomElevatedButton(
                            backgroundColor: allDetailsFilled
                                ? const Color(0xFFDD5428)
                                : const Color(0xFFA6A6A6),
                            // The tap must always reach the controller when
                            // the form is visible: the controller enforces the
                            // same guards and surfaces the concrete reason via
                            // saveErrorMessage. Gating onPressed on _canPay
                            // silently swallowed taps ("nothing happens").
                            onPressed: showFields
                                ? () async {
                                    logger.info('EDU_SAVE PROCEED_TAPPED');
                                    logger.info(
                                      'EDU_SAVE CAN_PAY_RESULT '
                                      'canPay=${_canPay(state, unverifiedFlow)}',
                                    );
                                    final ok = await controller.saveBeneficiary(
                                      unverifiedFlow: unverifiedFlow,
                                    );
                                    if (!ok) return;
                                    if (!context.mounted) return;
                                    if (!unverifiedFlow) {
                                      logger.info(
                                        'EDU_SAVE NAVIGATION_STARTED '
                                        'target=payment',
                                      );
                                      context.push(
                                        RouteConstants.educationFeesPayment,
                                      );
                                      return;
                                    }
                                    logger.info(
                                      'EDU_SAVE NAVIGATION_STARTED '
                                      'target=tutor_profile',
                                    );
                                    final amountValue = double.tryParse(
                                          state.amountInput.replaceAll(
                                            RegExp(r'\D'),
                                            '',
                                          ),
                                        ) ??
                                        0;
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            EducationTutorProfileView(
                                          tutorName: state.recipientName,
                                          accountLine: maskEducationAccount(
                                            state.accountNumber,
                                          ),
                                          amount: amountValue,
                                          amountLabel:
                                              '\u20B9${amountValue.toStringAsFixed(0)}',
                                          panDetails: state.pan,
                                          accountNumber: state.accountNumber,
                                          ifscCode: state.ifsc,
                                          branch: null,
                                          verified: false,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            label: state.isSavingBeneficiary
                                ? 'Saving...'
                                : 'Proceed',
                            isLoading: state.isSavingBeneficiary,
                            uppercaseLabel: false,
                            showArrow: false,
                            height: 44.h,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── helper widgets ───────────────────────────

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: const Color(0xFF52525B),
      ),
    );
  }
}

/// White rounded shell with the soft Figma drop shadow around each field.
class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFD40000),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 12.r,
          width: 12.r,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: AppColors.textPrimary.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Figma contact button: 28x28 orange rounded square, white address-book icon,
/// sits at the right edge inside the field.
class _ContactIconButton extends StatelessWidget {
  const _ContactIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        height: 28.r,
        width: 28.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: SvgPicture.asset(
          FileConstants.creditCardContactSvg,
          width: 14.r,
          height: 14.r,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Figma green verified badge (star-burst + check) rendered from SVG.
class _VerifyBadge extends StatelessWidget {
  const _VerifyBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      FileConstants.verifyBadgeGreenSvg,
      width: size,
      height: size,
    );
  }
}

/// In-field PAN status: spinner while verifying, green badge once verified,
/// otherwise a compact "Verify Now" pill (only for a well-formed PAN).
class _PanAction extends StatelessWidget {
  const _PanAction({
    required this.verifying,
    required this.verified,
    required this.canVerify,
    required this.onVerify,
  });

  final bool verifying;
  final bool verified;
  final bool canVerify;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    if (verifying) {
      return SizedBox(
        height: 16.r,
        width: 16.r,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }
    if (verified) {
      return _VerifyBadge(size: 18.r);
    }
    if (!canVerify) return const SizedBox.shrink();
    return InkWell(
      onTap: onVerify,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          'Verify Now',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFFFAFAFA),
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

InputDecoration _inputDecoration(
  String hint, {
  Color? borderColor,
  Widget? suffix,
}) {
  final edge = borderColor ?? AppColors.lightBorder;
  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    hintStyle: GoogleFonts.plusJakartaSans(
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary.withOpacity(0.4),
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    suffixIcon: suffix == null
        ? null
        : Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: suffix,
          ),
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(color: edge),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(color: edge),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(color: borderColor ?? AppColors.primary),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 14.w,
      vertical: 12.h,
    ),
  );
}

/// Plus Jakarta Sans input text for every recipient field so entered values
/// are always dark and readable.
TextStyle _fieldInputStyle() => GoogleFonts.plusJakartaSans(
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );

bool _canPay(EducationFeesState state, [bool unverifiedFlow = false]) {
  if (!state.showRecipientFields && !unverifiedFlow) return false;
  if (state.isSavingBeneficiary) return false;
  if (!state.panVerified) return false;
  if (state.accountType != EducationAccountType.bankDetails) return false;
  // Restored per committed product rule (HEAD): Proceed requires a
  // successful bank verification, in both flows.
  return state.bankVerified;
}
