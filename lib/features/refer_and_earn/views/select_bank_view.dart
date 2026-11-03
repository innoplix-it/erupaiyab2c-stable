// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_search_bar.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/screen_wrapper.dart';
import '../../services/components/credit_card/credit_card_figma_metrics.dart';
import '../repositories/bank_account_repository.dart';

// ---------------------------------------------------------------------------
// Select Receiver Bank
//
// Layout is the Credit Card bank listing (credit_card_listing_view.dart)
// copied 1:1 — same app bar, pinned search row, 3-column Popular Banks grid
// and All Banks rows with the tilt arrow — driven by the bank list API.
// Sizes go through CreditCardFigmaMetrics (440-wide Figma frame, MediaQuery
// scaled) exactly like the credit card screen, so both stay pixel-identical.
// ---------------------------------------------------------------------------

/// Placeholder rows for the loading skeleton (names never get painted).
const List<BankListItem> _mockBanks = [
  BankListItem(id: '1', bankName: 'HDFC Bank', bankCode: 'HDFC0000060'),
  BankListItem(id: '2', bankName: 'Axis Bank', bankCode: 'UTIB0000049'),
  BankListItem(id: '3', bankName: 'SBI Bank', bankCode: 'SBIN0000001'),
  BankListItem(id: '4', bankName: 'ICICI Bank', bankCode: 'ICIC0000087'),
  BankListItem(
      id: '5', bankName: 'Kotak Mahindra Bank', bankCode: 'KKBK0000001'),
  BankListItem(id: '6', bankName: 'RBL Bank', bankCode: 'RBLN0000014'),
];

