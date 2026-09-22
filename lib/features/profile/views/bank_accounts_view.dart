// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../../refer_and_earn/components/refer_and_earn_app_bar.dart';
import '../../refer_and_earn/repositories/bank_account_repository.dart';
import '../../refer_and_earn/views/add_bank_account_view.dart';
import '../../refer_and_earn/views/select_bank_view.dart';
import '../repositories/bank_accounts_repository.dart';

class BankAccountsView extends HookWidget {
  const BankAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // bottomNavigationBar: SafeArea(
      //   top: false,
      //   child: Padding(
      //     padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 18.h),
      //     child: CustomElevatedButton(
      //       label: 'Add New Bank Account',
      //       onPressed: openAddBank,
      //       height: 52.h,
      //       uppercaseLabel: false,
      //     ),
      //   ),
      // ),
      body: Stack(
        children: [
          Column(
            children: [
              ReferAndEarnAppBar(
                title: 'Bank Accounts',
                onHelp: () {},
                height: 260.h,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container(color: Colors.white)),
            ],
          ),
          Positioned.fill(
            top: 200.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26.r),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
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
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _BankAccountsShimmer();
    }
    if (snapshot.hasError) {
      return Text(
        'Failed to load bank accounts. Please try again.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withOpacity(0.6),
            ),
      );
    }

    final accounts = snapshot.data ?? const <BankAccountEntry>[];
    final existingAccount = accounts.isNotEmpty ? accounts.first : null;
    final isViewingDetails = useState(false);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (existingAccount == null)
          Text(
            'No bank accounts added yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
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
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textPrimary.withOpacity(0.4),
                    ),
                  ),
                  child: const Icon(Icons.account_balance_outlined),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Add New Bank Account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56A1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2.w,
              ),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bankName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    // if (account.verified)
                    //   Text(
                    //     'Verified',
                    //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    //           color: const Color(0xFF1B8E36),
                    //           fontWeight: FontWeight.w700,
                    //         ),
                    //   ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  _maskAccountNumber(account.accountNumber),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          CustomElevatedButton(
            onPressed: onView,
            label: 'View',
            height: 33.h,
            width: 90.w,
            uppercaseLabel: false,
            backgroundColor: const Color(0xFFE85A2C),
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
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
              label: 'Bank Name', value: _displayValue(account.bankName)),
          SizedBox(height: 12.h),
          _DetailRow(
            label: 'Account Holder Name',
            value: _displayValue(account.accountHolderName),
          ),
          SizedBox(height: 12.h),
          _DetailRow(
            label: 'Account Number',
            value: _displayValue(account.accountNumber),
          ),
          if ((account.ifsc ?? '').trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
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
                  height: 38.h,
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
                  height: 38.h,
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
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
                color: Color(0xFFE85A2C),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Delete Bank Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Are you sure you want to delete $bankName?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
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
                    child: const Text('Yes',
                        style: TextStyle(color: AppColors.white)),
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
          _CardSkeleton(height: 84.h),
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
      height: height.h,
      decoration: BoxDecoration(
        color: AppColors.lightBorder.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _Circle(size: 44),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Line(width: 120.w, height: 12.h),
                      SizedBox(height: 8.h),
                      _Line(width: 90.w, height: 10.h),
                    ],
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
      width: width.w,
      height: height.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
