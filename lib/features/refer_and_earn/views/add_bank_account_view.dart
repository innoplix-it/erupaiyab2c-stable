// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/secure_clipboard.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../auth/components/auth_step_parts.dart';
import '../../mobile_prepaid/components/recharge_quick_action_card.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/repositories/bank_accounts_repository.dart';
import '../../services/components/credit_card/credit_card_figma_metrics.dart';
import '../repositories/bank_account_repository.dart';
import '../views/select_bank_view.dart';

/// Add / Edit Bank Account.
///
/// Layout follows the Credit Card bill-entry screen 1:1 (same shared pieces:
/// [MyAppBar], [SimpleQuickActionCard] in `creditCardStyle`, the bill-field
/// chrome and [CustomElevatedButton]) and is sized through
/// [CreditCardFigmaMetrics] (440-wide Figma frame scaled by MediaQuery), so
/// every device gets the same proportions. Verification / save payloads and
/// the two-step flow are untouched; the KYC attestation checkbox is removed.
class AddBankAccountView extends HookConsumerWidget {
  const AddBankAccountView({
    super.key,
    this.existingAccount,
    this.selectedBankName,
    this.selectedBank,
    this.redirectToHomeOnSuccess = false,
  });

  final BankAccountEntry? existingAccount;
  final String? selectedBankName;

  /// Bank picked on [SelectBankView]; carries the logo for the header card.
  final BankListItem? selectedBank;
  final bool redirectToHomeOnSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = existingAccount != null;
    final step = useState(_BankStep.verify);
    final repository = useMemoized(() => BankAccountRepository());
    final profileState = ref.watch(profileControllerProvider);
    final isKycVerified =
        profileState.profile?.kycStatus == ProfileKycStatus.verified;

    final accountController = useTextEditingController();
    final ifscController = useTextEditingController();
    final nameController = useTextEditingController();
    final branchController = useTextEditingController();
    final bankNameController = useTextEditingController();
    // The header card mirrors the bank name, so rebuild when it changes
    // (picker selection, edit prefill, verify response).
    useListenable(bankNameController);
    final pickedBank = useState<BankListItem?>(selectedBank);

    final isVerifying = useState(false);
    final isSaving = useState(false);
    final referenceId = useState(existingAccount?.referenceId ?? '');

    useEffect(() {
      if (profileState.profile != null || profileState.isFetching) return null;
      Future.microtask(
        () => ref.read(profileControllerProvider.notifier).fetchProfile(),
      );
      return null;
    }, [profileState.profile, profileState.isFetching]);

    useEffect(() {
      if (isEdit && existingAccount != null) {
        accountController.text = '';
        ifscController.text = existingAccount!.ifsc ?? '';
        nameController.text = existingAccount!.accountHolderName;
        bankNameController.text = existingAccount!.bankName;
        referenceId.value = existingAccount!.referenceId ?? '';
        step.value = _BankStep.verify;
      }
      final incomingBank = selectedBank;
      if (incomingBank != null) {
        pickedBank.value = incomingBank;
        bankNameController.text = incomingBank.bankName.trim();
      } else if (selectedBankName != null &&
          selectedBankName!.trim().isNotEmpty) {
        bankNameController.text = selectedBankName!.trim();
      }
      return null;
    }, [existingAccount?.id, selectedBankName, selectedBank?.id]);

