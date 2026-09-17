// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../controllers/education_fees_controller.dart';
import 'education_fees_tutors_view.dart';

class EducationFeesAmountView extends HookConsumerWidget {
  const EducationFeesAmountView({
    super.key,
    this.feeType,
  });

  final String? feeType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(educationFeesControllerProvider);
    final controller = ref.read(educationFeesControllerProvider.notifier);
    final repository = ref.read(educationFeesRepositoryProvider);
    final isFetchingTutors = useState(false);
    final resolvedFeeType = _normalizeFeeType(feeType);
    final feeChipLabel = _feeChipLabel(resolvedFeeType);

    final amountController = useTextEditingController(text: state.amountInput);
    final amountFocusNode = useFocusNode();

    useEffect(() {
      if (amountController.text != state.amountInput) {
        amountController.text = state.amountInput;
      }
      return null;
    }, [state.amountInput]);

    useEffect(() {
      Future.microtask(amountFocusNode.requestFocus);
      return null;
    }, const []);

    useEffect(() {
      Future.microtask(
        () => controller.updateFeeType(_toApiFeeType(resolvedFeeType)),
      );
      return null;
    }, [resolvedFeeType]);

    Future<void> handleContinue() async {
      controller.updateFeeType(_toApiFeeType(resolvedFeeType));
      final ok = await controller.validateAmount();
      if (!ok) return;
      if (!context.mounted) return;
      isFetchingTutors.value = true;
      try {
        final response = await repository.fetchBeneficiaries();
        if (!context.mounted) return;
        if (response.status && response.beneficiaries.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EducationFeesTutorsView(
                amount: _parseAmount(state.amountInput),
                tutors: response.beneficiaries,
              ),
            ),
          );
        } else {
          context.push(RouteConstants.educationFeesRecipient);
        }
      } catch (_) {
        AppSnackbar.show(
          'Unable to fetch tutors. Please try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } finally {
        isFetchingTutors.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Education Fees',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          FileConstants.tutionFeesBanner,
                          height: 140.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: -20.h,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 22.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26.r),
                              border: Border.all(
                                color: AppColors.lightBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  color: AppColors.textPrimary,
                                  size: 18.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  feeChipLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 36.h),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Enter Amount',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Enter the amount for $resolvedFeeType payment',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary.withOpacity(0.6),
                                ),
                          ),
                          SizedBox(height: 16.h),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                FileConstants.amountBanner,
                                width: double.infinity,
                                height: 120.h,
                                fit: BoxFit.contain,
                              ),
                              Builder(
                                builder: (context) {
                                  final amountTextStyle = TextStyle(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  );
                                  final strut = StrutStyle(
                                    fontSize: 32.sp,
                                    height: 1,
                                    forceStrutHeight: true,
                                  );
                                  return Row(
                                    // mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 45.w),
                                        child: Text(
                                          '₹',
                                          style: amountTextStyle,
                                          strutStyle: strut,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      SizedBox(
                                        width: 140.w,
                                        child: TextField(
                                          controller: amountController,
                                          focusNode: amountFocusNode,
                                          autofocus: true,
                                          maxLines: 1,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          textAlign: TextAlign.left,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          strutStyle: strut,
                                          style: amountTextStyle,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged:
                                              controller.updateAmountInput,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          if (state.amountErrorMessage != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              state.amountErrorMessage!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
              child: CustomElevatedButton(
                onPressed: (state.isValidatingAmount || isFetchingTutors.value)
                    ? null
                    : handleContinue,
                label: state.isValidatingAmount
                    ? 'Validating...'
                    : isFetchingTutors.value
                        ? 'Loading...'
                        : 'Continue',
                uppercaseLabel: false,
                showArrow: false,
                height: 42.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _parseAmount(String value) {
  final amount = double.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
  return amount.toDouble();
}

String _normalizeFeeType(String? rawValue) {
  if (rawValue == null || rawValue.trim().isEmpty) {
    return 'Tuition Fees';
  }
  final value = rawValue.trim();
  switch (value.toLowerCase()) {
    case 'tuition fees':
    case 'tution fees':
      return 'Tuition Fees';
    case 'school fees':
      return 'School Fees';
    case 'college fees':
      return 'College Fees';
    case 'education fees':
      return 'Education Fees';
    default:
      return value;
  }
}

String _feeChipLabel(String feeType) {
  switch (feeType) {
    case 'School Fees':
      return 'School Fee';
    case 'College Fees':
      return 'College Fee';
    case 'Education Fees':
      return 'Education Fee';
    case 'Tuition Fees':
    default:
      return 'Tuition Fee';
  }
}

String _toApiFeeType(String feeType) {
  switch (feeType) {
    case 'School Fees':
      return 'School Fee';
    case 'College Fees':
      return 'College Fee';
    case 'Tuition Fees':
    case 'Tution Fees':
      return 'Tuition Fee';
    default:
      return 'Tuition Fee';
  }
}
