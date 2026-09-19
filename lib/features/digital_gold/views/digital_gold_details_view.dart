import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/routes_constant.dart';
import '../../../utils/error_message_utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/my_app_bar.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/gold_confirm_details_card.dart';
import '../components/gold_details_section_title.dart';
import '../components/gold_form_field.dart';
import '../models/digital_gold_preview.dart';
import '../models/digital_metal.dart';
import '../repo/digital_gold_repo.dart';

class DigitalGoldDetailsView extends HookConsumerWidget {
  const DigitalGoldDetailsView({
    super.key,
    required this.amount,
    this.metal = DigitalMetal.gold,
    this.preview,
    this.redirectToGoldOnSuccess = false,
  });

  final int amount;
  final DigitalMetal metal;
  final DigitalGoldPreview? preview;
  final bool redirectToGoldOnSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final nameController =
        useTextEditingController(text: profileState.profile?.name ?? '');
    final mobileController =
        useTextEditingController(text: profileState.profile?.mobile ?? '');
    final emailController =
        useTextEditingController(text: profileState.profile?.email ?? '');
    final panController =
        useTextEditingController(text: profileState.profile?.panNo ?? '');
    useListenable(nameController);
    useListenable(mobileController);
    useListenable(emailController);
    useListenable(panController);

    final billingAddress1 = useTextEditingController();
    final billingAddress2 = useTextEditingController();
    final billingCity = useTextEditingController();
    final billingState = useTextEditingController();
    final billingStateCode = useTextEditingController();
    final billingZip = useTextEditingController();
    final billingCountry = useTextEditingController();
    final billingMobile = useTextEditingController();

    final deliveryAddress1 = useTextEditingController();
    final deliveryAddress2 = useTextEditingController();
    final deliveryCity = useTextEditingController();
    final deliveryState = useTextEditingController();
    final deliveryStateCode = useTextEditingController();
    final deliveryZip = useTextEditingController();
    final deliveryCountry = useTextEditingController();
    final deliveryMobile = useTextEditingController();

    final sameAsBilling = useState<bool>(true);

    void copyBillingToDelivery() {
      deliveryAddress1.text = billingAddress1.text;
      deliveryAddress2.text = billingAddress2.text;
      deliveryCity.text = billingCity.text;
      deliveryState.text = billingState.text;
      deliveryStateCode.text = billingStateCode.text;
      deliveryZip.text = billingZip.text;
      deliveryCountry.text = billingCountry.text;
      deliveryMobile.text = billingMobile.text;
    }

    useEffect(() {
      final profile = profileState.profile;
      if (profile == null) return null;
      nameController.text = profile.name;
      mobileController.text = profile.mobile;
      emailController.text = profile.email ?? '';
      panController.text = profile.panNo ?? '';

      final billing = profile.billingAddress;
      if (billing != null) {
        billingAddress1.text = billing.addressLine1;
        billingAddress2.text = billing.addressLine2;
        billingCity.text = billing.city;
        billingState.text = billing.state;
        billingStateCode.text = billing.stateCode;
        billingZip.text = billing.pincode;
        billingCountry.text = billing.country;
        billingMobile.text = billing.billingMobile.isNotEmpty
            ? billing.billingMobile
            : profile.mobile;
        sameAsBilling.value = true;
        copyBillingToDelivery();
      } else {
        billingMobile.text = profile.mobile;
        deliveryMobile.text = profile.mobile;
        sameAsBilling.value = true;
      }
      return null;
    }, [profileState.profile]);

    useEffect(() {
      void syncIfNeeded() {
        if (!sameAsBilling.value) return;
        copyBillingToDelivery();
      }

      billingAddress1.addListener(syncIfNeeded);
      billingAddress2.addListener(syncIfNeeded);
      billingCity.addListener(syncIfNeeded);
      billingState.addListener(syncIfNeeded);
      billingStateCode.addListener(syncIfNeeded);
      billingZip.addListener(syncIfNeeded);
      billingCountry.addListener(syncIfNeeded);
      billingMobile.addListener(syncIfNeeded);
      return () {
        billingAddress1.removeListener(syncIfNeeded);
        billingAddress2.removeListener(syncIfNeeded);
        billingCity.removeListener(syncIfNeeded);
        billingState.removeListener(syncIfNeeded);
        billingStateCode.removeListener(syncIfNeeded);
        billingZip.removeListener(syncIfNeeded);
        billingCountry.removeListener(syncIfNeeded);
        billingMobile.removeListener(syncIfNeeded);
      };
    }, [
      sameAsBilling.value,
      billingAddress1,
      billingAddress2,
      billingCity,
      billingState,
      billingStateCode,
      billingZip,
      billingCountry,
      billingMobile,
    ]);

    final repository = ref.read(digitalGoldRepoProvider);
    final isSubmitting = useState<bool>(false);