    Future<void> handleVerify() async {
      if (profileState.profile == null) {
        AppSnackbar.show('Please wait while profile details are loading.');
        return;
      }
      if (!isKycVerified) {
        AppSnackbar.show('Please complete kyc first');
        if (context.mounted) {
          context.push(RouteConstants.kycVerification);
        }
        return;
      }
      final accountNo = accountController.text.trim();
      final ifsc = ifscController.text.trim();
      if (accountNo.isEmpty || ifsc.isEmpty) {
        AppSnackbar.show('Please enter account number and IFSC code.');
        return;
      }
      try {
        isVerifying.value = true;
        final response = await repository.verifyBank(
          accountNo: accountNo,
          ifsc: ifsc,
          bankName: bankNameController.text.trim(),
        );
        if (!response.isSuccess) {
          final message = response.message.isEmpty
              ? 'Unable to verify bank account.'
              : response.message;
          if (_isKycVerificationRequired(message)) {
            AppSnackbar.show(message);
            if (context.mounted) {
              context.push(RouteConstants.kycVerification);
            }
          } else if (_isKycMismatch(message)) {
            await KDialog.instance.openDialog(
              barrierDismissible: false,
              dialog: _KycMismatchDialog(
                onCancel: () => Navigator.of(context).pop(),
                onUpdate: () => Navigator.of(context).pop(),
              ),
            );
          } else {
            AppSnackbar.show(message);
          }
          return;
        }
        nameController.text = response.creditorName;
        accountController.text = response.accountNumber;
        ifscController.text = response.ifsc;
        referenceId.value = response.transactionReferenceNumber;
        step.value = _BankStep.confirm;
      } catch (e) {
        final resolvedMessage = ErrorMessageUtils.from(
          e,
          fallback: 'Failed to verify account. Please try again.',
        );
        AppSnackbar.show(resolvedMessage);
        if (_isKycVerificationRequired(resolvedMessage) && context.mounted) {
          context.push(RouteConstants.kycVerification);
        }
      } finally {
        isVerifying.value = false;
      }
    }

