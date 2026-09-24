// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_network_image.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../repositories/bank_account_repository.dart';

class SelectBankView extends HookWidget {
  const SelectBankView({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = useMemoized(() => BankAccountRepository());
    final query = useState('');
    final future = useMemoized(repository.fetchBanks);
    final snapshot = useFuture(future);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferAndEarnAppBar(
              title: 'Add Bank Account',
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
                    'Add Your Bank Details To Receive Withdrawal\nPayments Securely.',
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
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
                  child: _buildBody(
                    context,
                    snapshot,
                    query.value,
                    (next) => query.value = next,
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

Widget _buildBody(
  BuildContext context,
  AsyncSnapshot<BankListResponse> snapshot,
  String query,
  ValueChanged<String> onQuery,
) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(
      child: SpinKitCircle(
        color: AppColors.primary,
        size: 48,
      ),
    );
  }
  if (snapshot.hasError || !(snapshot.data?.status ?? false)) {
    return Text(
      'Failed to load banks. Please try again.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary.withOpacity(0.6),
          ),
    );
  }

  final data = snapshot.data!;
  final trimmedQuery = query.trim().toLowerCase();
  final popular = _filterBanks(data.popularBanks, trimmedQuery);
  final allBanks = _filterBanks(data.allBanks, trimmedQuery);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SearchField(
        initialValue: query,
        onChanged: onQuery,
      ),
      SizedBox(height: 20.h),
      Text(
        'Popular Banks',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
      SizedBox(height: 12.h),
      if (popular.isEmpty)
        Text(
          'No popular banks found.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.86,
          ),
          itemCount: popular.length,
          itemBuilder: (context, index) {
            final bank = popular[index];
            return _PopularBankCard(
              bank: bank,
              onTap: () => Navigator.of(context).pop(bank),
            );
          },
        ),
      SizedBox(height: 20.h),
      Text(
        'All Banks',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
      SizedBox(height: 8.h),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final bank = allBanks[index];
          return _AllBankRow(
            bank: bank,
            onTap: () => Navigator.of(context).pop(bank),
          );
        },
        separatorBuilder: (_, __) => Divider(
          height: 1.h,
          color: AppColors.lightBorder.withOpacity(0.8),
        ),
        itemCount: allBanks.length,
      ),
    ],
  );
}

List<BankListItem> _filterBanks(List<BankListItem> items, String query) {
  if (query.isEmpty) return items;
  return items
      .where((item) =>
          item.bankName.toLowerCase().contains(query) ||
          item.bankCode.toLowerCase().contains(query))
      .toList();
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.initialValue, required this.onChanged});

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search bank name',
          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.5),
              ),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.search,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _PopularBankCard extends StatelessWidget {
  const _PopularBankCard({required this.bank, required this.onTap});

  final BankListItem bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProviderIconFrame(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: AppNetworkImage(
                  url: bank.logoUrl,
                  width: 38.w,
                  height: 38.w,
                  fit: BoxFit.contain,
                  showShimmer: false,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              bank.bankName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllBankRow extends StatelessWidget {
  const _AllBankRow({required this.bank, required this.onTap});

  final BankListItem bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            _ProviderIconFrame(
              size: 44.w,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: AppNetworkImage(
                  url: bank.logoUrl,
                  width: 38.w,
                  height: 38.w,
                  fit: BoxFit.contain,
                  showShimmer: false,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                _formatBankName(bank),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatBankName(BankListItem bank) {
  final code = bank.bankCode.trim();
  if (code.isEmpty) return bank.bankName;
  final lowerName = bank.bankName.toLowerCase();
  if (lowerName.contains(code.toLowerCase())) return bank.bankName;
  return '${bank.bankName} ($code)';
}

class _ProviderIconFrame extends StatelessWidget {
  const _ProviderIconFrame({
    required this.child,
    this.size,
  });

  final Widget child;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 44.w,
      height: size ?? 44.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.lightBorder, width: 1),
      ),
      child: child,
    );
  }
}
