import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme() {
  const seedColor = Color(0xFFE7B7C8); // soft rose
  const backgroundColor = Color(0xFFFFFBFC); // blush white
  const inkColor = Color(0xFF1F1A1C); // deep warm black
  const mutedColor = Color(0xFF5B4E53); // darker than before (more readable)

  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    background: backgroundColor,
    surface: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: backgroundColor,
  );

  final textTheme = TextTheme(
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: inkColor,
    ),
    headlineSmall: GoogleFonts.playfairDisplay(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: inkColor,
    ),
    titleLarge: GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: inkColor,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: inkColor,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      color: inkColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      color: inkColor, // ✅ IMPORTANT: readable by default
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      color: mutedColor,
    ),
    labelLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w700,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,

    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: inkColor,
      ),
      iconTheme: const IconThemeData(color: inkColor),
    ),

    cardTheme: CardTheme(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.inter(color: mutedColor),
      labelStyle: GoogleFonts.inter(color: mutedColor, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
    ),

    // ✅ FilledButton (Material3)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: inkColor, // ✅ no white text
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
      ),
    ),

    // ✅ ElevatedButton (some screens still use it)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: inkColor, // ✅ no white text
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: inkColor,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
      ),
    ),

    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: colorScheme.outlineVariant),
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, color: inkColor),
      selectedColor: colorScheme.primary.withOpacity(0.14),
    ),

    // ✅ IMPORTANT: you use NavigationBar (Material3), not BottomNavigationBar
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      backgroundColor: Colors.white.withOpacity(0.92),
      elevation: 0,
      indicatorColor: colorScheme.primary.withOpacity(0.18),
      labelTextStyle: MaterialStateProperty.all(
        GoogleFonts.inter(fontWeight: FontWeight.w800),
      ),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        final selected = states.contains(MaterialState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : mutedColor,
        );
      }),
    ),

    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: inkColor,
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

