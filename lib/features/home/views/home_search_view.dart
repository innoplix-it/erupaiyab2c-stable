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
          final data = await ref
              .read(homeRepositoryProvider)
              .fetchQuickActions();
          if (id != requestId.value) return;
          allResults.value = data.categories;
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
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalSidePadding,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: AspectRatio(
                    aspectRatio: 393 / 67,
                    child: Image.asset(
                      'assets/images/investmentallservices.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/png/investmentallservices.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _RechargeHighlightSection(
                onServiceTap: handleServiceTap,
              ),
              SizedBox(height: 14.h),
            ] else ...[
              SizedBox(height: 8.h),
            ],
            if (isLoading.value)
              const _HomeSearchLoadingSkeleton()
            else if (error.value != null)
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Text(
                  error.value!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: Colors.red.shade700,
                  ),
                ),
              )
            else if (hasFetched.value && filteredCategories.isEmpty)
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
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
            else if (filteredCategories.isNotEmpty)
              SafeArea(
                top: false,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalSidePadding,
                    4.h,
                    horizontalSidePadding,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    return _CategorySection(
                      category: category,
                      onServiceTap: handleServiceTap,
                    );
                  },
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
            padding: EdgeInsets.only(left: 4.w, right: 4.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                CommonServiceSvgIcon(
                  assetPath: 'assets/images/svg/services/down_arrow.svg',
                  width: 14.w,
                  height: 8.w,
                ),
              ],
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
                  iconUrl: FileConstants.fastTag,
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
                  svgAsset: 'assets/images/svg/services/fleet_card_recharge.svg',
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
        iconUrl = FileConstants.electricity;
      }
    } else if (isEChallan) {
      iconUrl = FileConstants.creditcard;
    } else if (iconUrl == null || iconUrl.isEmpty) {
      if (lower.contains('prepaid') && lower.contains('mobile')) {
        svgAsset = 'assets/images/svg/services/mobile_recharge.svg';
      } else if (lower.contains('postpaid') && lower.contains('mobile')) {
        svgAsset = 'assets/images/svg/services/mobile_recharge.svg';
      } else if (lower.contains('fastag')) {
        iconUrl = FileConstants.fastTag;
      } else if (lower.contains('credit card')) {
        iconUrl = FileConstants.creditcard;
      } else if (lower.contains('gold')) {
        svgAsset = 'assets/images/svg/services/digital_gold.svg';
      } else if (lower.contains('silver')) {
        svgAsset = 'assets/images/svg/services/digital_silver.svg';
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
      label: displayServiceName(service.name),
      iconUrl: iconUrl,
      svgAsset: svgAsset,
      offer: service.offers,
      onTap: () => onServiceTap(service.name),
    );
  }
}
