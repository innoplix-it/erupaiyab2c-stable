// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_search_bar.dart';
import '../../../widgets/common_service_svg_icon.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/home_icon_tile.dart';
import '../components/service_utils.dart';
import '../controllers/home_controller.dart';
import '../models/banner_model.dart';
import '../models/quick_action_model.dart';

class HomeSearchView extends HookConsumerWidget {
  const HomeSearchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final query = useState('');
    final isLoading = useState(false);
    final hasFetched = useState(false);
    final error = useState<String?>(null);
    // allResults holds the complete API data — never filtered.
    final allResults = useState<List<QuickActionCategory>>([]);
    final banners = useState<List<BannerModel>>([]);
    final bannerError = useState<String?>(null);
    final bannerPage = useState(0);
    final requestId = useRef(0);
    final bannerController =
        useMemoized(() => PageController(viewportFraction: 1), const []);

    // Listen to controller text changes directly to guarantee query state sync.
    useEffect(() {
      void onTextChanged() {
        if (query.value != searchController.text) {
          query.value = searchController.text;
        }
      }

      searchController.addListener(onTextChanged);
      return () => searchController.removeListener(onTextChanged);
    }, [searchController]);

    // Fetch banners independently.
    useEffect(() {
      Future<void> fetchBanners() async {
        bannerError.value = null;
        try {
          banners.value = await ref
              .read(homeRepositoryProvider)
              .fetchExploreAllServicesBanners(lang: 'en');
        } catch (_) {
          bannerError.value = 'Failed to load banner.';
        }
      }

      Future.microtask(fetchBanners);
      return null;
    }, const []);

