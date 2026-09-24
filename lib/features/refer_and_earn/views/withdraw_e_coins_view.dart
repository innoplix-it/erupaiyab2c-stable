// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../../kyc/views/kyc_verification_view.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/repositories/bank_accounts_repository.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../repositories/referral_wallet_repository.dart';
import 'add_bank_account_view.dart';

class WithdrawECoinsView extends HookConsumerWidget {
  const WithdrawECoinsView({super.key, required this.walletBalance});

  final String walletBalance;
  static const int minimumWithdrawCoins = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final totalBalanceDouble = _parseAmount(walletBalance);
    final totalBalance = totalBalanceDouble.floor();
    final controller = useTextEditingController();
    final amount = useState(0);
    final selectedPercent = useState<int?>(null);
    final bankAccounts = useState<List<BankAccountEntry>>([]);
    final isFetchingBanks = useState(false);
    final repository = useMemoized(() => BankAccountsRepository());
    final isAmountBelowMinimum =
        amount.value > 0 && amount.value < minimumWithdrawCoins;
    final canWithdraw = amount.value >= minimumWithdrawCoins;

    useEffect(() {
      controller.text = '0';
      return null;
    }, [controller]);

    Future<void> loadBanks() async {
      try {
        isFetchingBanks.value = true;
        bankAccounts.value = await repository.fetchAccounts();
      } catch (_) {
        bankAccounts.value = const <BankAccountEntry>[];
      } finally {
        isFetchingBanks.value = false;
      }
    }

    useEffect(() {
      Future.microtask(loadBanks);
      return null;
    }, const []);

    useEffect(() {
      Future.microtask(() {
        ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded();
      });
      return null;
    }, const []);

    void updateAmount(int nextAmount, {int? percent}) {
      final clamped = _clampAmount(nextAmount, totalBalance);
      amount.value = clamped;
      selectedPercent.value = percent;
      controller.value = TextEditingValue(
        text: clamped.toString(),
        selection: TextSelection.collapsed(offset: clamped.toString().length),
      );
    }

    void handlePercentTap(int percent) {
      final computed = (totalBalance * percent / 100).floor();
      updateAmount(computed, percent: percent);
    }

