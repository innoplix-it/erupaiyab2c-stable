// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/repositories/bank_accounts_repository.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../repositories/bank_account_repository.dart';

class AddBankAccountView extends HookConsumerWidget {
  const AddBankAccountView({
    super.key,
    this.existingAccount,
    this.selectedBankName,
    this.redirectToHomeOnSuccess = false,
  });

  final BankAccountEntry? existingAccount;
  final String? selectedBankName;
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

    final confirmChecked = useState(isEdit);
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
      if (selectedBankName != null && selectedBankName!.trim().isNotEmpty) {
        bankNameController.text = selectedBankName!.trim();
      }
      return null;
    }, [existingAccount?.id, selectedBankName]);

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
      if (!confirmChecked.value) {
        AppSnackbar.show(
          'Please confirm your bank account details before verifying.',
        );
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

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (step.value == _BankStep.verify)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.w,
                        width: 20.w,
                        child: Checkbox(
                          value: confirmChecked.value,
                          onChanged: (value) =>
                              confirmChecked.value = value ?? false,
                          activeColor: const Color(0xFFE85A2C),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'I Confirm That The Bank Account Details Are Correct And Match My KYC Information.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (step.value == _BankStep.verify) SizedBox(height: 12.h),
              _PrimaryButton(
                label: step.value == _BankStep.verify
                    ? 'Verify Account'
                    : (isEdit ? 'Update Bank Account' : 'Save Bank Account'),
                loading: step.value == _BankStep.verify
                    ? isVerifying.value
                    : isSaving.value,
                onTap:
                    step.value == _BankStep.verify ? handleVerify : handleSave,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferAndEarnAppBar(
              title: isEdit ? 'Edit Bank Account' : 'Add Bank Account',
              height: 300.h,
              body: Column(
                children: [
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    isEdit
                        ? 'Edit your bank account details to keep withdrawals active.'
                        : step.value == _BankStep.verify
                            ? 'Select your bank to link it with your wallet for\nwithdrawals.'
                            : 'Add your bank details to receive withdrawal\npayments securely.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, -26.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
                  child: step.value == _BankStep.verify
                      ? _VerifyBankForm(
                          accountController: accountController,
                          ifscController: ifscController,
                        )
                      : _ConfirmBankForm(
                          nameController: nameController,
                          accountController: accountController,
                          ifscController: ifscController,
                          branchController: branchController,
                          bankNameController: bankNameController,
                        ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

enum _BankStep { verify, confirm }

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
        Text(
          'Account Number',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _InputField(
          controller: accountController,
          hintText: 'Enter Account Number',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16.h),
        Text(
          'IFSC Code',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _InputField(
          controller: ifscController,
          hintText: 'Enter IFSC Code',
          textCapitalization: TextCapitalization.characters,
        ),
        SizedBox(height: 24.h),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Account Holder Name',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _InputField(
          controller: nameController,
          hintText: 'Account Holder Name',
        ),
        SizedBox(height: 16.h),
        Text(
          'Account Number',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _InputField(
          controller: accountController,
          hintText: 'Account Number',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16.h),
        Text(
          'IFSC Code',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _InputField(
          controller: ifscController,
          hintText: 'IFSC Code',
          textCapitalization: TextCapitalization.characters,
        ),
        SizedBox(height: 16.h),
        Text(
          'Branch Name (Opt)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _InputField(
          controller: branchController,
          hintText: 'Enter Branch Name',
        ),
        SizedBox(height: 16.h),
        Text(
          'Bank Name (Opt)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _InputField(
          controller: bankNameController,
          hintText: 'Enter Bank Name',
        ),
        SizedBox(height: 16.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFFE7E7E7),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            'Please Confirm Your Bank Details Before Saving. Withdrawals Will Be Processed To This Account.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
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
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withOpacity(0.5),
            ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFF1A56A1)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends HookWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        height: 42.h,
        decoration: BoxDecoration(
          color: const Color(0xFFE85A2C),
          borderRadius: BorderRadius.circular(28.r),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(width: 22.w,
                height: 22.w,
                child: const Center(
                  child: SpinKitCircle(
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