    Future<void> handleSave() async {
      if (profileState.profile == null) {
        AppSnackbar.show('Please wait while profile details are loading.');
        return;
      }
      if (!isKycVerified) {
        AppSnackbar.show('Please complete kyc first');
        if (context.mounted) {
          context.push(RouteConstants.kycVerification);
        }
        return;
      }
      final accountNo = accountController.text.trim();
      final ifsc = ifscController.text.trim();
      final accountHolderName = nameController.text.trim();
      final bankName = bankNameController.text.trim();
      if (accountNo.isEmpty || ifsc.isEmpty || accountHolderName.isEmpty) {
        AppSnackbar.show('Please fill all required details.');
        return;
      }
      try {
        isSaving.value = true;
        final response = isEdit && existingAccount?.id != null
            ? await repository.updateBank(
                bankId: existingAccount!.id!,
                referenceId: referenceId.value.isNotEmpty
                    ? referenceId.value
                    : existingAccount!.referenceId ?? '',
              )
            : await repository.addBank(
                userId: (await Utils.getUserId() ?? '').isEmpty
                    ? ''
                    : (await Utils.getUserId() ?? ''),
                accountNo: accountNo,
                ifsc: ifsc,
                accountHolderName: accountHolderName,
                bankName: bankName,
                referenceId: referenceId.value,
                branchName: branchController.text.trim(),
              );

        if (!response.status) {
          AppSnackbar.show(response.message.isEmpty
              ? 'Unable to save bank account.'
              : response.message);
          return;
        }

        if (isEdit) {
          AppSnackbar.show(response.message.isEmpty
              ? 'Bank account updated successfully.'
              : response.message);
          Navigator.of(context).pop();
          return;
        }

        await KDialog.instance.openDialog(
          barrierDismissible: false,
          dialog: _BankAddedDialog(
            onContinue: () {
              Navigator.of(context).pop();
              if (redirectToHomeOnSuccess) {
                context.go(RouteConstants.home);
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
        );
      } catch (e) {
        AppSnackbar.show(
          ErrorMessageUtils.from(
            e,
            fallback: 'Failed to save bank account. Please try again.',
          ),
        );
      } finally {
        isSaving.value = false;
      }
    }

    /// Re-opens [SelectBankView]. The picked bank only feeds the existing
    /// verify/save payload (bank name) — no API logic changes here.
    Future<void> openBankPicker() async {
      final selected = await Navigator.of(context).push<BankListItem>(
        MaterialPageRoute(
          builder: (_) => const SelectBankView(),
        ),
      );
      if (selected == null) return;
      pickedBank.value = selected;
      bankNameController.text = selected.bankName.trim();
    }

    final bankLabel = bankNameController.text.trim();
    final hasBank = bankLabel.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: isEdit ? 'Edit Bank Account' : 'Add Bank Account',
        fitTitle: true,
        showHelp: true,
        // Figma keeps only the help mark on this screen.
        showBharatConnect: false,
        helpIconSize: 20,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            CreditCardFigmaMetrics.s(context, 24),
            0,
            CreditCardFigmaMetrics.s(context, 24),
            CreditCardFigmaMetrics.sy(context, 20),
          ),
          child: AuthButtonTheme(
            child: CustomElevatedButton(
              onPressed:
                  step.value == _BankStep.verify ? handleVerify : handleSave,
              label: step.value == _BankStep.verify
                  ? 'Proceed'
                  : (isEdit ? 'Update Bank Account' : 'Save Bank Account'),
              isLoading: step.value == _BankStep.verify
                  ? isVerifying.value
                  : isSaving.value,
              uppercaseLabel: false,
              // Every property of the auth flow "Continue" CTA: same width
              // driven height (48/360 clamped 40-56), flat brand fill, white
              // Plus Jakarta Sans 12 / w500 label and the rim-free button
              // theme, so both buttons render identically on every device.
              height: authButtonHeight(context),
              backgroundColor: AppColors.primary,
              labelColor: Colors.white,
              labelStyle: TextStyle(
                fontFamily: authFontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          CreditCardFigmaMetrics.s(context, 24),
          CreditCardFigmaMetrics.sy(context, 20),
          CreditCardFigmaMetrics.s(context, 24),
          CreditCardFigmaMetrics.sy(context, 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SimpleQuickActionCard(
              overline: 'Selected Bank',
              title: hasBank ? bankLabel : 'Tap to select bank',
              subtitle: '',
              // Bank list API sends no logo yet, so the generic bank mark shows
              // until a URL exists (LeadingIcon prefers the remote icon).
              leadingAsset: FileConstants.homeBank,
              leadingImageUrl: pickedBank.value?.logoUrl,
              creditCardStyle: true,
              showShadow: true,
              actionLabel: hasBank ? 'Change' : 'Select',
              onTap: openBankPicker,
              onAction: openBankPicker,
            ),
            SizedBox(height: CreditCardFigmaMetrics.sy(context, 22)),
            if (step.value == _BankStep.verify)
              _VerifyBankForm(
                accountController: accountController,
                ifscController: ifscController,
              )
            else
              _ConfirmBankForm(
                nameController: nameController,
                accountController: accountController,
                ifscController: ifscController,
                branchController: branchController,
                bankNameController: bankNameController,
              ),
          ],
        ),
      ),
    );
  }
}

enum _BankStep { verify, confirm }

/// Field label — Figma "Account Number" / "IFSC Code" row.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: CreditCardFigmaMetrics.s(context, 14),
          height: 1,
          color: const Color(0xFF000000),
        ),
      );
}

class _VerifyBankForm extends HookWidget {
  const _VerifyBankForm({
    required this.accountController,
    required this.ifscController,
  });

  final TextEditingController accountController;
  final TextEditingController ifscController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Account Number'),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 8)),
        _InputField(
          controller: accountController,
          hintText: 'Account number',
          keyboardType: TextInputType.number,
          blockCopy: true,
        ),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 18)),
        const _FieldLabel('IFSC Code'),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 8)),
        _InputField(
          controller: ifscController,
          hintText: 'IFSC',
          textCapitalization: TextCapitalization.characters,
          blockCopy: true,
        ),
      ],
    );
  }
}

class _ConfirmBankForm extends HookWidget {
  const _ConfirmBankForm({
    required this.nameController,
    required this.accountController,
    required this.ifscController,
    required this.branchController,
    required this.bankNameController,
  });

