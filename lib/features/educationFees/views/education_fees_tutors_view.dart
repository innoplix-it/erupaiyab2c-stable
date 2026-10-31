// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_search_bar.dart';
import '../../../widgets/my_app_bar.dart';
import '../../profile/controllers/profile_controller.dart';
import '../education_fees_typography.dart';
import '../models/education_fees_responses.dart';
import 'education_tutor_profile_view.dart';

/// Shared mint gradient (same as Tuition Fee amount screen).
const LinearGradient _kTutorsMintGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFB5FFDA), Color(0xFFFFFFFF)],
  stops: [0.0, 0.6631],
);

const double _kFigmaW = 448.0;
const double _kMaxContentW = 560.0;

double _unit(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w.clamp(320.0, _kMaxContentW) / _kFigmaW;
}

class EducationFeesTutorsView extends HookConsumerWidget {
  const EducationFeesTutorsView({
    super.key,
    required this.amount,
    required this.tutors,
  });

  final double amount;
  final List<EducationBeneficiary> tutors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final query = useState('');
    useEffect(() {
      Future.microtask(
        () =>
            ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded(),
      );
      return null;
    }, const []);

    final filtered = useMemoized(() {
      final q = query.value.trim().toLowerCase();
      if (q.isEmpty) return tutors;
      return tutors.where((t) {
        final name = t.name.toLowerCase();
        final mobile = t.mobile.toLowerCase();
        final account = t.accountMasked.toLowerCase();
        final type = t.accountType.toLowerCase();
        return name.contains(q) ||
            mobile.contains(q) ||
            account.contains(q) ||
            type.contains(q);
      }).toList();
    }, [tutors, query.value]);

    void openSummary(EducationBeneficiary tutor) {
      // Tutor profile screen — every value shown there comes from the
      // beneficiaries API (the [tutor] record), nothing is fabricated here.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EducationTutorProfileView(
            tutorName:
                tutor.name.isEmpty ? _fallbackTutorName(tutor) : tutor.name,
            accountLine: tutor.accountMasked,
            amount: amount,
            amountLabel: '\u20B9${amount.toStringAsFixed(0)}',
            panDetails: tutor.panMasked,
            accountNumber: tutor.accountNoUnmasked,
            ifscCode: tutor.ifsc,
            branch: tutor.branch,
          ),
        ),
      );
    }

    final u = _unit(context);
    final inset = 18 * u;
    const heroCirclePx = 138.0;
    final circle = heroCirclePx * u;
    final scale = circle / heroCirclePx;

    return EducationFeesTheme(
      child: Scaffold(
        backgroundColor: const Color(0xFFB5FFDA),
        appBar: MyAppBar(
          title: 'Tutors',
          showHelp: true,
          showBharatConnect: false,
          showDivider: false,
          fitTitle: true,
          titleStyle: MyAppBar.sharedTitleStyle(context),
          backgroundColor: const Color(0xFFB5FFDA),
          helpIconSize: 20 * u,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: _kTutorsMintGradient),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      inset,
                      24 * u,
                      inset,
                      20 * u,
                    ),
                    children: [
                      Center(
                        child: SizedBox(
                          width: circle,
                          height: circle,
                          child: ClipOval(
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  left: -29 * scale,
                                  top: -6 * scale,
                                  width: 196 * scale,
                                  height: 244 * scale,
                                  child: SvgPicture.asset(
                                    FileConstants.tuitionFeeHeroSvg,
                                    width: 196 * scale,
                                    height: 244 * scale,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18 * u),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12 * u),
                        child: Text(
                          'Select tutor to pay tuition fees \n via credit card',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            fontSize: 18 * u,
                            height: 1.35,
                          ),
                        ),
                      ),
                      SizedBox(height: 30 * u),
                      AppSearchBar(
                        hintText: 'Search contacts / tutors',
                        controller: searchController,
                        onChanged: (value) => query.value = value,
                        showSearchIcon: false,
                        barHeight: 54 * u,
                        barCornerRadius: 12 * u,
                        hintFontSize: 14 * u,
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 14 * u,
                          color: Colors.black,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 14 * u, right: 4 * u),
                          child: SvgPicture.asset(
                            FileConstants.educationSearchIconSvg,
                            width: 18 * u,
                            height: 18 * u,
                            fit: BoxFit.contain,
                          ),
                        ),
                        trailing: Padding(
                          padding: EdgeInsets.only(right: 10 * u),
                          child: GestureDetector(
                            onTap: () => context.push(
                              RouteConstants.educationSearchRecipient,
                            ),
                            child: SvgPicture.asset(
                              FileConstants.addTutorBadgeSvg,
                              height: 31 * u,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 26 * u),
                      Text(
                        'MY TUTORS',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF71717A),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          fontSize: 11 * u,
                          height: 1.9,
                        ),
                      ),
                      SizedBox(height: 18 * u),
                      if (filtered.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 32 * u),
                          child: Text(
                            query.value.trim().isEmpty
                                ? 'No tutors found.'
                                : 'No tutors match your search.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF71717A),
                                  fontSize: 14 * u,
                                ),
                          ),
                        )
                      else
                        ...List.generate(filtered.length, (index) {
                          final tutor = filtered[index];
                          final name = tutor.name.isEmpty
                              ? _fallbackTutorName(tutor)
                              : tutor.name;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10 * u),
                            child: _TutorCard(
                              unit: u,
                              name: name,
                              subject: _subjectLabel(tutor),
                              onViewAndPay: () => openSummary(tutor),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({
    required this.unit,
    required this.name,
    required this.subject,
    required this.onViewAndPay,
  });

  final double unit;
  final String name;
  final String? subject;
  final VoidCallback onViewAndPay;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final initials = _initialsFor(name);
    return Container(
      padding: EdgeInsets.fromLTRB(12 * u, 14 * u, 12 * u, 14 * u),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * u),
        border: Border.all(color: const Color(0xFFD7D7D7), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 12 * u,
            offset: Offset(0, 4 * u),
          ),
        ],
      ),
      child: Row(
        children: [
          _TutorAvatar(initials: initials, unit: u),
          SizedBox(width: 12 * u),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    fontSize: 14 * u,
                    height: 1.2,
                  ),
                ),
                if (subject != null && subject!.isNotEmpty) ...[
                  SizedBox(height: 5 * u),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * u,
                      vertical: 2 * u,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12 * u),
                      border: Border.all(
                        color: const Color(0xFFE4E4E7),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      subject!,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF52525B),
                        fontWeight: FontWeight.w600,
                        fontSize: 11 * u,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 6 * u),
          SizedBox(
            height: 32 * u,
            child: ElevatedButton(
              onPressed: onViewAndPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDD5428),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 10 * u),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16 * u),
                ),
              ),
              child: Text(
                'View & Pay',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12 * u,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorAvatar extends StatelessWidget {
  const _TutorAvatar({
    required this.initials,
    required this.unit,
  });

  final String initials;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final size = 48 * u;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(
            FileConstants.tutorListAvatarSvg,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          Text(
            initials,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontSize: 15 * u,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

String _initialsFor(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String? _subjectLabel(EducationBeneficiary tutor) {
  final raw = tutor.accountType.trim();
  if (raw.isEmpty) return null;
  // Backend account_type — show as a short subject/tag under the name.
  if (raw.length == 1) return raw.toUpperCase();
  return raw[0].toUpperCase() + raw.substring(1);
}

String _fallbackTutorName(EducationBeneficiary tutor) {
  if (tutor.accountMasked.isNotEmpty) {
    return 'Account ${tutor.accountMasked}';
  }
  return 'Beneficiary';
}