    final theme = DigitalMetalTheme.of(metal);
    Future<bool> handleBack() async {
      if (context.canPop()) {
        context.pop();
        return false;
      }
      context.go('${RouteConstants.digitalGold}?metal=${theme.queryValue}');
      return false;
    }

    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          handleBack();
        },
        child: Scaffold(
          backgroundColor: theme.designTopTint,
          body: Column(
            children: [
              MyAppBar(
                title: '${theme.label} Buy And Sell',
                onBack: () {
                  handleBack();
                },
                showHelp: false,
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                ),
                backgroundColor: theme.designTopTint,
                height: 90.h,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoldDetailsSectionTitle(
                          title: 'Confirm Your Details',
                          trailingIcon: Icons.close,
                          onTrailingTap: () {},
                        ),
                        SizedBox(height: 8.h),
                        GoldConfirmDetailsCard(
                          name: nameController.text,
                          mobile: mobileController.text,
                          email: emailController.text,
                          pan: panController.text,
                        ),
                        SizedBox(height: 16.h),
                        const GoldDetailsSectionTitle(
                            title: 'Enter Other Details'),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Billing Address Line1',
                          controller: billingAddress1,
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Billing Address Line2',
                          controller: billingAddress2,
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Billing City',
                          controller: billingCity,
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Billing State',
                          controller: billingState,
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: GoldFormField(
                                label: 'Billing Statecode',
                                controller: billingStateCode,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: GoldFormField(
                                label: 'Billing Zip',
                                controller: billingZip,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Billing Country',
                          controller: billingCountry,
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Billing Mobile',
                          controller: billingMobile,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 16.h),
                        const GoldDetailsSectionTitle(
                            title: 'Delivery Address'),
                        SizedBox(height: 6.h),
                        InkWell(
                          onTap: () {
                            sameAsBilling.value = !sameAsBilling.value;
                            if (sameAsBilling.value) {
                              copyBillingToDelivery();
                            }
                          },
                          borderRadius: BorderRadius.circular(10.r),
                          child: Row(
                            children: [
                              Checkbox(
                                value: sameAsBilling.value,
                                onChanged: (v) {
                                  sameAsBilling.value = v ?? false;
                                  if (sameAsBilling.value) {
                                    copyBillingToDelivery();
                                  }
                                },
                              ),
                              Text(
                                'Same as Billing Address',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Delivery Address Line1',
                          controller: deliveryAddress1,
                          enabled: !sameAsBilling.value,
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Delivery Address Line2',
                          controller: deliveryAddress2,
                          enabled: !sameAsBilling.value,
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Delivery City',
                          controller: deliveryCity,
                          enabled: !sameAsBilling.value,
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Delivery State',
                          controller: deliveryState,
                          enabled: !sameAsBilling.value,
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: GoldFormField(
                                label: 'Delivery Statecode',
                                controller: deliveryStateCode,
                                keyboardType: TextInputType.number,
                                enabled: !sameAsBilling.value,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: GoldFormField(
                                label: 'Delivery Zip',
                                controller: deliveryZip,
                                keyboardType: TextInputType.number,
                                enabled: !sameAsBilling.value,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Delivery Country',
                          controller: deliveryCountry,
                          enabled: !sameAsBilling.value,
                        ),
                        SizedBox(height: 10.h),
                        GoldFormField(
                          label: 'Delivery Mobile',
                          controller: deliveryMobile,
                          keyboardType: TextInputType.phone,
                          enabled: !sameAsBilling.value,
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
                child: CustomElevatedButton(
                  onPressed: () async {
                    if (isSubmitting.value) return;
                    isSubmitting.value = true;
                    try {
                      await repository.createCustomer(
                        mobile: mobileController.text.trim(),
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        panNumber: panController.text.trim(),
                        billingAddressLine1: billingAddress1.text.trim(),
                        billingAddressLine2: billingAddress2.text.trim(),
                        billingCity: billingCity.text.trim(),
                        billingState: billingState.text.trim(),
                        billingStateCode: billingStateCode.text.trim(),
                        billingZip: billingZip.text.trim(),
                        billingCountry: billingCountry.text.trim(),
                        billingMobile: billingMobile.text.trim(),
                        deliveryAddressLine1: deliveryAddress1.text.trim(),
                        deliveryAddressLine2: deliveryAddress2.text.trim(),
                        deliveryCity: deliveryCity.text.trim(),
                        deliveryState: deliveryState.text.trim(),
                        deliveryStateCode: deliveryStateCode.text.trim(),
                        deliveryZip: deliveryZip.text.trim(),
                        deliveryCountry: deliveryCountry.text.trim(),
                        deliveryMobile: deliveryMobile.text.trim(),
                      );
                      if (!context.mounted) return;
                      if (redirectToGoldOnSuccess || amount <= 0) {
                        context.go(
                          '${RouteConstants.digitalGold}?metal=${theme.queryValue}',
                        );
                        return;
                      }

                      context.push(
                        '${RouteConstants.digitalGoldSummary}?metal=${theme.queryValue}',
                        extra: <String, dynamic>{
                          'amount': amount.toDouble(),
                          'preview': preview ??
                              const DigitalGoldPreview(
                                kycStatus: true,
                                isUserRegistered: true,
                                myGoldBalance: 0,
                                taxAmt1: 0,
                                taxAmt2: 0,
                                preTaxAmount: 0,
                                totalAmount: 0,
                              ),
                        },
                      );
                    } catch (e) {
                      AppSnackbar.show(
                        ErrorMessageUtils.from(
                          e,
                          fallback: 'Unable to continue. Please try again.',
                        ),
                        type: AppSnackbarType.error,
                      );
                    } finally {
                      isSubmitting.value = false;
                    }
                  },
                  label: 'Confirm Details',
                  uppercaseLabel: false,
                  height: 42.h,
                ),
              ),
            ),
          ),
        ));
  }
}
