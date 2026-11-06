import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/widgets/app_network_image.dart';
import 'package:e_rupaiya/widgets/app_search_bar.dart';
import 'package:e_rupaiya/features/educationFees/components/education_contact_sheet.dart';
import 'package:e_rupaiya/features/educationFees/components/education_erupaiya_verifying_overlay.dart';
import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/views/education_search_recipient_view.dart';
import 'package:e_rupaiya/features/educationFees/views/education_tutor_request_view.dart';
import 'package:e_rupaiya/features/educationFees/views/education_tutor_unverified_view.dart';
import 'package:e_rupaiya/features/mobile_prepaid/controllers/contacts_cache_controller.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(home: child),
    ),
  );
}

/// Serves canned tutor-verify / tutor-details responses (or errors) and
/// records the calls, so the routing tests never touch the real Dio client.
class _FakeTutorVerifyRepository extends EducationFeesRepository {
  _FakeTutorVerifyRepository({
    this.response,
    this.error,
    this.detailsResponse,
    this.detailsError,
  });

  EducationTutorVerifyResponse? response;
  final Object? error;

  EducationTutorDetailsResponse? detailsResponse;
  final Object? detailsError;

  final verifyCalls = <String>[];
  final detailsMobiles = <String>[];
  final detailsAmounts = <int>[];

  @override
  Future<EducationTutorVerifyResponse> verifyTutor(String mobile) async {
    verifyCalls.add(mobile);
    if (error != null) throw error!;
    return response ??
        const EducationTutorVerifyResponse(
          status: false,
          verificationStatus: EducationTutorVerificationStatus.unknown,
        );
  }

  @override
  Future<EducationTutorDetailsResponse> fetchTutorDetails({
    required String mobile,
    required int amount,
  }) async {
    detailsMobiles.add(mobile);
    detailsAmounts.add(amount);
    if (detailsError != null) throw detailsError!;
    return detailsResponse ??
        const EducationTutorDetailsResponse(
          status: false,
          verificationStatus: EducationTutorVerificationStatus.unknown,
        );
  }

  @override
  Future<EducationBeneficiariesResponse> fetchBeneficiaries() async =>
      const EducationBeneficiariesResponse(status: true);
}

/// Seeds the device contact list so a contact tile can actually be tapped.
class _FakeContactsCacheController extends ContactsCacheController {
  _FakeContactsCacheController(List<Contact> contacts) {
    state = ContactsCacheState(
      contacts: contacts,
      searchIndex: [
        for (final contact in contacts)
          {
            'name': contact.displayName.toLowerCase(),
            'phone': contact.phones.isNotEmpty
                ? contact.phones.first.number.replaceAll(RegExp(r'\D'), '')
                : '',
          },
      ],
    );
  }

  @override
  Future<void> fetchIfNeeded() async {}

  @override
  Future<void> reload() async {}
}

