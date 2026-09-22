// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../components/education_account_type_sheet.dart';
import '../components/education_contact_sheet.dart';
import '../controllers/education_fees_controller.dart';
import '../models/education_account_type.dart';
import '../models/education_fees_state.dart';

class EducationFeesRecipientView extends HookConsumerWidget {
  const EducationFeesRecipientView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(educationFeesControllerProvider);
    final controller = ref.read(educationFeesControllerProvider.notifier);

    final mobileController = useTextEditingController(text: state.mobileInput);
    final nameController = useTextEditingController(text: state.recipientName);
    final panController = useTextEditingController(text: state.pan);
    final accountNoController =
        useTextEditingController(text: state.accountNumber);
    final ifscController = useTextEditingController(text: state.ifsc);

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

    useEffect(() {
      if (panController.text != state.pan) {
        panController.text = state.pan;
      }
      return null;
    }, [state.pan]);

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

    final lastCheckedMobile = useRef<String?>(null);

    useEffect(() {
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
      if (!state.showRecipientFields) {
        lastVerifiedPanKey.value = null;
        return null;
      }
      final name = state.recipientName.trim();
      final pan = state.pan.trim().toUpperCase();
      if (name.isEmpty || pan.isEmpty || pan.length != 10) {
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
    }, [state.recipientName, state.pan, state.showRecipientFields]);

    void openContacts() {
      KDialog.instance.openSheet(
        dialog: EducationContactSheet(
          onSelect: (mobile) {
            mobileController.text = mobile;
            controller.updateMobileInput(mobile);
            controller.checkMobile();
          },
        ),
      );
    }

    void openAccountTypeSheet() {
      KDialog.instance.openSheet(
        dialog: EducationAccountTypeSheet(
          selected: state.accountType,
          onSelect: controller.updateAccountType,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Enter Recipient Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label(text: 'Recipient\'s Mobile Number'),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter mobile number',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: const BorderSide(
                                    color: AppColors.lightBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: const BorderSide(
                                    color: AppColors.lightBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide:
                                    const BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 14.h,
                              ),
                              suffixIcon: state.isCheckingMobile
                                  ? Padding(
                                      padding: EdgeInsets.all(12.r),
                                      child: SizedBox(height: 18.r,
                                        width: 18.r,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            onChanged: controller.updateMobileInput,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        InkWell(
                          onTap: openContacts,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            height: 45.h,
                            width: 45.h,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: const Icon(
                              Icons.contacts_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (state.mobileErrorMessage != null) ...[
                      SizedBox(height: 6.h),
                      Text(
                        state.mobileErrorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    if (state.showRecipientFields) ...[
                      SizedBox(height: 14.h),
                      Text(
                        'New Recipient At E-Rupaiya. Add More Details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.55),
                            ),
                      ),
                      SizedBox(height: 14.h),
                      const _Label(text: 'Recipient\'s Name'),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('Enter recipient name'),
                        onChanged: controller.updateRecipientName,
                      ),
                      SizedBox(height: 14.h),
                      const _Label(text: 'PAN Details'),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: panController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration('Enter PAN'),
                        onChanged: controller.updatePan,
                      ),
                      if (state.isVerifyingPan) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            SizedBox(height: 14.r,
                              width: 14.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Verifying PAN...',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        AppColors.textPrimary.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ] else if (state.panErrorMessage != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          state.panErrorMessage!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ] else if (state.panVerified) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppColors.green,
                              size: 16.r,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'PAN verified',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      if (state.panVerified) ...[
                        SizedBox(height: 14.h),
                        const _Label(text: 'Account Type'),
                        SizedBox(height: 8.h),
                        InkWell(
                          onTap: openAccountTypeSheet,
                          borderRadius: BorderRadius.circular(14.r),
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
                                  color: AppColors.textPrimary.withOpacity(0.6),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    state.accountType.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: state.accountType ==
                                                  EducationAccountType.none
                                              ? AppColors.textPrimary
                                                  .withOpacity(0.45)
                                              : AppColors.textPrimary,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.textPrimary.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (state.panVerified &&
                          state.accountType ==
                              EducationAccountType.bankDetails) ...[
                        SizedBox(height: 14.h),
                        const _Label(text: 'Account Number'),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: accountNoController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Account Number'),
                          onChanged: controller.updateAccountNumber,
                        ),
                        SizedBox(height: 14.h),
                        const _Label(text: 'IFSC Code'),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: ifscController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _inputDecoration('IFSC Code'),
                          onChanged: controller.updateIfsc,
                        ),
                        if (state.isVerifyingBank) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              SizedBox(height: 14.r,
                                width: 14.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Verifying bank details...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textPrimary
                                          .withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ] else if (state.bankErrorMessage != null) ...[
                          SizedBox(height: 8.h),
                          Text(
                            state.bankErrorMessage!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ] else if (state.bankVerified) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.verified,
                                color: AppColors.green,
                                size: 16.r,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Bank verified',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      SizedBox(height: 20.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'We will notify the recipient via WhatsApp/SMS to onboard and start receiving payments via E-Rupaiya.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.6),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.saveErrorMessage != null) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        state.saveErrorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                  CustomElevatedButton(
                    onPressed: _canPay(state)
                        ? () async {
                            final ok = await controller.saveBeneficiary();
                            if (!ok) return;
                            if (!context.mounted) return;
                            context.push(RouteConstants.educationFeesPayment);
                          }
                        : null,
                    label: state.isSavingBeneficiary ? 'Saving...' : 'Pay Now',
                    uppercaseLabel: false,
                    showArrow: false,
                    height: 42.h,
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

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    hintStyle: TextStyle(
      color: AppColors.textPrimary.withOpacity(0.4),
    ),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 14.w,
      vertical: 14.h,
    ),
  );
}

bool _canPay(EducationFeesState state) {
  if (!state.showRecipientFields) return false;
  if (state.isSavingBeneficiary) return false;
  if (!state.panVerified) return false;
  if (state.accountType != EducationAccountType.bankDetails) return false;
  return state.bankVerified;
}