  final TextEditingController nameController;
  final TextEditingController accountController;
  final TextEditingController ifscController;
  final TextEditingController branchController;
  final TextEditingController bankNameController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Confirm Bank Details',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: CreditCardFigmaMetrics.s(context, 15),
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        const _FieldLabel('Account Holder Name'),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 8)),
        _InputField(
          controller: nameController,
          hintText: 'Account Holder Name',
        ),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 16)),
        const _FieldLabel('Account Number'),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 8)),
        _InputField(
          controller: accountController,
          hintText: 'Account Number',
          keyboardType: TextInputType.number,
          blockCopy: true,
        ),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 16)),
        const _FieldLabel('IFSC Code'),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 8)),
        _InputField(
          controller: ifscController,
          hintText: 'IFSC Code',
          textCapitalization: TextCapitalization.characters,
          blockCopy: true,
        ),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 16)),
        const _FieldLabel('Branch Name (Opt)'),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 8)),
        _InputField(
          controller: branchController,
          hintText: 'Enter Branch Name',
        ),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 16)),
        const _FieldLabel('Bank Name (Opt)'),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 8)),
        _InputField(
          controller: bankNameController,
          hintText: 'Enter Bank Name',
        ),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 16)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: CreditCardFigmaMetrics.s(context, 12),
            vertical: CreditCardFigmaMetrics.sy(context, 10),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE7E7E7),
            borderRadius: BorderRadius.circular(
              CreditCardFigmaMetrics.s(context, 10),
            ),
          ),
          child: Text(
            'Please Confirm Your Bank Details Before Saving. Withdrawals Will Be Processed To This Account.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: CreditCardFigmaMetrics.s(context, 12),
              height: 1.35,
              color: AppColors.textPrimary.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputField extends HookWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization,
    this.blockCopy = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;

  /// AUD-038: true for account-number / IFSC inputs — removes Copy/Cut from
  /// the selection toolbar so typed banking values cannot reach the clipboard.
  final bool blockCopy;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      CreditCardFigmaMetrics.billFieldRadius(context),
    );
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color),
        );
    final fontSize = CreditCardFigmaMetrics.s(context, 14);

    // Same chrome as the credit card bill inputs: fixed Figma height, text
    // centred, hairline border and a soft elevation.
    return SizedBox(
      width: double.infinity,
      height: CreditCardFigmaMetrics.billFieldHeight(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: CreditCardFigmaMetrics.s(context, 8),
              offset: Offset(0, CreditCardFigmaMetrics.sy(context, 2)),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          contextMenuBuilder:
              blockCopy ? SecureClipboard.sensitiveFieldContextMenu : null,
          expands: true,
          maxLines: null,
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w400,
              fontSize: fontSize,
              color: const Color(0xFF7C7C7C),
            ),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: CreditCardFigmaMetrics.billFieldHorizontalInset(
                context,
              ),
            ),
            border: border(AppColors.lightBorder),
            enabledBorder: border(AppColors.lightBorder),
            focusedBorder: border(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _KycMismatchDialog extends HookWidget {
  const _KycMismatchDialog({
    required this.onCancel,
    required this.onUpdate,
  });

  final VoidCallback onCancel;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: const BoxDecoration(
                color: Color(0xFFE85A2C),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info, color: Colors.white, size: 28.r),
            ),
            SizedBox(height: 12.h),
            Text(
              'KYC Mismatch\nDetected',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'The bank account holder name does not match\nyour verified KYC details.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                      side: const BorderSide(color: AppColors.lightBorder),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85A2C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                    ),
                    child: const Text('Update Details',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BankAddedDialog extends HookWidget {
  const _BankAddedDialog({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: const BoxDecoration(
                color: Color(0xFF1B8E36),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance, color: Colors.white),
            ),
            SizedBox(height: 12.h),
            Text(
              'Bank Account Added\nSuccessfully',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You can now withdraw your wallet\nbalance to this bank account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85A2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isKycMismatch(String message) {
  final lower = message.toLowerCase();
  return lower.contains('match');
}

bool _isKycVerificationRequired(String message) {
  final lower = message.toLowerCase();
  return lower.contains('complete your kyc') ||
      lower.contains('complete kyc') ||
      lower.contains('kyc verification');
}
