// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/search_textfield.dart';
import '../components/home_icon_tile.dart';
import '../components/service_utils.dart';
import '../controllers/home_controller.dart';
import '../models/banner_model.dart';
import '../models/quick_action_model.dart';
import '../utils/banner_redirect_mapper.dart';

class HomeSearchView extends HookConsumerWidget {
  const HomeSearchView({super.key});

  static const double _bannerHeight = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final query = useState('');
    final isLoading = useState(false);
    final hasFetched = useState(false);
    final error = useState<String?>(null);
    final results = useState<List<QuickActionCategory>>([]);
    final banners = useState<List<BannerModel>>([]);
    final bannerError = useState<String?>(null);
    final bannerPage = useState(0);
    final requestId = useRef(0);
    final debounceRef = useRef<Timer?>(null);
    final bannerController =
        useMemoized(() => PageController(viewportFraction: 1), const []);

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

    useEffect(() {
      final currentRequestId = ++requestId.value;

      void fetch() async {
        isLoading.value = true;
        error.value = null;
        try {
          final data = await ref
              .read(homeRepositoryProvider)
              .fetchQuickActions(search: query.value.trim());
          if (currentRequestId != requestId.value) return;
          results.value = data.categories;
          hasFetched.value = true;
        } catch (_) {
          if (currentRequestId != requestId.value) return;
          error.value = 'Failed to fetch services. Please try again.';
          hasFetched.value = true;
        } finally {
          if (currentRequestId == requestId.value) {
            isLoading.value = false;
          }
        }
      }

      debounceRef.value?.cancel();
      debounceRef.value = Timer(const Duration(milliseconds: 300), fetch);

      return () {
        debounceRef.value?.cancel();
      };
    }, [query.value]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            MyAppBar(
              title: 'All Services',
              showHelp: false,
              onBack: () => Navigator.of(context).pop(),
              onHelp: () {},
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth < 392.w
                      ? constraints.maxWidth
                      : 392.w;
                  return Align(
                    alignment: Alignment.center,
                    child: SearchTextfield(
                      hintText: 'Search Services',
                      controller: searchController,
                      onChange: (value) {
                        query.value = value;
                      },
                      width: barWidth,
                      height: 54.h,
                      radius: 12.r,
                      fillColor: const Color(0xFFFFFFFF),
                      borderColor: const Color(0xFFD7D7D7),
                      borderWidth: 0.5,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x0F000000),
                          offset: Offset(0, 4.h),
                          blurRadius: 16.r,
                        ),
                      ],
                      contentPadding: EdgeInsets.only(right: 16.w),
                      prefixIconConstraints:
                          SearchBarLeadingIcon.constraints(fieldHeight: 54.h),
                      prefixIcon: SearchBarLeadingIcon(fieldHeight: 54.h),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (bannerError.value == null && banners.value.isNotEmpty)
              SizedBox(
                height: _bannerHeight,
                child: PageView.builder(
                  controller: bannerController,
                  padEnds: false,
                  onPageChanged: (page) => bannerPage.value = page,
                  itemCount: banners.value.length,
                  itemBuilder: (_, index) {
                    final banner = banners.value[index];
                    return GestureDetector(
                      onTap: () => BannerRedirectMapper.handle(
                        context,
                        banner.redirectUrl,
                      ),
                      child: AppNetworkImage(
                        url: banner.image,
                        width: double.infinity,
                        height: _bannerHeight,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            if (isLoading.value)
              const _HomeSearchLoadingSkeleton()
            else if (error.value != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(
                  error.value!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade700,
                      ),
                ),
              )
            else if (hasFetched.value && results.value.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(
                  'No services found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                ),
              )
            else if (results.value.isNotEmpty)
              SafeArea(
                top: false,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    12 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: results.value.length,
                  itemBuilder: (context, index) {
                    final category = results.value[index];
                    return _CategorySection(
                      category: category,
                      onServiceTap: (serviceName) {
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
                        } else {
                          context.push(
                            RouteConstants.billerListing,
                            extra: serviceName,
                          );
                        }
                      },
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: _mockCategories
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: canExpand ? () => expanded.value = !expanded.value : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  if (canExpand)
                    Icon(
                      expanded.value
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 26,
                      color: AppColors.textPrimary,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxWidth = constraints.maxWidth;
                  const double spacing = 12;
                  final double itemWidth =
                      (maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: 18,
                    children: List.generate(visibleServices.length, (index) {
                      final service = visibleServices[index];
                      return SizedBox(
                        width: itemWidth,
                        child: HomeIconTile(
                          label: displayServiceName(service.name),
                          iconUrl: service.icon,
                          onTap: () => onServiceTap(service.name),
                        ),
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
}