Widget _wrapWithVerify(
  Widget child,
  EducationFeesRepository repository, {
  List<Contact>? contacts,
}) {
  return ProviderScope(
    overrides: [
      educationFeesRepositoryProvider.overrideWithValue(repository),
      if (contacts != null)
        contactsCacheControllerProvider.overrideWith(
          (ref) => _FakeContactsCacheController(contacts),
        ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(home: child),
    ),
  );
}

/// Types a 10-digit number that has no matching contact. The ABC field
/// auto-switches to 123 mode, whose Continue button runs the same pick path.
Future<void> _pickNumber(WidgetTester tester, String digits) async {
  await tester.enterText(find.byType(AppSearchBar), digits);
  await tester.pump();
  expect(find.text('Continue'), findsOneWidget);

  await tester.tap(find.text('Continue'));
  await tester.pump();
  expect(find.text('Verifying on eRupaiya'), findsOneWidget);

  // Overlay minimum display time (200 ms) plus the awaited API response.
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    // Grant contacts permission so the search bar (not the empty state)
    // renders in the widget test environment.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async {
        if (call.method == 'checkPermissionStatus') return 1; // granted
        return 0;
      },
    );
  });

  testWidgets('contact tap shows verifying overlay text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EducationSearchRecipientView(
          verificationDuration: Duration(milliseconds: 200),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Search Recipient'), findsNothing);
    expect(find.text('enter contact name or number'), findsOneWidget);
    expect(find.text('Contacts'), findsNothing);
    expect(find.text('Verifying on eRupaiya'), findsNothing);

    // The bar keeps the shared (credit card listing) defaults; only the
    // leading glyph is Education-specific.
    final bar = tester.widget<AppSearchBar>(find.byType(AppSearchBar));
    expect(bar.barHeight, isNull);
    expect(bar.barCornerRadius, isNull);
    expect(bar.prefixIcon, isNotNull);
  });

  testWidgets('verifying overlay completes and opens tutor request',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EducationErupaiyaVerifyingOverlay(
            duration: const Duration(milliseconds: 100),
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Verifying on eRupaiya'), findsOneWidget);
    expect(find.text('Do not close or go back.'), findsOneWidget);
    // Loader is all SVG: gradient circle + centred eRupaiya glyph + arc.
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsNWidgets(3));

    await tester.pump(const Duration(milliseconds: 120));
    expect(completed, isTrue);
  });

  testWidgets('PopScope allows pop before verification starts', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EducationSearchRecipientView(
          verificationDuration: Duration(seconds: 30),
        ),
      ),
    );
    await tester.pump();

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isTrue);
  });

  testWidgets('app bar has no verified/unverified flow selector',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EducationSearchRecipientView(
          verificationDuration: Duration(milliseconds: 200),
        ),
      ),
    );
    await tester.pump();

    // The manual app-bar pills are gone; the tutor-verify API outcome decides
    // which flow a contact pick runs.
    expect(find.text('Verified'), findsNothing);
    expect(find.text('Unverified'), findsNothing);
  });

  testWidgets('tutor request screen shows actions and no local banner',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EducationTutorRequestView(
          tutorName: 'Test Tutor Name',
          mobile: '9876500001',
          amount: 2000,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Test Tutor Name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.textContaining('Send Request'), findsOneWidget);
    expect(
      find.textContaining(
        'Please ask your tutor to accept the tuition fees request',
      ),
      findsOneWidget,
    );
    // Investment banner now comes from the backend; no local PNG rendered.
    expect(
      find.imageAsset(FileConstants.educationInvestmentBannerPng),
      findsNothing,
    );
  });

  group('contact pick routes on the tutor-verify API result', () {
    const verified = EducationTutorVerifyResponse(
      status: true,
      verificationStatus: EducationTutorVerificationStatus.verified,
      message: 'Mobile number verified successfully.',
    );
    const notFound = EducationTutorVerifyResponse(
      status: true,
      verificationStatus: EducationTutorVerificationStatus.notFound,
      message: 'This mobile number is not registered in eRupaiya.',
    );
    const tutorDetails = EducationTutorDetailsData(
      tutorId: 7,
      tutorName: 'Test Tutor Name',
      bankName: 'HDFC Bank',
      accountNumber: '50213456789012',
      accountHolderName: 'TEST TUTOR NAME',
      ifsc: 'HDFC0001234',
      bankLogo: 'https://cdn.example/hdfc.png',
      amount: 2500,
    );

    Future<_FakeTutorVerifyRepository> openScreen(
      WidgetTester tester,
      EducationTutorVerifyResponse? response, {
      Object? error,
      EducationTutorDetailsResponse? detailsResponse,
      Object? detailsError,
      List<Contact>? contacts,
    }) async {
      final repo = _FakeTutorVerifyRepository(
        response: response,
        error: error,
        detailsResponse: detailsResponse,
        detailsError: detailsError,
      );
      await tester.pumpWidget(
        _wrapWithVerify(
          const EducationSearchRecipientView(
            verificationDuration: Duration(milliseconds: 200),
          ),
          repo,
          contacts: contacts,
        ),
      );
      await tester.pump();
      // The tuition amount typed on the previous screen is what the flow
      // forwards to the Tutor Details API, never a hardcoded value.
      ProviderScope.containerOf(
        tester.element(find.byType(EducationSearchRecipientView)),
      ).read(educationFeesControllerProvider.notifier).updateAmountInput(
            '2000',
          );
      await tester.pump();
      return repo;
    }

    EducationTutorDetailsResponse details(EducationTutorDetailsData data) {
      return EducationTutorDetailsResponse(
        status: true,
        verificationStatus: EducationTutorVerificationStatus.verified,
        message: 'Tutor details fetched successfully.',
        data: data,
      );
    }

    testWidgets('VERIFIED fetches details with the picked mobile and amount',
        (tester) async {
      final repo = await openScreen(
        tester,
        verified,
        detailsResponse: details(tutorDetails),
      );

      await _pickNumber(tester, '9876500003');

      expect(repo.verifyCalls, ['9876500003']);
      expect(repo.detailsMobiles, ['9876500003']);
      expect(repo.detailsAmounts, [2000]);
      expect(find.byType(EducationTutorRequestView), findsOneWidget);
      expect(find.byType(EducationTutorUnverifiedView), findsNothing);
      expect(find.text('Send Request'), findsOneWidget);
    });

    testWidgets('the verified card shows the API tutor name and account',
        (tester) async {
      await openScreen(tester, verified,
          detailsResponse: details(tutorDetails));

      await _pickNumber(tester, '9876500003');

      expect(find.text('Test Tutor Name'), findsOneWidget);
      expect(find.text('50213456789012'), findsOneWidget);
      expect(find.text('Bank: HDFC Bank'), findsOneWidget);
      expect(
        find.text('Account Holder: TEST TUTOR NAME'),
        findsOneWidget,
      );
      // Amount echoed by the Tutor Details API, not the amount entered.
      expect(find.text('₹2,500'), findsOneWidget);
    });

    testWidgets('the card renders bank_logo from the API', (tester) async {
      await openScreen(tester, verified,
          detailsResponse: details(tutorDetails));

      await _pickNumber(tester, '9876500003');

      expect(_networkLogoUrls(tester), ['https://cdn.example/hdfc.png']);
      // The verified badge stays on the shared identity card.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader.toString().contains('tutor'),
        ),
        findsWidgets,
      );
    });

    testWidgets('a null bank_logo keeps the generic bank glyph',
        (tester) async {
      await openScreen(
        tester,
        verified,
        detailsResponse: const EducationTutorDetailsResponse(
          status: true,
          verificationStatus: EducationTutorVerificationStatus.verified,
          data: EducationTutorDetailsData(
            tutorId: 7,
            tutorName: 'Prof. Anita Deshpande',
            // Backend returned no branding at all for this tutor.
            bankName: '',
            accountNumber: '50213456789012',
            accountHolderName: 'ANITA SADANA DESHPANDE',
            ifsc: '',
            bankLogo: null,
            amount: 2500,
          ),
        ),
      );

      await _pickNumber(tester, '9876500003');

      expect(find.byType(EducationTutorRequestView), findsOneWidget);
      // No branding is invented: no network image, only the shared glyph.
      expect(_networkLogoUrls(tester), isEmpty);
      expect(find.imageAsset(FileConstants.homeBank), findsOneWidget);
      // An empty bank name simply hides that caption line.
      expect(find.textContaining('Bank:'), findsNothing);
    });

    testWidgets('NOT_VERIFIED opens the unverified Ask for KYC screen',
        (tester) async {
      final repo = await openScreen(
        tester,
        const EducationTutorVerifyResponse(
          status: true,
          verificationStatus: EducationTutorVerificationStatus.notVerified,
          message: 'This user is registered but KYC is not completed.',
        ),
      );

      await _pickNumber(tester, '9876500003');

      expect(repo.verifyCalls, ['8055851920']);
      // Details are only fetched for a VERIFIED tutor.
      expect(repo.detailsMobiles, isEmpty);
      expect(find.byType(EducationTutorUnverifiedView), findsOneWidget);
      expect(find.byType(EducationTutorRequestView), findsNothing);
    });

    testWidgets('NOT_FOUND opens the same unverified screen', (tester) async {
      final repo = await openScreen(tester, notFound);

      await _pickNumber(tester, '9876500003');

      expect(repo.verifyCalls, ['8055851920']);
      expect(repo.detailsMobiles, isEmpty);
      // NOT_FOUND is a valid business outcome, so it navigates instead of
      // staying on the contacts screen with an error snackbar.
      expect(find.byType(EducationTutorUnverifiedView), findsOneWidget);
      expect(find.byType(EducationTutorRequestView), findsNothing);
      expect(find.text('Verifying on eRupaiya'), findsNothing);
    });

    testWidgets('status false does not open any tutor screen', (tester) async {
      final repo = await openScreen(
        tester,
        const EducationTutorVerifyResponse(
          status: false,
          verificationStatus: EducationTutorVerificationStatus.verified,
          message: 'Invalid request',
        ),
        detailsResponse: details(tutorDetails),
      );

      await _pickNumber(tester, '9876500003');

      expect(repo.verifyCalls, ['8055851920']);
      expect(repo.detailsMobiles, isEmpty);
      expect(find.byType(EducationTutorRequestView), findsNothing);
      expect(find.byType(EducationTutorUnverifiedView), findsNothing);
      expect(find.byType(AppSearchBar), findsOneWidget);
      expect(find.text('Verifying on eRupaiya'), findsNothing);
    });

    testWidgets('a failed verify call does not open any tutor screen',
        (tester) async {
      final repo = await openScreen(
        tester,
        null,
        error: Exception('network down'),
      );

      await _pickNumber(tester, '9876500003');

      expect(repo.verifyCalls, ['8055851920']);
      expect(find.byType(EducationTutorRequestView), findsNothing);
      expect(find.byType(EducationTutorUnverifiedView), findsNothing);
      expect(find.byType(AppSearchBar), findsOneWidget);
    });

    testWidgets(
        'VERIFIED then details NOT_VERIFIED opens Add Details',
        (tester) async {
      final repo = await openScreen(
        tester,
        verified,
        detailsResponse: const EducationTutorDetailsResponse(
          status: true,
          verificationStatus: EducationTutorVerificationStatus.notVerified,
          message: 'This tutor has not completed KYC verification.',
        ),
      );

      await _pickNumber(tester, '9876500003');

      expect(repo.verifyCalls, ['9876500003']);
      expect(repo.detailsMobiles, ['9876500003']);
      expect(find.byType(EducationTutorUnverifiedView), findsOneWidget);
      expect(find.byType(EducationTutorRequestView), findsNothing);
    });

    testWidgets(
        'a details failure after VERIFIED is not treated as '
        'unverified', (tester) async {
      final repo = await openScreen(
        tester,
        verified,
        detailsError: Exception('details timeout'),
      );

      await _pickNumber(tester, '9876500003');

      expect(repo.verifyCalls, ['9876500003']);
      expect(repo.detailsMobiles, ['9876500003']);
      // No fake bank data is shown and the KYC screen is never opened.
      expect(find.byType(EducationTutorRequestView), findsNothing);
      expect(find.byType(EducationTutorUnverifiedView), findsNothing);
      expect(find.byType(AppSearchBar), findsOneWidget);
      expect(find.text('Verifying on eRupaiya'), findsNothing);
    });

    testWidgets('the same number can be retried after a failed call',
        (tester) async {
      final repo = await openScreen(
        tester,
        null,
        error: Exception('network down'),
      );

      await _pickNumber(tester, '9876500003');
      expect(repo.verifyCalls, ['8055851920']);

      // The screen is preserved and the guards are released, so Continue works
      // again as the retry path.
      await _pickNumber(tester, '9876500003');
      expect(repo.verifyCalls, ['8055851920', '8055851920']);
      expect(find.byType(EducationTutorRequestView), findsNothing);
    });

    testWidgets('repeated taps while verifying fire only one call pair',
        (tester) async {
      final repo = await openScreen(
        tester,
        verified,
        detailsResponse: details(tutorDetails),
      );

      await tester.enterText(find.byType(AppSearchBar), '8055851920');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Verifying on eRupaiya'), findsOneWidget);
      // A second tap while the scrim and both API calls are in flight.
      await tester.tap(find.text('Continue'), warnIfMissed: false);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.verifyCalls, ['9876500003']);
      expect(repo.detailsMobiles, ['9876500003']);
      expect(find.byType(EducationTutorRequestView), findsOneWidget);
    });

    testWidgets('selecting a contact runs the same verify and details flow',
        (tester) async {
      final repo = await openScreen(
        tester,
        verified,
        detailsResponse: details(tutorDetails),
        contacts: [
          Contact(
            displayName: 'Test Contact Name',
            phones: [Phone('9876500003')],
          ),
        ],
      );

      // The list tiles are only rendered after the sheet's compute() filter
      // returns from an isolate, which the fake-async test zone never
      // delivers. The picked-contact handler the tile's onTap calls is
      // therefore driven with the very same cached contact values.
      final cached = ProviderScope.containerOf(
        tester.element(find.byType(EducationSearchRecipientView)),
      ).read(contactsCacheControllerProvider).contacts.single;
      final sheet = tester
          .widget<EducationContactSheet>(find.byType(EducationContactSheet));
      sheet.onContactPicked!(
        normalizeEducationMobile(cached.phones.single.number),
        cached.displayName,
      );
      await tester.pump();
      expect(find.text('Verifying on eRupaiya'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.verifyCalls, ['9876500003']);
      expect(repo.detailsMobiles, ['9876500003']);
      expect(repo.detailsAmounts, [2000]);
      expect(find.byType(EducationTutorRequestView), findsOneWidget);
      // The API name wins over the device contact name on the card.
      expect(find.text('Test Tutor Name'), findsOneWidget);
    });
  });
}

/// URLs handed to the shared network image widget, so the test asserts on the
/// API value rather than on a decoded bitmap.
List<String> _networkLogoUrls(WidgetTester tester) {
  return tester
      .widgetList<AppNetworkImage>(find.byType(AppNetworkImage))
      .map((image) => image.url?.trim() ?? '')
      .where((url) => url.isNotEmpty)
      .toList();
}

Finder imageAssetContaining(String asset) => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == asset,
    );

extension on CommonFinders {
  Finder imageAsset(String asset) => imageAssetContaining(asset);
}
