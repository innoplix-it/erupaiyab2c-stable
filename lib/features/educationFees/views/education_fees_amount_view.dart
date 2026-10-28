// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/my_app_bar.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import 'education_fees_tutors_view.dart';

/// Figma artboard width. Every Tuition-screen size is (figmaPx * unit).
const double _kFigmaW = 448.0;

/// Max width the content grows to on tablets / large screens.
const double _kMaxContentW = 560.0;

/// Shown until the API limits are loaded (matches Figma).
const double _kDefaultMinAmount = 100;
const double _kDefaultMaxAmount = 200000;

const Color _kMint = Color(0xFFB5FFDA);

/// Scale factor relative to the Figma artboard, clamped for small / large devices.
double _unit(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w.clamp(320.0, _kMaxContentW) / _kFigmaW;
}

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
    final isTuition = resolvedFeeType == 'Tuition Fees';

    final amountController = useTextEditingController();
    final amountFocusNode = useFocusNode();
    final suppressAmountSync = useRef(false);

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

    useEffect(() {
      if (!isTuition) return null;
      Future.microtask(controller.prefetchAmountLimits);
      return null;
    }, [isTuition]);

    useEffect(() {
      suppressAmountSync.value = true;
      amountController.clear();
      Future.microtask(() {
        suppressAmountSync.value = false;
        controller.updateAmountInput('');
      });
      return () {
        suppressAmountSync.value = true;
        amountController.clear();
        Future.microtask(() => controller.updateAmountInput(''));
      };
    }, [resolvedFeeType]);

    useListenable(amountController);
    final amountValue = _parseAmount(amountController.text);
    final amountError = state.amountErrorMessage;
    final hasInput = amountController.text.trim().isNotEmpty;
    // Empty field only disables the button. Min/max is decided by the API.
    final canContinue = isTuition
        ? hasInput && !state.isValidatingAmount && !isFetchingTutors.value
        : amountValue > 0 &&
            !state.isValidatingAmount &&
            !isFetchingTutors.value;

    Future<void> handleContinue() async {
      if (!canContinue) return;
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
                amount: amountValue,
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

    final continueLabel = state.isValidatingAmount
        ? 'Validating...'
        : isFetchingTutors.value
            ? 'Loading...'
            : 'Continue';

    final u = _unit(context);
    final continueButton = CustomElevatedButton(
      onPressed: canContinue ? handleContinue : null,
      label: continueLabel,
      uppercaseLabel: false,
      showArrow: false,
      height: 52 * u,
      borderRadius: 26 * u,
      backgroundColor:
          canContinue ? const Color(0xFFDD5428) : const Color(0xFFD4D4D8),
      labelColor: Colors.white,
    );

    return EducationFeesTheme(
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) return;
          suppressAmountSync.value = true;
          amountController.clear();
          controller.updateAmountInput('');
        },
      child: Scaffold(
        backgroundColor: isTuition ? _kMint : Colors.white,
          appBar: MyAppBar(
            title: isTuition ? feeChipLabel : resolvedFeeType,
            showHelp: true,
            showBharatConnect: false,
            showDivider: false,
            fitTitle: true,
            titleStyle: MyAppBar.sharedTitleStyle(context),
            backgroundColor: isTuition ? _kMint : null,
            helpIconSize: 20,
            onBack: () {
              suppressAmountSync.value = true;
              amountController.clear();
              controller.updateAmountInput('');
              Navigator.of(context).maybePop();
            },
          ),
          body: ColoredBox(
            color: Colors.white,
            child: Stack(
              children: [
                // Mint → white fade only at the top (as in Figma), rest is white.
                if (isTuition)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 300 * u,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_kMint, Color(0xFFFFFFFF)],
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: MediaQuery.withClampedTextScaling(
                    minScaleFactor: 1.0,
                    maxScaleFactor: 1.15,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: _kMaxContentW),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                child: isTuition
                                    ? Column(
                                        children: [
                                          _TuitionAmountBody(
                                            feeChipLabel: feeChipLabel,
                                            paymentName: resolvedFeeType,
                                            amountController: amountController,
                                            amountFocusNode: amountFocusNode,
                                            amountError: amountError,
                                            minAmount: state.minAmount,
                                            maxAmount: state.maxAmount,
                                            amountLimitHint:
                                                state.amountLimitHint,
                                            hasAmount: hasInput,
                                            onAmountChanged: (value) {
                                              if (suppressAmountSync.value) {
                                                return;
                                              }
                                              controller
                                                  .updateAmountInput(value);
                                            },
                                          ),
                                          SizedBox(height: 24 * u),
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              20 * u,
                                              0,
                                              20 * u,
                                              16 * u,
                                            ),
                                            child: continueButton,
                                          ),
                                        ],
                                      )
                                    : _LegacyAmountBody(
                                        resolvedFeeType: resolvedFeeType,
                                        feeChipLabel: feeChipLabel,
                                        amountController: amountController,
                                        amountFocusNode: amountFocusNode,
                                        amountError: amountError,
                                        onAmountChanged: (value) {
                                          if (suppressAmountSync.value) return;
                                          controller.updateAmountInput(value);
                                        },
                                      ),
                              ),
                            ),
                            if (!isTuition && amountValue > 0)
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20 * u,
                                  8 * u,
                                  20 * u,
                                  24 * u,
                                ),
                                child: continueButton,
                              ),
                          ],
                        ),
                      ),
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
}

