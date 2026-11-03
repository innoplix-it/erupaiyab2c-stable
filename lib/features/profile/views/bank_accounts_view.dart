// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../../refer_and_earn/components/refer_and_earn_app_bar.dart';
import '../../refer_and_earn/repositories/bank_account_repository.dart';
import '../../refer_and_earn/views/add_bank_account_view.dart';
import '../../refer_and_earn/views/select_bank_view.dart';
import '../repositories/bank_accounts_repository.dart';

const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kTextGrey = Color(0xFF71717A);
const Color _kCardBorder = Color(0xFFE4E4E4);

TextStyle _ts(double size, FontWeight weight, Color color) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size.sp,
    fontWeight: weight,
    color: color,
  );
}

class BankAccountsView extends HookWidget {
  const BankAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    final headerHeight = 260.h;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              ReferAndEarnAppBar(
                title: 'Bank Accounts',
                height: headerHeight,
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_outlined,
                        color: Colors.white,
                        size: 30.r,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 26.w),
                      child: Text(
                        'Select Your Bank To Link It With Your Wallet For Withdrawals.',
                        textAlign: TextAlign.center,
                        style: _ts(13, FontWeight.w500, Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container(color: Colors.white)),
            ],
          ),
          Positioned.fill(
            top: headerHeight - 60.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26.r),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 12.h),
                child: const BankAccountsSection(
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BankAccountsSection extends HookWidget {
  const BankAccountsSection({
    super.key,
    this.padding,
  });

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final refreshKey = useState(0);
    final repository = useMemoized(() => BankAccountsRepository());
    final future = useMemoized(
      () => repository.fetchAccounts(),
      [refreshKey.value],
    );
    final snapshot = useFuture(future);

    Future<void> openAddBank([BankAccountEntry? account]) async {
      if (account == null) {
        final selected = await Navigator.of(context).push<BankListItem>(
          MaterialPageRoute(
            builder: (_) => const SelectBankView(),
          ),
        );
        if (selected == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AddBankAccountView(selectedBankName: selected.bankName),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddBankAccountView(existingAccount: account),
          ),
        );
      }
      refreshKey.value += 1;
    }

    Future<void> openEditBank(BankAccountEntry account) async {
      final selected = await Navigator.of(context).push<BankListItem>(
        MaterialPageRoute(
          builder: (_) => const SelectBankView(),
        ),
      );
      if (selected == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddBankAccountView(
            existingAccount: account,
            selectedBankName: selected.bankName,
          ),
        ),
      );
      refreshKey.value += 1;
    }

    final body = BankAccountsPanel(
      snapshot: snapshot,
      onAddBank: openAddBank,
      onEditBank: openEditBank,
      refresh: () => refreshKey.value += 1,
    );

    if (padding == null) return body;
    return Padding(
      padding: padding!,
      child: body,
    );
  }
}

class BankAccountsPanel extends HookWidget {
  const BankAccountsPanel({
    required this.snapshot,
    required this.onAddBank,
    required this.onEditBank,
    required this.refresh,
    super.key,
  });

