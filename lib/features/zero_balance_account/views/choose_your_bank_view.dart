import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../home/components/zero_balance_account_popup_view.dart';
import '../components/zero_balance_account_success_popup.dart';
import '../models/zero_balance_bank.dart';

/// Figma reference frame: 440 x 978. Each Figma px value is scaled exactly
/// once, by ScreenUtil: layout as a fraction of the screen (.sw / .sh), text
/// via .sp after mapping the 440 frame onto ScreenUtil's design width.
const double _figmaWidth = 440;
const double _figmaHeight = 978;

double _w(double px) => (px / _figmaWidth).sw;
double _h(double px) => (px / _figmaHeight).sh;
/// Figma px -> ScreenUtil design units (unscaled); feed to exactly one of
/// .sp / .r.
double _design(double px) {
  final screenUtil = ScreenUtil();
  final designWidth = screenUtil.screenWidth / screenUtil.scaleWidth;
  return px * designWidth / _figmaWidth;
}

double _sp(double px) => _design(px).sp;

/// Spacing that should look the same on every phone: scales with
/// min(width, height) like the .sp text it separates, not with screen height.
double _r(double px) => _design(px).r;

const Color _zinc600 = Color(0xFF52525B);
const Color _accountTypeGreen = Color(0xFF16A34A);
const Color _disabledButton = Color(0xFFADADAD);

class ChooseYourBankView extends StatefulWidget {
  const ChooseYourBankView({
    super.key,
    this.rewardAmount = ZeroBalanceBank.defaultRewardAmount,
    this.banks,
    this.onContinue,
    this.creditedRewardAmount,
  });

  final num rewardAmount;
  final List<ZeroBalanceBank>? banks;

  /// Overrides the default Continue behaviour (the Congratulations popup).
  final ValueChanged<ZeroBalanceBank>? onContinue;

  /// Reward the account-opening API reports as credited. No such API exists
  /// yet, so it is null and the Congratulations popup shows ₹0.
  final num? creditedRewardAmount;

  @override
  State<ChooseYourBankView> createState() => _ChooseYourBankViewState();
}

class _ChooseYourBankViewState extends State<ChooseYourBankView> {
  String? _selectedId;

  List<ZeroBalanceBank> get _banks =>
      widget.banks ?? ZeroBalanceBank.partners;

  ZeroBalanceBank? get _selectedBank {
    for (final bank in _banks) {
      if (bank.id == _selectedId) return bank;
    }
    return null;
  }