class SelectBankView extends HookWidget {
  const SelectBankView({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = useMemoized(() => BankAccountRepository());
    final refreshKey = useState(0);
    final snapshot = useFuture(
      useMemoized(repository.fetchBanks, [refreshKey.value]),
    );
    final searchController = useTextEditingController();
    useListenable(searchController);

    final data = snapshot.data;
    final popularBanks = data?.popularBanks ?? const <BankListItem>[];
    final allBanks = data?.allBanks ?? const <BankListItem>[];

    final query = searchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;
    // Search flattens both lists (name or code match), popular entries first.
    final searchResults =
        isSearching ? _filterBanks(popularBanks, allBanks, query) : const [];
    // Figma: the grid shows the six popular banks, everything else is a row.
    final topPicks =
        isSearching ? const <BankListItem>[] : popularBanks.take(6).toList();
    final remaining = isSearching ? const <BankListItem>[] : allBanks;

    final isLoading = snapshot.connectionState == ConnectionState.waiting;
    final errorMessage = (snapshot.hasError || (data != null && !data.status))
        ? 'Failed to load banks. Please try again.'
        : null;
    final isEmpty = !isLoading &&
        errorMessage == null &&
        (isSearching
            ? searchResults.isEmpty
            : popularBanks.isEmpty && allBanks.isEmpty);

    void selectBank(BankListItem bank) => Navigator.of(context).pop(bank);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Select Receiver Bank',
            showHelp: true,
            // Figma keeps only the help mark on this screen.
            showBharatConnect: false,
            helpIconSize: 20,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Padding(
            // Same pinned gap as the Credit Card listing (sticky above list).
            padding: AppSearchBar.pinnedPadding,
            child: AppSearchBar(
              hintText: 'Search by Bank Name',
              controller: searchController,
              // Typed text only (+2 px vs the credit card bar); the hint
              // keeps the shared AppSearchBar size.
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                fontSize: CreditCardFigmaMetrics.s(context, 16),
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const _SelectBankSkeleton()
                : ScreenWrapper(
                    isFetching: false,
                    isEmpty: isEmpty,
                    emptyMessage: 'No banks found',
                    errorMessage: errorMessage,
                    actions: errorMessage != null
                        ? [
                            TextButton(
                              onPressed: () => refreshKey.value += 1,
                              child: Text(
                                'Retry',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      CreditCardFigmaMetrics.s(context, 14),
                                ),
                              ),
                            ),
                          ]
                        : null,
                    child: isSearching
                        ? ListView.builder(
                            primary: false,
                            padding: EdgeInsets.fromLTRB(
                              CreditCardFigmaMetrics.s(context, 24),
                              CreditCardFigmaMetrics.sy(context, 4),
                              CreditCardFigmaMetrics.s(context, 24),
                              CreditCardFigmaMetrics.sy(context, 16) +
                                  MediaQuery.paddingOf(context).bottom,
                            ),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) => _BankListTile(
                              bank: searchResults[index],
                              onTap: () => selectBank(searchResults[index]),
                            ),
                          )
                        : SingleChildScrollView(
                            primary: false,
                            padding: EdgeInsets.only(
                              bottom: CreditCardFigmaMetrics.sy(context, 16) +
                                  MediaQuery.paddingOf(context).bottom,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    CreditCardFigmaMetrics.s(context, 24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _PopularBankGrid(
                                    banks: topPicks,
                                    onSelect: selectBank,
                                  ),
                                  if (remaining.isNotEmpty) ...[
                                    SizedBox(
                                        height: CreditCardFigmaMetrics.sy(
                                            context, 18)),
                                    _sectionHeading(context, 'All Banks'),
                                    SizedBox(
                                        height: CreditCardFigmaMetrics.sy(
                                            context, 12)),
                                    Column(
                                      children: [
                                        for (final bank in remaining)
                                          _BankListTile(
                                            bank: bank,
                                            onTap: () => selectBank(bank),
                                          ),
                                      ],
                                    ),
                                  ],
                                  SizedBox(
                                      height: CreditCardFigmaMetrics.sy(
                                          context, 12)),
                                ],
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionHeading(BuildContext context, String title) {
  return Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
  );
}

/// Popular + all-bank entries matching [query] on name or code, de-duplicated
/// so a bank present in both lists is offered once.
List<BankListItem> _filterBanks(
  List<BankListItem> popularBanks,
  List<BankListItem> allBanks,
  String query,
) {
  final matches = <BankListItem>[];
  final seen = <String>{};
  for (final bank in <BankListItem>[...popularBanks, ...allBanks]) {
    final key = bank.id.isNotEmpty ? bank.id : bank.bankName.toLowerCase();
    if (seen.contains(key)) continue;
    final haystack = '${bank.bankName} ${bank.bankCode}'.toLowerCase();
    if (haystack.contains(query)) {
      seen.add(key);
      matches.add(bank);
    }
  }
  return matches;
}

/// "State Bank of India" + "SBIN0000001" → "State Bank Of India (SBIN0000001)".
String _formatBankName(BankListItem bank) {
  final code = bank.bankCode.trim();
  if (code.isEmpty) return bank.bankName;
  final lowerName = bank.bankName.toLowerCase();
  if (lowerName.contains(code.toLowerCase())) return bank.bankName;
  return '${bank.bankName} ($code)';
}

/// Row label casing shared with the credit card listing rows.
String _titleCase(String value) => value
    .split(RegExp(r'\s+'))
    .map((word) =>
        word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
    .join(' ');

/// Figma "Popular Banks" block: heading + 3 tiles per row with a 16 gap in
/// both directions. Hidden when the API sends no popular banks.
class _PopularBankGrid extends StatelessWidget {
  const _PopularBankGrid({required this.banks, required this.onSelect});

  final List<BankListItem> banks;
  final ValueChanged<BankListItem> onSelect;

  @override
  Widget build(BuildContext context) {
    if (banks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(context, 'Popular Banks'),
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 12)),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = CreditCardFigmaMetrics.s(context, 16);
            const columns = 3;
            final tileWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final bank in banks)
                  SizedBox(
                    width: tileWidth,
                    child: _BankGridTile(
                      bank: bank,
                      onTap: () => onSelect(bank),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BankGridTile extends StatelessWidget {
  const _BankGridTile({required this.bank, this.onTap});

  final BankListItem bank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pad = CreditCardFigmaMetrics.s(context, 16);
    final iconSize = CreditCardFigmaMetrics.s(context, 50);
    final gap = CreditCardFigmaMetrics.s(context, 8);
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: CreditCardFigmaMetrics.s(context, 12),
          height: 1.4,
        );
    final textHeight =
        2 * (labelStyle?.fontSize ?? 12) * (labelStyle?.height ?? 1.4);
    final tileHeight = CreditCardFigmaMetrics.sy(context, 122);

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(CreditCardFigmaMetrics.s(context, 16)),
      child: Container(
        height: tileHeight,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(CreditCardFigmaMetrics.s(context, 16)),
          border: Border.all(
            color: const Color(0xFFE4E4E4).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            // Figma drop shadow 1: Y 4, blur 8, #B3B3B3 @10%.
            BoxShadow(
              color: const Color(0xFFB3B3B3).withOpacity(0.10),
              blurRadius: CreditCardFigmaMetrics.s(context, 8),
              offset: Offset(0, CreditCardFigmaMetrics.sy(context, 4)),
            ),
            // Figma drop shadow 2: Y 14, blur 14, #B3B3B3 @9%.
            BoxShadow(
              color: const Color(0xFFB3B3B3).withOpacity(0.09),
              blurRadius: CreditCardFigmaMetrics.s(context, 14),
              offset: Offset(0, CreditCardFigmaMetrics.sy(context, 14)),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxHeight - gap - textHeight;
            final side = iconSize > available ? available : iconSize;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ProviderIconFrame(
                  size: side,
                  child: _BankLogo(
                    name: bank.bankName,
                    iconUrl: bank.logoUrl,
                    // frame 50 - 2x3 padding - 2x1 border = 42 logo area.
                    size: side - CreditCardFigmaMetrics.s(context, 8),
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(
                        CreditCardFigmaMetrics.s(context, 14)),
                  ),
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: textHeight,
                  child: Text(
                    bank.bankName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    // Exactly the "All Banks" row text (no overrides).
                    style: labelStyle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BankListTile extends StatelessWidget {
  const _BankListTile({required this.bank, this.onTap});

  final BankListItem bank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const borderWidth = 1.0;
    final cardSize = CreditCardFigmaMetrics.s(context, 50);
    final cardPadding = CreditCardFigmaMetrics.s(context, 4);
    final logoSize = cardSize - 2 * (cardPadding + borderWidth);
    final arrowSize = CreditCardFigmaMetrics.s(context, 24);
    // Same Figma row gap rule as Electricity (screen width, not .h).
    final screenWidth = MediaQuery.sizeOf(context).width;
    final rowGap = screenWidth * 20 / 440;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: rowGap / 2),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: cardSize),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: cardSize,
                height: cardSize,
                padding: EdgeInsets.all(cardPadding),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                      CreditCardFigmaMetrics.s(context, 16)),
                  border: Border.all(
                    color: AppColors.lightBorder2,
                    width: borderWidth,
                  ),
                ),
                child: _BankLogo(
                  name: bank.bankName,
                  iconUrl: bank.logoUrl,
                  size: logoSize,
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(
                      CreditCardFigmaMetrics.s(context, 12)),
                ),
              ),
              SizedBox(width: CreditCardFigmaMetrics.s(context, 10)),
              Expanded(
                child: Text(
                  _titleCase(_formatBankName(bank)),
                  // Shared operator-name text (AppTextStyles.operatorName),
                  // identical to the credit card provider rows so every
                  // module's name renders at one size.
                  style: AppTextStyles.operatorName(context),
                ),
              ),
              SizedBox(width: CreditCardFigmaMetrics.s(context, 10)),
              Image.asset(
                FileConstants.tiltArrow,
                width: arrowSize,
                height: arrowSize,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  const _BankLogo({
    required this.name,
    required this.iconUrl,
    required this.size,
    required this.backgroundColor,
    required this.borderRadius,
  });

  final String name;
  final String? iconUrl;
  final double size;
  final Color backgroundColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '';
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

    if (iconUrl == null || iconUrl!.isEmpty) {
      return fallback;
    }

    return AppNetworkImage(
      url: iconUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      borderRadius: borderRadius,
      placeholder: fallback,
      errorWidget: fallback,
    );
  }
}

class _ProviderIconFrame extends StatelessWidget {
  const _ProviderIconFrame({
    required this.child,
    required this.size,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(CreditCardFigmaMetrics.s(context, 3)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(CreditCardFigmaMetrics.s(context, 18)),
        border: Border.all(color: AppColors.lightBorder, width: 1),
      ),
      child: child,
    );
  }
}

/// Loading state shaped like the loaded screen (grid + rows) so nothing jumps
/// when the bank list arrives. The pinned search row above is real, so it is
/// not repeated here.
class _SelectBankSkeleton extends StatelessWidget {
  const _SelectBankSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: SingleChildScrollView(
          primary: false,
          padding: EdgeInsets.fromLTRB(
            CreditCardFigmaMetrics.s(context, 24),
            0,
            CreditCardFigmaMetrics.s(context, 24),
            CreditCardFigmaMetrics.sy(context, 16) +
                MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PopularBankGrid(banks: _mockBanks, onSelect: (_) {}),
              SizedBox(height: CreditCardFigmaMetrics.sy(context, 18)),
              _sectionHeading(context, 'All Banks'),
              SizedBox(height: CreditCardFigmaMetrics.sy(context, 12)),
              for (final bank in _mockBanks)
                _BankListTile(bank: bank, onTap: null),
            ],
          ),
        ),
      ),
    );
  }
}