  final AsyncSnapshot<List<BankAccountEntry>> snapshot;
  final void Function([BankAccountEntry?]) onAddBank;
  final Future<void> Function(BankAccountEntry) onEditBank;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context) {
    // Hooks must be called before any early return.
    final isViewingDetails = useState(false);

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _BankAccountsShimmer();
    }
    if (snapshot.hasError) {
      return Text(
        'Failed to load bank accounts. Please try again.',
        style: _ts(12, FontWeight.w400, AppColors.textPrimary.withOpacity(0.6)),
      );
    }

    final accounts = snapshot.data ?? const <BankAccountEntry>[];
    final existingAccount = accounts.isNotEmpty ? accounts.first : null;

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (existingAccount == null)
            Text(
              'No bank accounts added yet.',
              style: _ts(
                12,
                FontWeight.w400,
                AppColors.textPrimary.withOpacity(0.6),
              ),
            )
          else ...[
            _BankAccountSummaryCard(
              account: existingAccount,
              onView: () {
                if (!isViewingDetails.value) {
                  isViewingDetails.value = true;
                }
              },
            ),
            if (isViewingDetails.value) ...[
              SizedBox(height: 10.h),
              _BankAccountDetailsCard(
                account: existingAccount,
                onChange: () => onEditBank(existingAccount),
                onDelete: () async {
                  if (existingAccount.id == null) {
                    AppSnackbar.show('Unable to delete bank account.');
                    return;
                  }

                  final dialog = _ConfirmDeleteBankDialog(
                    bankName: existingAccount.bankName,
                    onCancel: () => Navigator.of(context).pop(),
                    onConfirm: () async {
                      Navigator.of(context).pop();
                      try {
                        final response = await BankAccountsRepository()
                            .deleteBank(bankId: existingAccount.id!);
                        if (response.status) {
                          AppSnackbar.show(response.message.isEmpty
                              ? 'Bank account deleted successfully.'
                              : response.message);
                          refresh();
                        } else {
                          AppSnackbar.show(response.message.isEmpty
                              ? 'Failed to delete bank account.'
                              : response.message);
                        }
                      } catch (e) {
                        AppSnackbar.show('Failed to delete bank account.');
                      }
                    },
                  );
                  await KDialog.instance.openDialog(dialog: dialog);
                },
              ),
            ],
          ],
          if (existingAccount == null) ...[
            SizedBox(height: 14.h),
            InkWell(
              onTap: () => onAddBank(),
              borderRadius: BorderRadius.circular(12.r),
              child: Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textPrimary.withOpacity(0.4),
                      ),
                    ),
                    child: Icon(Icons.account_balance_outlined, size: 20.r),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Add New Bank Account',
                    style: _ts(13, FontWeight.w600, AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Figma: white card, 12 radius, 1px #E4E4E4 border, 33 logo, small View button.
class _BankAccountSummaryCard extends StatelessWidget {
  const _BankAccountSummaryCard({
    required this.account,
    required this.onView,
  });

  final BankAccountEntry account;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final bankName =
        account.bankName.isNotEmpty ? account.bankName : 'Bank Account';
    // Figma Frame 1984078054: Fill(392) x Hug(72), radius 8, 1px #E4E4E4
    // border, 16 padding, space-between inner alignment, #FFFFFF.
    return Container(
      constraints: BoxConstraints(minHeight: 72.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _kCardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: (account.bankLogo ?? '').isNotEmpty
                ? AppNetworkImage(
                    url: account.bankLogo,
                    width: 33.r,
                    height: 33.r,
                    fit: BoxFit.cover,
                    showShimmer: false,
                  )
                : Container(
                    width: 33.r,
                    height: 33.r,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A56A1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 16.r,
                    ),
                  ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(13, FontWeight.w500, _kTextDark),
                ),
                SizedBox(height: 2.h),
                Text(
                  _maskAccountNumber(account.accountNumber),
                  style: _ts(12, FontWeight.w400, const Color(0xFF000000)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          CustomElevatedButton(
            onPressed: onView,
            label: 'View',
            height: 42.h,
            width: 88.w,
            borderRadius: 8.r,
            uppercaseLabel: false,
            labelStyle: _ts(14, FontWeight.w500, Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BankAccountDetailsCard extends StatelessWidget {
  const _BankAccountDetailsCard({
    required this.account,
    required this.onChange,
    required this.onDelete,
  });

  final BankAccountEntry account;
  final VoidCallback onChange;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
              label: 'Bank Name', value: _displayValue(account.bankName)),
          SizedBox(height: 10.h),
          _DetailRow(
            label: 'Account Holder Name',
            value: _displayValue(account.accountHolderName),
          ),
          SizedBox(height: 10.h),
          _DetailRow(
            label: 'Account Number',
            value: _displayValue(account.accountNumber),
          ),
          if ((account.ifsc ?? '').trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            _DetailRow(
              label: 'IFSC Code',
              value: _displayValue(account.ifsc ?? ''),
            ),
          ],
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  onPressed: onDelete,
                  label: 'Delete',
                  height: 34.h,
                  uppercaseLabel: false,
                  isBorder: true,
                  backgroundColor: Colors.white,
                  labelColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomElevatedButton(
                  onPressed: onChange,
                  label: 'Change',
                  height: 34.h,
                  uppercaseLabel: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _ts(12, FontWeight.w400, _kTextGrey)),
        SizedBox(height: 2.h),
        Text(value, style: _ts(13, FontWeight.w500, _kTextDark)),
      ],
    );
  }
}

String _displayValue(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '-' : trimmed;
}

String _maskAccountNumber(String value) {
  final digits = value.replaceAll(RegExp(r'\s+'), '');
  if (digits.isEmpty) return '-';
  final last4 =
      digits.length > 4 ? digits.substring(digits.length - 4) : digits;
  return '********$last4';
}

class _ConfirmDeleteBankDialog extends StatelessWidget {
  const _ConfirmDeleteBankDialog({
    required this.bankName,
    required this.onCancel,
    required this.onConfirm,
  });

  final String bankName;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECE8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance,
                size: 40.r,
                color: const Color(0xFFE85A2C),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Delete Bank Account',
              style: _ts(18, FontWeight.w700, AppColors.textPrimary),
            ),
            SizedBox(height: 10.h),
            Text(
              'Are you sure you want to delete $bankName?',
              textAlign: TextAlign.center,
              style: _ts(
                13,
                FontWeight.w400,
                AppColors.textPrimary.withOpacity(0.75),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text(
                      'No',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85A2C),
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: AppColors.white),
                    ),
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

class _BankAccountsShimmer extends StatelessWidget {
  const _BankAccountsShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardSkeleton(height: 58.h),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lightBorder.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            const _Circle(size: 33),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(width: 120.w, height: 10.h),
                  SizedBox(height: 6.h),
                  _Line(width: 90.w, height: 8.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value * 3 - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                AppColors.lightBorder.withOpacity(0.2),
                AppColors.lightBorder.withOpacity(0.6),
                AppColors.lightBorder.withOpacity(0.2),
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: const Alignment(-1, -0.3),
              end: const Alignment(1, 0.3),
              transform: _SlidingGradientTransform(value),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.r,
      width: size.r,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
