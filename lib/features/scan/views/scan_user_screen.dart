//  ignore_for_file: deprecated_member_use
// 
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// 
// import '../../../constants/app_colors.dart';
// import '../../../constants/file_constants.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// 
// import '../components/scan_frame.dart';
// import '../helpers/scan_helper.dart';
// import '../../home/controllers/home_tab_controller.dart';
// 
// class ScanUserScreen extends ConsumerStatefulWidget {
//   const ScanUserScreen({super.key});
// 
//   @override
//   ConsumerState<ScanUserScreen> createState() => _ScanUserScreenState();
// }
// 
// class _ScanUserScreenState extends ConsumerState<ScanUserScreen> {
//   // late final ScanHelper _scanHelper;
//   final GlobalKey _qrKey = GlobalKey(debugLabel: 'qr');
//   bool _scannerFailed = false;
// 
//   @override
//   void initState() {
//     super.initState();
//     // _scanHelper = ScanHelper();
//   }
// 
//   @override
//   void dispose() {
//     // _scanHelper.dispose();
//     super.dispose();
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     if (_scannerFailed) {
//       return const _ScanFallbackView();
//     }
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: QRView(
//               key: _qrKey,
//               onQRViewCreated: (controller) {
//                 _scanHelper.attachController(controller);
//                 _scanHelper.startScan();
//               },
//               onPermissionSet: (_, granted) {
//                 if (!granted && mounted) {
//                   setState(() => _scannerFailed = true);
//                 }
//               },
//               overlay: QrScannerOverlayShape(
//                 borderColor: AppColors.primary,
//                 borderRadius: 22.r,
//                 borderLength: 26.w,
//                 borderWidth: 3.w,
//                 cutOutSize: 250.w,
//                 overlayColor: Colors.black.withOpacity(0.65),
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Column(
//               children: [
//                 Padding(
//                   padding: EdgeInsets.fromLTRB(8.w, 10.h, 12.w, 6.h),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         onPressed: () {
//                           if (context.canPop()) {
//                             context.pop();
//                             return;
//                           }
//                           ref.read(homeTabControllerProvider).index = 0;
//                         },
//                         icon: Icon(Icons.arrow_back,
//                             color: Colors.white, size: 22.sp),
//                       ),
//                       SizedBox(width: 4.w),
//                       Text(
//                         'Cancel',
//                         style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                             ),
//                       ),
//                       const Spacer(),
//                       ValueListenableBuilder<bool>(
//                         valueListenable: _scanHelper.torchEnabled,
//                         builder: (_, enabled, __) {
//                           return IconButton(
//                             onPressed: _scanHelper.toggleTorch,
//                             icon: Icon(
//                               enabled
//                                   ? Icons.flashlight_on
//                                   : Icons.flashlight_off,
//                               color: Colors.white,
//                               size: 20.sp,
//                             ),
//                           );
//                         },
//                       ),
//                       IconButton(
//                         onPressed: _scanHelper.scanFromGallery,
//                         icon: Icon(Icons.image, color: Colors.white, size: 20.sp),
//                       ),
//                       IconButton(
//                         onPressed: () {},
//                         icon: Icon(Icons.more_vert,
//                             color: Colors.white, size: 20.sp),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 16.h),
//                 Expanded(
//                   child: Column(
//                     children: [
//                       SizedBox(height: 8.h),
//                       IgnorePointer(child: ScanFrame(size: 270.w)),
//                       SizedBox(height: 14.h),
//                       ValueListenableBuilder<String>(
//                         valueListenable: _scanHelper.lastResult,
//                         builder: (_, value, __) {
//                           final label = value.isEmpty
//                               ? 'ERUPAIYA1234567890'
//                               : value;
//                           return Text(
//                             label,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .bodySmall
//                                 ?.copyWith(
//                                   color: Colors.white.withOpacity(0.7),
//                                   letterSpacing: 0.6,
//                                 ),
//                           );
//                         },
//                       ),
//                       SizedBox(height: 18.h),
//                       Text(
//                         'Show This QR Code To Receive\nE-Coins In Your Wallet.',
//                         textAlign: TextAlign.center,
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                               color: Colors.white.withOpacity(0.7),
//                               height: 1.4,
//                             ),
//                       ),
//                       SizedBox(height: 20.h),
//                       Container(
//                         padding:
//                             EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.08),
//                           borderRadius: BorderRadius.circular(20.r),
//                         ),
//                         child: Text(
//                           'Scan A QR Code To Send E-Coins',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodySmall
//                               ?.copyWith(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                         ),
//                       ),
//                       const Spacer(),
//                       Padding(
//                         padding: EdgeInsets.only(bottom: 18.h),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Image.asset(
//                               FileConstants.appLogo,
//                               height: 22.h,
//                               fit: BoxFit.contain,
//                             ),
//                             SizedBox(width: 10.w),
//                             Container(
//                               width: 1,
//                               height: 18.h,
//                               color: Colors.white24,
//                             ),
//                             SizedBox(width: 10.w),
//                             Image.asset(
//                               FileConstants.bharatConnect,
//                               height: 22.h,
//                               fit: BoxFit.contain,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// 
// class _ScanFallbackView extends StatelessWidget {
//   const _ScanFallbackView();
// 
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 24.w),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.qr_code_2, size: 72.sp, color: AppColors.primary),
//                 SizedBox(height: 12.h),
//                 Text(
//                   'Scanner Unavailable',
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         color: AppColors.textPrimary,
//                         fontWeight: FontWeight.w700,
//                       ),
//                 ),
//                 SizedBox(height: 6.h),
//                 Text(
//                   'We couldn’t access the camera on this device. Please check permissions or try again.',
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: AppColors.textPrimary.withOpacity(0.7),
//                         height: 1.4,
//                       ),
//                 ),
//                 SizedBox(height: 16.h),
//                 ElevatedButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('Go Back'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