    void handleAmountChange(String raw) {
      final parsed = _parseAmount(raw).floor();
      final clamped = _clampAmount(parsed, totalBalance);
      if (clamped != parsed) {
        updateAmount(clamped, percent: _matchPercent(clamped, totalBalance));
        return;
      }
      amount.value = clamped;
      selectedPercent.value = _matchPercent(clamped, totalBalance);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 18.h),
        child: SafeArea(
          top: false,
          child: InkWell(
            onTap: !canWithdraw
                ? null
                : () async {
                    final isKycVerified =
                        profileState.profile?.isKycVerified == true;
                    if (!isKycVerified) {
                      AppSnackbar.show(
                        'Complete your KYC before withdrawing E-Coins.',
                      );
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const KycVerificationView(),
                        ),
                      );
                      if (!context.mounted) return;
                      await ref
                          .read(profileControllerProvider.notifier)
                          .fetchProfileIfNeeded(force: true);
                      return;
                    }
                    if (isFetchingBanks.value) return;
                    await loadBanks();
                    if (bankAccounts.value.isEmpty) {
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddBankAccountView(),
                        ),
                      );
                      if (!context.mounted) return;
                      await loadBanks();
                      return;
                    }
                    KDialog.instance.openSheet(
                      dialog: _WithdrawConfirmSheet(
                        amount: amount.value,
                        accounts: bankAccounts.value,
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(28.r),
            child: Container(
              height: 42.h,
              decoration: BoxDecoration(
                color: !canWithdraw
                    ? const Color(0xFFE85A2C).withOpacity(0.5)
                    : const Color(0xFFE85A2C),
                borderRadius: BorderRadius.circular(28.r),
              ),
              alignment: Alignment.center,
              child: Text(
                'Withdraw Now',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferAndEarnAppBar(
              title: 'Withdraw E-Coins',
              height: 300.h,
              body: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          FileConstants.coin_3d,
                          width: 30.w,
                          height: 30.w,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatAmount(totalBalanceDouble),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Current Balance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Text(
                      '1 = ₹1 | Get Real Cash Instant',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Coins',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: handleAmountChange,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 12.h),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 12.w, right: 8.w),
                            child: Image.asset(
                              FileConstants.coin_3d,
                              width: 18.w,
                              height: 18.w,
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 32.w,
                            minHeight: 32.w,
                          ),
                          suffixText: 'Coins',
                          suffixStyle:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide:
                                const BorderSide(color: AppColors.lightBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide:
                                const BorderSide(color: Color(0xFF1A56A1)),
                          ),
                        ),
                      ),
                      if (isAmountBelowMinimum) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Enter at least 100 E-Coins to withdraw.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Text(
                        'Min: $minimumWithdrawCoins Coins | Max: ${_formatAmount(totalBalanceDouble)} Coins',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          _PercentChip(
                            label: '25%',
                            active: selectedPercent.value == 25,
                            onTap: () => handlePercentTap(25),
                          ),
                          SizedBox(width: 10.w),
                          _PercentChip(
                            label: '50%',
                            active: selectedPercent.value == 50,
                            onTap: () => handlePercentTap(50),
                          ),
                          SizedBox(width: 10.w),
                          _PercentChip(
                            label: '75%',
                            active: selectedPercent.value == 75,
                            onTap: () => handlePercentTap(75),
                          ),
                          SizedBox(width: 10.w),
                          _PercentChip(
                            label: '100%',
                            active: selectedPercent.value == 100,
                            onTap: () => handlePercentTap(100),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      Center(
                        child: Text(
                          'You Will Receive',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              FileConstants.withdrawBanner,
                              height: 90.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Text(
                              '₹${amount.value}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'Note',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: 6.h),
                      const _NoteItem(
                        text: 'Minimum 100 E-Coins are required to withdraw.',
                      ),
                      const _NoteItem(
                        text:
                            'Coins Will Be Converted To INR Based On The Current Conversion Rate.',
                      ),
                      const _NoteItem(
                        text:
                            'Withdrawals Are Processed Within 24-48 Hours After Confirmation.',
                      ),
                      const _NoteItem(
                        text:
                            'Ensure Your Bank Account And KYC Are Verified Before Withdrawing.',
                      ),
                      const _NoteItem(
                        text:
                            'Once A Withdrawal Request Is Submitted, It Cannot Be Cancelled.',
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ),
              // SizedBox(height: 8.h),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentChip extends HookWidget {
  const _PercentChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          height: 38.h,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE6E6E6) : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.lightBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _NoteItem extends HookWidget {
  const _NoteItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

double _parseAmount(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9\\.]'), '');
  if (cleaned.isEmpty) return 0;
  final firstDot = cleaned.indexOf('.');
  if (firstDot == -1) {
    return double.tryParse(cleaned) ?? 0;
  }
  final normalized = cleaned.substring(0, firstDot + 1) +
      cleaned.substring(firstDot + 1).replaceAll('.', '');
  return double.tryParse(normalized) ?? 0;
}

int _clampAmount(int amount, int max) {
  if (amount < 0) return 0;
  if (amount > max) return max;
  return amount;
}

int? _matchPercent(int amount, int total) {
  if (total <= 0) return null;
  final percent = ((amount / total) * 100).round();
  if (percent == 25 || percent == 50 || percent == 75 || percent == 100) {
    return percent;
  }
  return null;
}

String _formatCoins(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _formatAmount(double value) {
  if (value % 1 == 0) {
    return _formatCoins(value.toInt());
  }
  final parts = value.toStringAsFixed(2).split('.');
  return '${_formatCoins(int.tryParse(parts[0]) ?? 0)}.${parts[1]}';
}

class _WithdrawConfirmSheet extends HookConsumerWidget {
  const _WithdrawConfirmSheet({
    required this.amount,
    required this.accounts,
  });

  final int amount;
  final List<BankAccountEntry> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);
    final isSubmitting = useState(false);
    final repository = useMemoized(() => ReferralWalletRepository());

    Future<void> handleConfirm() async {
      if (amount <= 0) {
        AppSnackbar.show('Enter a valid amount to withdraw.');
        return;
      }
      final selectedAccount = accounts[selectedIndex.value];
      final bankId = selectedAccount.id;
      if (bankId == null) {
        AppSnackbar.show('Selected bank account is invalid. Please try again.');
        return;
      }
      if (isSubmitting.value) return;
      try {
        isSubmitting.value = true;
        final response = await repository.withdrawEcoins(
          bankId: bankId,
          ecoins: amount,
        );
        if (!response.success) {
          _closeTopRoute();
          await _openWithdrawStatusDialog(
            status: _WithdrawStatus.failed,
            amount: amount,
          );
          return;
        }
        try {
          await repository.fetchSummary();
        } catch (_) {}
        final status = _resolveWithdrawStatus(response.message);
        if (status == _WithdrawStatus.success) {
          try {
            await ref.read(profileControllerProvider.notifier).fetchProfile();
          } catch (_) {}
        }
        _closeTopRoute();
        await _openWithdrawStatusDialog(
          status: status,
          amount: amount,
        );
      } catch (_) {
        _closeTopRoute();
        await _openWithdrawStatusDialog(
          status: _WithdrawStatus.failed,
          amount: amount,
        );
      } finally {
        isSubmitting.value = false;
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Withdrawal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            'The amount will be credited to your registered bank account\nwithin 24-48 hours.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0F9D58),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      FileConstants.coin_3d,
                      width: 14.w,
                      height: 14.w,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${_formatCoins(amount)} Coins = ₹${_formatCoins(amount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          ...accounts.asMap().entries.map((entry) {
            final index = entry.key;
            final account = entry.value;
            return GestureDetector(
              onTap: () => selectedIndex.value = index,
              child: Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8.r,
                      offset: Offset(0.w, 4.h),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A56A1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  account.bankName.isNotEmpty
                                      ? account.bankName
                                      : 'Bank Account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (account.verified)
                                Text(
                                  'Verified',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF1B8E36),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            account.accountNumber,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedIndex.value == index
                              ? const Color(0xFFE85A2C)
                              : AppColors.lightBorder,
                          width: 1.5,
                        ),
                      ),
                      child: selectedIndex.value == index
                          ? Center(
                              child: Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE85A2C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 6.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: isSubmitting.value ? null : handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85A2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: isSubmitting.value
                  ? SizedBox(width: 20.w,
                      height: 20.w,
                      child: const Center(
                        child: SpinKitCircle(
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                    )
                  : Text(
                      'Confirm Withdrawal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _WithdrawStatus { success, failed, requested }

_WithdrawStatus _resolveWithdrawStatus(String message) {
  final lower = message.trim().toLowerCase();
  if (lower.contains('request') ||
      lower.contains('submitted') ||
      lower.contains('pending')) {
    return _WithdrawStatus.requested;
  }
  if (lower.contains('success') ||
      lower.contains('withdrawn') ||
      lower.contains('credited')) {
    return _WithdrawStatus.success;
  }
  return _WithdrawStatus.requested;
}

Future<void> _openWithdrawStatusDialog({
  required _WithdrawStatus status,
  required int amount,
}) async {
  await Future.delayed(const Duration(milliseconds: 120));
  await KDialog.instance.openDialog(
    barrierDismissible: false,
    dialog: _WithdrawStatusDialog(
      status: status,
      amount: amount,
      onPrimary: () {
        if (status == _WithdrawStatus.failed) {
          _closeTopRoute();
          return;
        }
        _popToWallet();
      },
      onSecondary: () {
        if (status == _WithdrawStatus.failed) {
          _closeTopRoute();
          return;
        }
        _popToHome();
      },
    ),
  );
}

void _closeTopRoute() {
  final nav = navigatorKey.currentState;
  if (nav != null && nav.canPop()) {
    nav.pop();
  }
}

void _popToWallet() {
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  if (nav.canPop()) {
    nav.pop();
  }
  if (nav.canPop()) {
    nav.pop();
  }
}

void _popToHome() {
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  nav.popUntil((route) => route.isFirst);
}

class _WithdrawStatusDialog extends StatelessWidget {
  const _WithdrawStatusDialog({
    required this.status,
    required this.amount,
    required this.onPrimary,
    required this.onSecondary,
  });

  final _WithdrawStatus status;
  final int amount;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final config = _WithdrawStatusConfig.from(status);
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 24.h, 18.w, 22.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: config.gradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(26.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                color: config.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  config.iconAsset,
                  width: 50.w,
                  height: 50.w,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              config.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
            ),
            SizedBox(height: 10.h),
            Text(
              config.message(amount),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                    fontSize: 12.sp,
                  ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrimary,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: config.primaryBorder),
                      foregroundColor: config.primaryText,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text(
                      config.primaryLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: config.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSecondary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85A2C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text(
                      config.secondaryLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
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

class _WithdrawStatusConfig {
  const _WithdrawStatusConfig({
    required this.title,
    required this.iconAsset,
    required this.iconBackground,
    required this.gradient,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primaryBorder,
    required this.primaryText,
    required this.message,
  });

  final String title;
  final String iconAsset;
  final Color iconBackground;
  final List<Color> gradient;
  final String primaryLabel;
  final String secondaryLabel;
  final Color primaryBorder;
  final Color primaryText;
  final String Function(int amount) message;

  factory _WithdrawStatusConfig.from(_WithdrawStatus status) {
    switch (status) {
      case _WithdrawStatus.success:
        return _WithdrawStatusConfig(
          title: 'Withdrawal Successful',
          iconAsset: FileConstants.withdrawSuccess,
          iconBackground: Colors.transparent,
          gradient: const [Color(0xFFF38B6B), Color(0xFF052E6F)],
          primaryLabel: 'View Details',
          secondaryLabel: 'Back To Home',
          primaryBorder: const Color(0xFFE85A2C),
          primaryText: const Color(0xFFE85A2C),
          message: (amount) =>
              '₹${_formatCoins(amount)} has been successfully withdrawn.\nThe amount will be credited to your bank\naccount shortly.',
        );
      case _WithdrawStatus.failed:
        return _WithdrawStatusConfig(
          title: 'Withdrawal Failed',
          iconAsset: FileConstants.withdrawFailed,
          iconBackground: Colors.transparent,
          gradient: const [Color(0xFF5C1200), Color(0xFF052E6F)],
          primaryLabel: 'Contact Support',
          secondaryLabel: 'Retry',
          primaryBorder: const Color(0xFFE85A2C),
          primaryText: const Color(0xFFE85A2C),
          message: (amount) =>
              '₹${_formatCoins(amount)} withdrawal could not be processed.\nPlease try again or check your bank\ndetails.',
        );
      case _WithdrawStatus.requested:
        return _WithdrawStatusConfig(
          title: 'Withdrawal Requested',
          iconAsset: FileConstants.withdrawRequested,
          iconBackground: Colors.transparent,
          gradient: const [Color(0xFFF59E0B), Color(0xFF052E6F)],
          primaryLabel: 'View Details',
          secondaryLabel: 'Back To Home',
          primaryBorder: const Color(0xFFE85A2C),
          primaryText: const Color(0xFFE85A2C),
          message: (amount) =>
              '₹${_formatCoins(amount)} withdrawal request received.\nThe amount will be credited within 24\nhours.',
        );
    }
  }
}