    // Auto-scroll banner carousel if multiple banners exist.
    useEffect(() {
      if (banners.value.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!bannerController.hasClients) return;
        final next = (bannerPage.value + 1) % banners.value.length;
        bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [banners.value.length]);

    // Fetch ALL services once at mount — no search param sent to backend.
    useEffect(() {
      void fetch() async {
        isLoading.value = true;
        error.value = null;
        final id = ++requestId.value;
        try {
          final data =
              await ref.read(homeRepositoryProvider).fetchQuickActions();
          if (id != requestId.value) return;
          // Permanently hidden containers per Figma (hidden at the data
          // source so they appear in no state, search included):
          //   - "Pay Bills & Expenses"
          //   - "Banking & Investments"
          // "Other Services" is NOT hidden anymore — it renders as the
          // static _OtherServicesCategorySection at the bottom, so the API
          // category is only suppressed at render time (see
          // replacedByStaticSections) and stays searchable.
          final hiddenCategories = <String>[
            'pay bills',
            // Banking & Investments container is commented out per Figma;
            // this entry keeps it hidden until Figma re-enables it.
            'banking',
          ];

          // Figma: the "Other Services" container keeps only these cards;
          // every other item of the API category is commented out (hidden
          // in browse and search). Substring match, lower-case.
          const otherServicesKeep = <String>[
            'subscription',
            'pipe', // covers "Pipe Gas" and "Piped Gas"
            'water',
            'metro', // covers "Metro Recharge"
            'prepaid meter',
          ];
          allResults.value = data.categories.where((c) {
            final name = c.category.trim().toLowerCase();
            return !hiddenCategories.any(name.contains);
          }).map((c) {
            if (!c.category.trim().toLowerCase().contains('other services')) {
              return c;
            }
            return QuickActionCategory(
              category: c.category,
              services: c.services.where((s) {
                final n = s.name.trim().toLowerCase();
                return otherServicesKeep.any(n.contains);
              }).toList(),
            );
          }).toList();
          hasFetched.value = true;
        } catch (_) {
          if (id != requestId.value) return;
          error.value = 'Failed to fetch services. Please try again.';
          hasFetched.value = true;
        } finally {
          if (id == requestId.value) isLoading.value = false;
        }
      }

      Future.microtask(fetch);
      return null;
    }, const []);

    // Instant local filtering without stale closures or race conditions.
    final filteredCategories = useMemoized(() {
      final q = query.value.trim().toLowerCase();
      if (q.isEmpty) {
        return allResults.value;
      }
      return allResults.value
          .map((cat) {
            final catMatches = cat.category.toLowerCase().contains(q);
            final matchedServices = cat.services.where((s) {
              final name = s.name.toLowerCase();
              final type = (s.type ?? '').toLowerCase();
              return name.contains(q) || type.contains(q);
            }).toList();
            return QuickActionCategory(
              category: cat.category,
              services: catMatches ? cat.services : matchedServices,
            );
          })
          .where((cat) => cat.services.isNotEmpty)
          .toList();
    }, [query.value, allResults.value]);

    void handleServiceTap(String serviceName) {
      final normalized = serviceName.trim().toLowerCase();
      if (normalized == 'credit card') {
        context.push(RouteConstants.creditCardMyCards);
      } else if (normalized == 'mobile prepaid') {
        context.push(RouteConstants.mobilePrepaid);
      } else if (normalized == 'digital gold') {
        context.push(
          '${RouteConstants.digitalGold}?entry=home',
        );
      } else if (normalized == 'digital silver') {
        context.push(
          '${RouteConstants.digitalGold}?metal=silver&entry=home',
        );
      } else if (normalized == 'tuition fees' ||
          normalized == 'tution fees' ||
          normalized == 'school fees' ||
          normalized == 'college fees' ||
          normalized == 'education fees' ||
          normalized.contains('house rent') ||
          normalized.contains('shop rent')) {
        context.push(
          RouteConstants.educationFeesAmount,
          extra: serviceName,
        );
      } else if (normalized.contains('fastag')) {
        context.push(
          RouteConstants.billerListing,
          extra: 'Fastag',
        );
      } else if (normalized == 'electricity bill') {
        context.push(
          RouteConstants.billerListing,
          extra: 'Electricity',
        );
      } else {
        context.push(
          RouteConstants.billerListing,
          extra: serviceName,
        );
      }
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalSidePadding = (screenWidth < 360 ? 16.0 : 19.6).w;
    final isSearching = query.value.trim().isNotEmpty;

    // API categories replaced by the hardcoded Figma containers above.
    // In browse mode they must NOT render again (no duplicates); in search
    // mode they stay searchable so static-only services remain findable.
    const replacedByStaticSections = <String>[
      'recharge',
      'utilit', // covers "Utility Bills" and "Utilities"
      'financial',
      'education',
      'lifestyle',
      'insurance',
      'rent',
      'other services', // rendered as the static section at the bottom
    ];
    final apiCategories = isSearching
        ? filteredCategories
        : filteredCategories
            .where((cat) => !replacedByStaticSections
                .any(cat.category.trim().toLowerCase().contains))
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            MyAppBar(
              title: 'All Services',
              showHelp: true,
              onBack: () => Navigator.of(context).pop(),
              titleStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalSidePadding,
                vertical: 6.h,
              ),
              child: AppSearchBar(
                hintText: 'Search Services',
                controller: searchController,
                onChanged: (value) {
                  query.value = value;
                },
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                  color: Colors.black,
                ),
              ),
            ),
            if (!isSearching) ...[
              SizedBox(height: 8.h),
              _RechargeHighlightSection(
                onServiceTap: handleServiceTap,
              ),
              SizedBox(height: 14.h),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalSidePadding),
                child: _RechargeCategorySection(
                  onServiceTap: handleServiceTap,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalSidePadding),
                child: _UtilityBillsCategorySection(
                  onServiceTap: handleServiceTap,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalSidePadding),
                child: _FinancialCategorySection(
                  onServiceTap: handleServiceTap,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalSidePadding),
                child: _EducationCategorySection(
                  onServiceTap: handleServiceTap,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalSidePadding),
                child: _InsuranceCategorySection(
                  onServiceTap: handleServiceTap,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalSidePadding),
                child: _RentPropertyCategorySection(
                  onServiceTap: handleServiceTap,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalSidePadding),
                child: _OtherServicesCategorySection(
                  onServiceTap: handleServiceTap,
                ),
              ),
            ] else ...[
              SizedBox(height: 8.h),
            ],
            if (isLoading.value)
              const _HomeSearchLoadingSkeleton()
            else if (error.value != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Text(
                  error.value!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: Colors.red.shade700,
                  ),
                ),
              )
            else if (isSearching && hasFetched.value && apiCategories.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Center(
                  child: Text(
                    'No services found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else if (apiCategories.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalSidePadding,
                    4.h,
                    horizontalSidePadding,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      for (final category in apiCategories)
                        _CategorySection(
                          category: category,
                          onServiceTap: handleServiceTap,
                        ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _RechargeHighlightSection extends StatelessWidget {
  const _RechargeHighlightSection({required this.onServiceTap});

  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPad = (screenWidth < 360 ? 10.0 : 16.0).w;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: 16.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x4DFFB49D), // rgba(255, 180, 157, 0.3)
            Color(0x4DDD5428), // rgba(221, 84, 40, 0.3)
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Text(
              'Recharge',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.02 * 14.sp,
                color: const Color(0xFF000000),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HomeIconTile(
                  label: 'Mobile Prepaid',
                  svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
                  onTap: () => onServiceTap('Mobile Prepaid'),
                ),
              ),
              Expanded(
                child: HomeIconTile(
                  label: 'Mobile Postpaid',
                  svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
                  onTap: () => onServiceTap('Mobile Postpaid'),
                ),
              ),
              Expanded(
                child: HomeIconTile(
                  label: 'FASTag Recharge',
                  svgAsset: 'assets/images/svg/services/fastag_recharge.svg',
                  onTap: () => onServiceTap('FASTag Recharge'),
                ),
              ),
              Expanded(
                child: HomeIconTile(
                  label: 'EV Recharge',
                  svgAsset: 'assets/images/svg/services/ev_recharge.svg',
                  onTap: () => onServiceTap('EV Recharge'),
                ),
              ),
              Expanded(
                child: HomeIconTile(
                  label: 'Fleet Card Recharge',
                  svgAsset:
                      'assets/images/svg/services/fleet_card_recharge.svg',
                  onTap: () => onServiceTap('Fleet Card Recharge'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RechargeCategorySection extends StatelessWidget {
  const _RechargeCategorySection({required this.onServiceTap});

  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    return _StaticCategorySection(
      title: 'Recharge',
      showArrow: true,
      tiles: [
        HomeIconTile(
          label: 'Mobile Prepaid',
          svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
          onTap: () => onServiceTap('Mobile Prepaid'),
        ),
        HomeIconTile(
          label: 'Mobile Postpaid',
          svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
          onTap: () => onServiceTap('Mobile Postpaid'),
        ),
        HomeIconTile(
          label: 'FASTag Recharge',
          svgAsset: 'assets/images/svg/services/fastag_recharge.svg',
          onTap: () => onServiceTap('FASTag Recharge'),
        ),
        HomeIconTile(
          label: 'EV Recharge',
          svgAsset: 'assets/images/svg/services/ev_recharge.svg',
          onTap: () => onServiceTap('EV Recharge'),
        ),
        HomeIconTile(
          label: 'Fleet Card Recharge',
          svgAsset: 'assets/images/svg/services/fleet_card_recharge.svg',
          onTap: () => onServiceTap('Fleet Card Recharge'),
        ),
        HomeIconTile(
          label: 'NCMC Recharge',
          svgAsset: 'assets/images/svg/services/ncmc_recharge.svg',
          onTap: () => onServiceTap('NCMC Recharge'),
        ),
      ],
    );
  }
}

/// A white-card category section with a fixed, hardcoded list of service
/// tiles (icon + label), matching the API-driven [_CategorySection] styling:
/// 4-column wrap, Home-sized [HomeIconTile] circles and text.
class _StaticCategorySection extends HookWidget {
  const _StaticCategorySection({
    required this.title,
    required this.tiles,
    this.showArrow = true,
  });

  final String title;
  final List<Widget> tiles;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    const int columns = 4;
    final expanded = useState(true);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: showArrow ? () => expanded.value = !expanded.value : null,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        letterSpacing: -0.02 * 14.sp,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                  if (showArrow)
                    AnimatedRotation(
                      turns: expanded.value ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: CommonServiceSvgIcon(
                        assetPath: 'assets/images/svg/services/down_arrow.svg',
                        width: 14.w,
                        height: 8.w,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded.value
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 20.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFEBEBEB),
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x0A000000),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double maxWidth = constraints.maxWidth;
                            final double spacing = (maxWidth < 300 ? 8 : 12).w;
                            final double itemWidth =
                                (maxWidth - (spacing * (columns - 1))) /
                                    columns;
                            return Wrap(
                              spacing: spacing,
                              runSpacing: 18.h,
                              children: [
                                for (final tile in tiles)
                                  SizedBox(width: itemWidth, child: tile),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Utility Bills — hardcoded category shown below the Recharge sections.
class _UtilityBillsCategorySection extends StatelessWidget {
  const _UtilityBillsCategorySection({required this.onServiceTap});

  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    return _StaticCategorySection(
      title: 'Utility Bills',
      tiles: [
        HomeIconTile(
          label: 'Electricity Bill',
          svgAsset: 'assets/images/svg/services/electricity_bill.svg',
          onTap: () => onServiceTap('Electricity Bill'),
        ),
        HomeIconTile(
          label: 'Book LPG',
          iconUrl: FileConstants.gasCylinder,
          onTap: () => onServiceTap('Book LPG'),
        ),
        HomeIconTile(
          label: 'Pipe Gas',
          svgAsset: 'assets/images/svg/services/pipe_gas.svg',
          onTap: () => onServiceTap('Pipe Gas'),
        ),
        HomeIconTile(
          label: 'Prepaid Meter',
          svgAsset: 'assets/images/svg/services/prepaid_meter.svg',
          onTap: () => onServiceTap('Prepaid Meter'),
        ),
        HomeIconTile(
          label: 'Cable TV',
          svgAsset: 'assets/images/svg/services/cable_tv.svg',
          onTap: () => onServiceTap('Cable TV'),
        ),
        HomeIconTile(
          label: 'DTH',
          svgAsset: 'assets/images/svg/services/dth.svg',
          onTap: () => onServiceTap('DTH'),
        ),
        HomeIconTile(
          label: 'Broadband',
          svgAsset: 'assets/images/svg/services/broadband.svg',
          onTap: () => onServiceTap('Broadband'),
        ),
        HomeIconTile(
          label: 'Landline',
          svgAsset: 'assets/images/svg/services/landline.svg',
          onTap: () => onServiceTap('Landline'),
        ),
        HomeIconTile(
          label: 'Housing Society',
          svgAsset: 'assets/images/svg/services/housing_society.svg',
          onTap: () => onServiceTap('Housing Society'),
        ),
        HomeIconTile(
          label: 'Municipal Services',
          svgAsset: 'assets/images/svg/services/municipal_services.svg',
          onTap: () => onServiceTap('Municipal Services'),
        ),
      ],
    );
  }
}

/// Financial — hardcoded category with the collapse arrow, matching Figma.
class _FinancialCategorySection extends StatelessWidget {
  const _FinancialCategorySection({required this.onServiceTap});

  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    return _StaticCategorySection(
      title: 'Financial',
      showArrow: true,
      tiles: [
        HomeIconTile(
          label: 'Credit Card Bill',
          // Figma: same icon as the NCMC Recharge card.
          svgAsset: 'assets/images/svg/services/ncmc_recharge.svg',
          onTap: () => onServiceTap('Credit Card Bill'),
        ),
        HomeIconTile(
          label: 'Digital Gold',
          // Figma: Digital Gold reuses the electricity bulb icon.
          svgAsset: 'assets/images/svg/services/electricity_bill.svg',
          onTap: () => onServiceTap('Digital Gold'),
        ),
        HomeIconTile(
          label: 'Digital Silver',
          // Figma: Digital Silver reuses the book-gas icon.
          svgAsset: 'assets/images/svg/services/pipe_gas.svg',
          onTap: () => onServiceTap('Digital Silver'),
        ),
        HomeIconTile(
          label: 'Loan Repayment',
          svgAsset: 'assets/images/svg/services/loan_repayment.svg',
          onTap: () => onServiceTap('Loan Repayment'),
        ),
        HomeIconTile(
          label: 'Municipal Taxes',
          svgAsset: 'assets/images/svg/services/municipal_taxes.svg',
          onTap: () => onServiceTap('Municipal Taxes'),
        ),
        HomeIconTile(
          label: 'eChallan',
          // Figma: same icon as the NCMC Recharge card.
          svgAsset: 'assets/images/svg/services/ncmc_recharge.svg',
          onTap: () => onServiceTap('Echallan'),
        ),
        HomeIconTile(
          label: 'NPS',
          svgAsset: 'assets/images/svg/services/nps.svg',
          onTap: () => onServiceTap('NPS'),
        ),
        HomeIconTile(
          label: 'Forex',
          svgAsset: 'assets/images/svg/services/forex.svg',
          onTap: () => onServiceTap('Forex'),
        ),
        HomeIconTile(
          label: 'Agent Collection',
          svgAsset: 'assets/images/svg/services/agent_collection.svg',
          onTap: () => onServiceTap('Agent Collection'),
        ),
        HomeIconTile(
          label: 'B2B Payments',
          svgAsset: 'assets/images/svg/services/b2b_payments.svg',
          onTap: () => onServiceTap('B2B Payments'),
        ),
      ],
    );
  }
}

/// Pay via credit card (Education) — replaces the old API
/// "Education and Lifestyle" container per Figma.
class _EducationCategorySection extends StatelessWidget {
  const _EducationCategorySection({required this.onServiceTap});

  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    return _StaticCategorySection(
      title: 'Pay via Credit Card (Education)',
      tiles: [
        HomeIconTile(
          label: 'School Fees',
          iconUrl: FileConstants.schoolFees,
          onTap: () => onServiceTap('School Fees'),
        ),
        HomeIconTile(
          label: 'Tution Fees',
          iconUrl: FileConstants.tutionFees,
          onTap: () => onServiceTap('Tution Fees'),
        ),
        HomeIconTile(
          label: 'College Fees',
          iconUrl: FileConstants.collegeFees,
          onTap: () => onServiceTap('College Fees'),
        ),
        HomeIconTile(
          // Replaces the old Gym Membership tile, with its own Figma icon.
          label: 'Education Fees',
          svgAsset: 'assets/images/svg/services/education_fees.svg',
          onTap: () => onServiceTap('Education Fees'),
        ),
      ],
    );
  }
}

/// Insurance — same card styling and size as the container above.
class _InsuranceCategorySection extends StatelessWidget {
  const _InsuranceCategorySection({required this.onServiceTap});

  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    return _StaticCategorySection(
      title: 'Insurance',
      tiles: [
        HomeIconTile(
          label: 'General Insurance',
          iconUrl: FileConstants.generalInsurance,
          onTap: () => onServiceTap('General Insurance'),
        ),
        HomeIconTile(
          label: 'Health Insurance',
          iconUrl: FileConstants.healthInsurance,
          onTap: () => onServiceTap('Health Insurance'),
        ),
        HomeIconTile(
          label: 'Life Insurance',
          iconUrl: FileConstants.lifeInsurance,
          onTap: () => onServiceTap('Life Insurance'),
        ),
      ],
    );
  }
}

/// Rent & Property — House Rent / Shop Rent moved out of the old
/// education container, plus the new Rental tile from Figma.
class _RentPropertyCategorySection extends StatelessWidget {
  const _RentPropertyCategorySection({required this.onServiceTap});

  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    return _StaticCategorySection(
      title: 'Rent & Property',
      tiles: [
        HomeIconTile(
          label: 'House Rent',
          iconUrl: FileConstants.houseRent,
          onTap: () => onServiceTap('House Rent'),
        ),
        HomeIconTile(
          label: 'Shop Rent',
          iconUrl: FileConstants.shopRent,
          onTap: () => onServiceTap('Shop Rent'),
        ),
        HomeIconTile(
          label: 'Rental',
          svgAsset: 'assets/images/svg/services/rental.svg',
          onTap: () => onServiceTap('Rental'),
        ),
      ],
    );
  }
}

/// Other Services — re-enabled per Figma as the LAST container with only
/// the approved cards (Subscription, Pipe Gas, Water, Metro Recharge,
/// Prepaid Meter). All other items from the old API category stay
/// commented out (see otherServicesKeep in the fetch effect).
class _OtherServicesCategorySection extends StatelessWidget {
  const _OtherServicesCategorySection({required this.onServiceTap});

  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    return _StaticCategorySection(
      title: 'Other Services',
      tiles: [
        HomeIconTile(
          label: 'Subscription',
          iconUrl: FileConstants.subscriptions,
          onTap: () => onServiceTap('Subscription'),
        ),
        HomeIconTile(
          label: 'Pipe Gas',
          svgAsset: 'assets/images/svg/services/pipe_gas.svg',
          onTap: () => onServiceTap('Pipe Gas'),
        ),
        HomeIconTile(
          label: 'Water',
          iconUrl: FileConstants.water,
          onTap: () => onServiceTap('Water'),
        ),
        HomeIconTile(
          label: 'Metro Recharge',
          iconUrl: FileConstants.metro,
          onTap: () => onServiceTap('Metro Recharge'),
        ),
        HomeIconTile(
          label: 'Prepaid Meter',
          svgAsset: 'assets/images/svg/services/prepaid_meter.svg',
          onTap: () => onServiceTap('Prepaid Meter'),
        ),
      ],
    );
  }
}

class _HomeSearchLoadingSkeleton extends StatelessWidget {
  const _HomeSearchLoadingSkeleton();

  static const _mockCategories = [
    QuickActionCategory(
      category: 'Popular Services',
      services: [
        QuickActionService(name: 'Electricity'),
        QuickActionService(name: 'Credit Card'),
        QuickActionService(name: 'DTH'),
        QuickActionService(name: 'Fastag'),
        QuickActionService(name: 'Broadband'),
        QuickActionService(name: 'Piped Gas'),
        QuickActionService(name: 'Water'),
        QuickActionService(name: 'Insurance'),
      ],
    ),
    QuickActionCategory(
      category: 'Recharge & Bills',
      services: [
        QuickActionService(name: 'Mobile Prepaid'),
        QuickActionService(name: 'Mobile Postpaid'),
        QuickActionService(name: 'Landline'),
        QuickActionService(name: 'Cable TV'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          child: Column(
            children: _mockCategories
                .map(
                  (category) => Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: _CategorySection(
                      category: category,
                      onServiceTap: (_) {},
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends HookWidget {
  const _CategorySection({
    required this.category,
    required this.onServiceTap,
  });

  final QuickActionCategory category;
  final void Function(String serviceName) onServiceTap;

  @override
  Widget build(BuildContext context) {
    const int columns = 4;
    const int initialRows = 2;
    const maxCollapsedItems = columns * initialRows;
    final canExpand = category.services.length > maxCollapsedItems;
    final expanded = useState(false);

    useEffect(() {
      expanded.value = !canExpand;
      return null;
    }, [category.category, category.services.length]);

    final visibleServices = canExpand && !expanded.value
        ? category.services.take(maxCollapsedItems).toList()
        : category.services;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: canExpand ? () => expanded.value = !expanded.value : null,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.category,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        letterSpacing: -0.02 * 14.sp,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                  if (canExpand)
                    Icon(
                      expanded.value
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 24.r,
                      color: const Color(0xFF000000),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFEBEBEB), width: 1.w),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0A000000),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxWidth = constraints.maxWidth;
                  final double spacing = (maxWidth < 300 ? 8 : 12).w;
                  final double itemWidth =
                      (maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: 18.h,
                    children: List.generate(visibleServices.length, (index) {
                      final service = visibleServices[index];
                      return SizedBox(
                        width: itemWidth,
                        child: _buildServiceTile(service, onServiceTap),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(
    QuickActionService service,
    void Function(String) onServiceTap,
  ) {
    final name = service.name.trim();
    final lower = name.toLowerCase();
    final isEv = lower.contains('ev recharge');
    final isFleet = lower.contains('fleet card');
    final isElectricity = lower.contains('electricity');
    final isEChallan = lower.contains('challan');
    final isNcmc = lower.contains('ncmc');
    // Figma: the Gym Membership tile is replaced by Education Fees here.
    final label =
        lower.contains('gym') ? 'Education Fees' : displayServiceName(name);

    String? svgAsset;
    String? iconUrl = service.icon;

    if (isEv) {
      svgAsset = 'assets/images/svg/services/ev_recharge.svg';
    } else if (isFleet) {
      svgAsset = 'assets/images/svg/services/fleet_card_recharge.svg';
    } else if (isNcmc) {
      svgAsset = 'assets/images/svg/services/ncmc_recharge.svg';
    } else if (isElectricity) {
      if (iconUrl == null || iconUrl.isEmpty) {
        svgAsset = 'assets/images/svg/services/electricity_bill.svg';
      }
    } else if (isEChallan) {
      // Figma: same icon as the NCMC Recharge card.
      svgAsset = 'assets/images/svg/services/ncmc_recharge.svg';
    } else if (iconUrl == null || iconUrl.isEmpty) {
      if (lower.contains('prepaid') && lower.contains('mobile')) {
        svgAsset = 'assets/images/svg/services/mobile_recharge.svg';
      } else if (lower.contains('postpaid') && lower.contains('mobile')) {
        svgAsset = 'assets/images/svg/services/mobile_recharge.svg';
      } else if (lower.contains('fastag')) {
        svgAsset = 'assets/images/svg/services/fastag_recharge.svg';
      } else if (lower.contains('gym') || lower.contains('education fees')) {
        svgAsset = 'assets/images/svg/services/education_fees.svg';
      } else if (lower.contains('rental')) {
        svgAsset = 'assets/images/svg/services/rental.svg';
      } else if (lower.contains('credit card')) {
        svgAsset = 'assets/images/svg/services/ncmc_recharge.svg';
      } else if (lower.contains('gold')) {
        // Figma: Digital Gold reuses the electricity bulb icon.
        svgAsset = 'assets/images/svg/services/electricity_bill.svg';
      } else if (lower.contains('silver')) {
        // Figma: Digital Silver reuses the book-gas icon.
        svgAsset = 'assets/images/svg/services/pipe_gas.svg';
      } else if (lower.contains('pipe gas') || lower.contains('piped gas')) {
        svgAsset = 'assets/images/svg/services/pipe_gas.svg';
      } else if (lower.contains('book') &&
          (lower.contains('gas') || lower.contains('lpg'))) {
        iconUrl = FileConstants.gasCylinder;
      } else if (lower.contains('prepaid meter')) {
        svgAsset = 'assets/images/svg/services/prepaid_meter.svg';
      } else if (lower.contains('cable')) {
        svgAsset = 'assets/images/svg/services/cable_tv.svg';
      } else if (lower.contains('dth')) {
        svgAsset = 'assets/images/svg/services/dth.svg';
      } else if (lower.contains('broadband')) {
        svgAsset = 'assets/images/svg/services/broadband.svg';
      } else if (lower.contains('landline')) {
        svgAsset = 'assets/images/svg/services/landline.svg';
      } else if (lower.contains('housing')) {
        svgAsset = 'assets/images/svg/services/housing_society.svg';
      } else if (lower.contains('municipal tax')) {
        svgAsset = 'assets/images/svg/services/municipal_taxes.svg';
      } else if (lower.contains('municipal')) {
        svgAsset = 'assets/images/svg/services/municipal_services.svg';
      } else if (lower.contains('loan') || lower.contains('repayment')) {
        svgAsset = 'assets/images/svg/services/loan_repayment.svg';
      } else if (lower.contains('nps') || lower.contains('pension')) {
        svgAsset = 'assets/images/svg/services/nps.svg';
      } else if (lower.contains('forex')) {
        svgAsset = 'assets/images/svg/services/forex.svg';
      } else if (lower.contains('b2b')) {
        svgAsset = 'assets/images/svg/services/b2b_payments.svg';
      } else if (lower.contains('agent')) {
        svgAsset = 'assets/images/svg/services/agent_collection.svg';
      } else if (lower.contains('school')) {
        iconUrl = FileConstants.schoolFees;
      } else if (lower.contains('college')) {
        iconUrl = FileConstants.collegeFees;
      } else if (lower.contains('tution') || lower.contains('tuition')) {
        iconUrl = FileConstants.tutionFees;
      } else if (lower.contains('house rent')) {
        iconUrl = FileConstants.houseRent;
      } else if (lower.contains('shop rent')) {
        iconUrl = FileConstants.shopRent;
      } else if (lower.contains('life')) {
        iconUrl = FileConstants.lifeInsurance;
      } else if (lower.contains('health')) {
        iconUrl = FileConstants.healthInsurance;
      } else if (lower.contains('general') || lower.contains('insurance')) {
        iconUrl = FileConstants.generalInsurance;
      }
    }

    return HomeIconTile(
      label: label,
      iconUrl: iconUrl,
      svgAsset: svgAsset,
      offer: service.offers,
      onTap: () => onServiceTap(service.name),
    );
  }
}