  Future<void> _onContinue() async {
    final bank = _selectedBank;
    if (bank == null) return;
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(bank);
      return;
    }
    // TEMP: no account-opening API exists yet, so Continue shows the
    // Congratulations popup directly. Call that API here and show the popup
    // only on success once it is available.
    final action = await showZeroBalanceAccountSuccessPopup(
      context,
      bank: bank,
      rewardAmount: widget.creditedRewardAmount,
    );
    if (!mounted) return;
    switch (action) {
      case ZeroBalanceSuccessAction.done:
        Navigator.of(context).maybePop();
      case ZeroBalanceSuccessAction.viewBalance:
        context.pushReplacement(RouteConstants.referAndEarnWallet);
      case ZeroBalanceSuccessAction.close:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                FileConstants.zeroBalancePopupBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                opacity: kZeroBalanceBgOpacity,
              ),
            ),
            Column(
              children: [
                Expanded(child: _buildBody(insets.top)),
                _BottomBar(
                  bottomInset: insets.bottom,
                  enabled: _selectedBank != null,
                  onContinue: _onContinue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(double topInset) {
    final rewardLabel = formatZeroBalanceReward(widget.rewardAmount);
    final backTarget = _w(48);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        _w(24),
        topInset + _h(3),
        _w(24),
        _h(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The 48 px tap target is shifted so the 24 px glyph lines up with
          // the page's left edge, as in Figma.
          Transform.translate(
            offset: Offset(-(backTarget - _w(24)) / 2, 0),
            child: IconButton(
              key: const ValueKey('chooseBankBack'),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: backTarget,
                height: backTarget,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.black,
                size: _w(24),
              ),
            ),
          ),
          SizedBox(height: _h(31)),
          Text(
            'Choose Your Bank',
            key: const ValueKey('chooseBankTitle'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: _sp(20),
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: _h(4)),
          Text(
            'Open a zero balance savings account with your preferred bank.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: _sp(14),
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: _h(18)),
          for (var i = 0; i < _banks.length; i++) ...[
            if (i > 0) SizedBox(height: _h(22)),
            _BankTile(
              key: ValueKey('chooseBank_${_banks[i].id}'),
              bank: _banks[i],
              selected: _banks[i].id == _selectedId,
              onTap: () => setState(() => _selectedId = _banks[i].id),
            ),
          ],
          SizedBox(height: _h(48)),
          SvgPicture.asset(
            FileConstants.giftIconSvg,
            width: _w(32),
            height: _w(30),
          ),
          SizedBox(height: _h(14)),
          Text(
            'Earn Up to $rewardLabel to in Rewards',
            key: const ValueKey('chooseBankRewardHeading'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: _sp(18),
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: _h(6)),
          Text(
            'Get your reward in the eRupaiya app after your account is '
            'successfully opened, subject to applicable terms.',
            key: const ValueKey('chooseBankRewardBody'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: _sp(14),
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: _h(10)),
          Text(
            'Rewards are subject to eligibility, successful account opening, '
            'and applicable offer terms.*',
            key: const ValueKey('chooseBankRewardTerms'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: _sp(10),
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({
    super.key,
    required this.bank,
    required this.selected,
    required this.onTap,
  });

  final ZeroBalanceBank bank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_w(8));
    final logoBox = _w(62);
    final logoWidth = _w(bank.logoFigmaWidth);
    return Semantics(
      button: true,
      selected: selected,
      label: bank.name,
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: EdgeInsets.all(_w(12)),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: logoBox,
                  height: logoBox,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_w(4)),
                    border: Border.all(color: AppColors.lightBorder2),
                  ),
                  child: SvgPicture.asset(
                    bank.logoAsset,
                    width: logoWidth,
                    height: logoWidth / bank.logoAspectRatio,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: _w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: _sp(16),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        bank.accountType,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: _sp(12),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: _accountTypeGreen,
                        ),
                      ),
                      Text(
                        bank.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: _sp(12),
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          color: _zinc600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _w(12)),
                _RadioMark(size: _w(20), selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.size, required this.selected});

  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return SvgPicture.asset(
        FileConstants.radioUnselectedIconSvg,
        width: size,
        height: size,
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: size * 0.1),
      ),
      child: Container(
        width: size * 0.5,
        height: size * 0.5,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.bottomInset,
    required this.enabled,
    required this.onContinue,
  });

  final double bottomInset;
  final bool enabled;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        // Design spacing via .r so it reads the same on short and tall
        // phones. Figma leaves 30 px under the hint; on devices with a home
        // indicator the hint must still clear the system inset.
        padding: EdgeInsets.fromLTRB(
          _w(24),
          _r(31),
          _w(24),
          math.max(_r(30), bottomInset + _r(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomElevatedButton(
              key: const ValueKey('chooseBankContinue'),
              // Kept non-null so Material's disabled overlay does not darken
              // the Figma grey; _onContinue ignores taps until a bank is
              // picked.
              onPressed: onContinue,
              label: 'Continue',
              height: _w(52),
              uppercaseLabel: false,
              backgroundColor: enabled ? null : _disabledButton,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: _sp(18),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              key: const ValueKey('chooseBankContinueGap'),
              height: _r(10),
            ),
            Text(
              'Select a bank to continue',
              key: const ValueKey('chooseBankContinueHint'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: _sp(12),
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: _zinc600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
