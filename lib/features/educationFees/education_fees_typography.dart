import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Plus Jakarta Sans for the entire Education Fees module.
class EducationFeesTheme extends StatelessWidget {
  const EducationFeesTheme({super.key, required this.child});

  final Widget child;

  static ThemeData wrapTheme(ThemeData base) {
    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      primaryTextTheme:
          GoogleFonts.plusJakartaSansTextTheme(base.primaryTextTheme),
    );
  }

  static TextStyle style(TextStyle style) {
    return GoogleFonts.plusJakartaSans(textStyle: style);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: wrapTheme(Theme.of(context)),
      child: child,
    );
  }
}