class _TuitionAmountBody extends StatelessWidget {
  const _TuitionAmountBody({
    required this.feeChipLabel,
    required this.paymentName,
    required this.amountController,
    required this.amountFocusNode,
    required this.amountError,
    required this.minAmount,
    required this.maxAmount,
    required this.amountLimitHint,
    required this.hasAmount,
    required this.onAmountChanged,
  });

  final String feeChipLabel;
  final String paymentName;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String? amountError;
  final double? minAmount;
  final double? maxAmount;
  final String? amountLimitHint;
  final bool hasAmount;
  final ValueChanged<String> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final u = _unit(context);
    final circle = 138 * u;
    final scale = circle / 138;
    final caption = (amountLimitHint != null && amountLimitHint!.isNotEmpty)
        ? amountLimitHint!
        : _minMaxLabel(
            minAmount ?? _kDefaultMinAmount,
            maxAmount ?? _kDefaultMaxAmount,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(20 * u, 24 * u, 20 * u, 8 * u),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero circle (white disc with soft shadow, illustration clipped inside)
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1A000000),
                  blurRadius: 18 * u,
                  offset: Offset(0, 6 * u),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -29 * scale,
                    top: -6 * scale,
                    width: 196 * scale,
                    height: 244 * scale,
                    child: SvgPicture.asset(
                      FileConstants.tuitionFeeHeroSvg,
                      width: 196 * scale,
                      height: 244 * scale,
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16 * u),
          Text(
            'Enter Amount',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontSize: 20 * u,
                  height: 1.15,
                ),
          ),
          SizedBox(height: 8 * u),
          Text(
            'Enter the amount for $paymentName payment',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF71717A),
                  fontWeight: FontWeight.w500,
                  fontSize: 14 * u,
                  height: 1.35,
                ),
          ),
          if (amountError != null) ...[
            SizedBox(height: 10 * u),
            Text(
              amountError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13 * u,
                  ),
            ),
          ],
          SizedBox(height: 45 * u),
          _AmountCard(
            feeChipLabel: feeChipLabel,
            amountController: amountController,
            amountFocusNode: amountFocusNode,
            hasAmount: hasAmount,
            onAmountChanged: onAmountChanged,
          ),
          if (caption.isNotEmpty) ...[
            SizedBox(height: 18 * u),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF71717A),
                    fontWeight: FontWeight.w500,
                    fontSize: 13 * u,
                    height: 1.3,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.feeChipLabel,
    required this.amountController,
    required this.amountFocusNode,
    required this.hasAmount,
    required this.onAmountChanged,
  });

  final String feeChipLabel;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final bool hasAmount;
  final ValueChanged<String> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final u = _unit(context);
    final fontSize = 36 * u;
    final amountTextStyle = EducationFeesTheme.style(
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0C0A09),
        height: 1,
      ),
    );
    final rupeeW = 24 * u;
    final rupeeH = 30 * u;
    final capSize = 16 * u;
    final cardHeight = 103 * u;
    final chipHeight = 32 * u;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: chipHeight * 0.42),
          child: Container(
            width: double.infinity,
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16 * u),
              border: Border.all(
                color: const Color(0x80D7D7D7),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x26C7C7C7),
                  offset: Offset(0, 8 * u),
                  blurRadius: 20 * u,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inner = constraints.maxWidth;
                final digits = amountController.text;

                // Measure the real text width so the "₹ + amount" group is
                // always centered, on every device / font scale.
                final painter = TextPainter(
                  text: TextSpan(text: digits, style: amountTextStyle),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                )..layout();
                final textW = painter.width;
                painter.dispose();
                final fieldWidth = (textW + 4 * u).clamp(4.0, inner * 0.7);

                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IgnorePointer(
                        child: SvgPicture.asset(
                          FileConstants.rupeeAmountSvg,
                          width: rupeeW,
                          height: rupeeH,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 6 * u),
                      // Single TextField for both states -> focus / keyboard
                      // never drops when the first digit is typed.
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: amountController,
                          focusNode: amountFocusNode,
                          autofocus: true,
                          maxLines: 1,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.left,
                          cursorColor: const Color(0xFF0C0A09),
                          style: amountTextStyle,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: onAmountChanged,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          height: chipHeight,
          padding: EdgeInsets.symmetric(horizontal: 12 * u),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(chipHeight / 2),
            border: Border.all(color: const Color(0xFFD5D5D5), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                FileConstants.tuitionFeeCapSvg,
                width: capSize,
                height: capSize,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 4 * u),
              Text(
                feeChipLabel,
                style: MyAppBar.sharedTitleStyle(context)?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13 * u,
                      letterSpacing: 0,
                      height: 1,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegacyAmountBody extends StatelessWidget {
  const _LegacyAmountBody({
    required this.resolvedFeeType,
    required this.feeChipLabel,
    required this.amountController,
    required this.amountFocusNode,
    required this.amountError,
    required this.onAmountChanged,
  });

  final String resolvedFeeType;
  final String feeChipLabel;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String? amountError;
  final ValueChanged<String> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 2200 / 925,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bannerHeight = constraints.maxHeight;
              return Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    _feeBannerAsset(resolvedFeeType),
                    height: bannerHeight,
                    width: constraints.maxWidth,
                    fit: BoxFit.cover,
                    alignment: resolvedFeeType == 'House Rent'
                        ? const Alignment(0, -0.55)
                        : Alignment.center,
                  ),
                  Positioned(
                    top: bannerHeight * 42 / 140 - 10.r,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _feeChipIcon(
                        resolvedFeeType,
                        color: Colors.white,
                        size: 20.r,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -bannerHeight * 20 / 140,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26.r),
                        border: Border.all(color: AppColors.lightBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10.r,
                            offset: Offset(0.w, 6.h),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _feeChipIcon(resolvedFeeType),
                          SizedBox(width: 8.w),
                          Text(
                            feeChipLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 36.h),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Enter Amount',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (amountError != null) ...[
                SizedBox(height: 6.h),
                Text(
                  amountError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              SizedBox(height: 16.h),
              AspectRatio(
                aspectRatio: 1648 / 516,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        FileConstants.amountBanner,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final amountTextStyle = EducationFeesTheme.style(
                          TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        );
                        final strut = StrutStyle(
                          fontSize: 32.sp,
                          height: 1,
                          forceStrutHeight: true,
                        );
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 16.w),
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
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textAlign: TextAlign.left,
                                textAlignVertical: TextAlignVertical.center,
                                strutStyle: strut,
                                style: amountTextStyle,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: onAmountChanged,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _minMaxLabel(double? minAmount, double? maxAmount) {
  final formatter = NumberFormat.decimalPattern('en_IN');
  final parts = <String>[];
  if (minAmount != null) {
    parts.add('Min Amount ${formatter.format(minAmount.round())}');
  }
  if (maxAmount != null) {
    parts.add('Max ₹${formatter.format(maxAmount.round())}');
  }
  return parts.join(' ');
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
  final lower = value.toLowerCase();
  if (lower.contains('tuition') || lower.contains('tution')) {
    return 'Tuition Fees';
  }
  if (lower.contains('school fee')) {
    return 'School Fees';
  }
  if (lower.contains('college fee')) {
    return 'College Fees';
  }
  if (lower.contains('house rent')) {
    return 'House Rent';
  }
  if (lower.contains('shop rent')) {
    return 'Shop Rent';
  }
  if (lower.contains('education')) {
    return 'Education Fees';
  }
  return value;
}

String _feeBannerAsset(String feeType) {
  switch (feeType) {
    case 'School Fees':
      return FileConstants.schoolFeesBanner;
    case 'College Fees':
      return FileConstants.collegeFeesBanner;
    case 'House Rent':
      return FileConstants.houseRentBanner;
    case 'Shop Rent':
      return FileConstants.shopRentBanner;
    default:
      return FileConstants.tutionFeesBanner;
  }
}

String? _feeChipIconAsset(String feeType) {
  switch (feeType) {
    case 'School Fees':
      return 'assets/images/svg/school_fees.svg';
    case 'College Fees':
      return 'assets/images/svg/college_fees.svg';
    case 'Tuition Fees':
      return 'assets/images/svg/tuition_fees.svg';
    case 'House Rent':
      return 'assets/images/svg/house_rent.svg';
    case 'Shop Rent':
      return 'assets/images/svg/shop_rent.svg';
    default:
      return null;
  }
}

Widget _feeChipIcon(String feeType, {Color? color, double? size}) {
  final iconSize = size ?? 18.r;
  final asset = _feeChipIconAsset(feeType);
  if (asset != null) {
    return SvgPicture.asset(
      asset,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      colorFilter:
          color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
  return Icon(
    (feeType == 'House Rent' || feeType == 'Shop Rent')
        ? Icons.home_outlined
        : Icons.school_outlined,
    color: color ?? AppColors.textPrimary,
    size: iconSize,
  );
}

String _feeChipLabel(String feeType) {
  switch (feeType) {
    case 'School Fees':
      return 'School Fee';
    case 'College Fees':
      return 'College Fee';
    case 'Education Fees':
      return 'Education Fee';
    case 'House Rent':
      return 'House Rent';
    case 'Shop Rent':
      return 'Shop Rent';
    case 'Tuition Fees':
      return 'Tuition Fee';
    default:
      return feeType;
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
    case 'House Rent':
      return 'House Rent';
    case 'Shop Rent':
      return 'Shop Rent';
    default:
      return feeType;
  }
}
