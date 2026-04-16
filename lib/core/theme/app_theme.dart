import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Primary palette ─────────────────────────────────────────────────────
  static const violet     = Color(0xFF7C3AED); // Primary brand
  static const violetDeep = Color(0xFF4C1D95); // Deep variant
  static const violetSoft = Color(0xFFF5F3FF); // Light surface tint
  static const violetMid  = Color(0xFFEDE9FE); // Chip / tag bg
  static const violetDark = Color(0xFF2E1065); // Darkest for gradients

  // ── Accent ──────────────────────────────────────────────────────────────
  static const gold      = Color(0xFFD97706); // Amber gold
  static const goldLight = Color(0xFFFEF3C7); // Gold light bg

  // ── Semantic ────────────────────────────────────────────────────────────
  static const success = Color(0xFF059669);
  static const danger  = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info    = Color(0xFF0EA5E9);

  // ── Neutrals ────────────────────────────────────────────────────────────
  static const charcoal = Color(0xFF1E1B4B);
  static const slate    = Color(0xFF64748B);
  static const surface  = Color(0xFFFAF8FF);
  static const cream    = Color(0xFFF8F7FF);
  static const ivory    = Color(0xFFF5F3FF); // kept for compat

  // ── Backward-compat aliases (existing files use these) ──────────────────
  static const saffron    = violet;
  static const deepMaroon = violetDeep;

  // ── Gradients ───────────────────────────────────────────────────────────
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, Color(0xFF9333EA)],
  );
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violetDeep, violet, Color(0xFFBE185D)],
  );
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );
  static const coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF0EA5E9)],
  );
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.light,
      primary: AppColors.violet,
      secondary: AppColors.gold,
      tertiary: AppColors.violetDeep,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.violetSoft,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.dark,
      primary: Color(0xFFA78BFA),  // lighter violet for dark mode
      secondary: AppColors.gold,
      tertiary: Color(0xFF8B5CF6),
    );
    return _base(scheme, Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F0E17) : AppColors.surface,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1A1830) : AppColors.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        shadowColor: AppColors.violet.withValues(alpha: 0.08),
        surfaceTintColor: AppColors.violet,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1830) : Colors.white,
        indicatorColor: AppColors.violetMid,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.violet, size: 24);
          }
          return IconThemeData(color: AppColors.slate, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelSmall?.copyWith(color: AppColors.slate);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.violet.withValues(alpha: 0.12),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violet,
          side: const BorderSide(color: AppColors.violet, width: 1.5),
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.violet,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1E1B4B).withValues(alpha: 0.6)
            : AppColors.violetSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.violetMid,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.violet, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        prefixIconColor: AppColors.slate,
        suffixIconColor: AppColors.slate,
        hintStyle: TextStyle(color: AppColors.slate.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.slate),
        floatingLabelStyle: const TextStyle(color: AppColors.violet),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: isDark ? const Color(0xFF1A1830) : Colors.white,
        surfaceTintColor: AppColors.violetSoft,
        shadowColor: AppColors.violet.withValues(alpha: 0.08),
        clipBehavior: Clip.antiAlias,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.violetMid,
        selectedColor: AppColors.violet,
        labelStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppColors.violet,
      ),

      dividerTheme: const DividerThemeData(
        space: 0,
        thickness: 0.5,
        color: AppColors.violetMid,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.violet,
        linearTrackColor: AppColors.violetMid,
        circularTrackColor: AppColors.violetMid,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.violet,
        inactiveTrackColor: AppColors.violetMid,
        thumbColor: AppColors.violet,
        overlayColor: AppColors.violet.withValues(alpha: 0.12),
        valueIndicatorColor: AppColors.violetDeep,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.violet : AppColors.slate),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.violetMid
                : AppColors.violetSoft),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.violet : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: AppColors.slate, width: 1.5),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
        smallSize: 8,
        largeSize: 18,
        textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        padding: EdgeInsets.symmetric(horizontal: 5),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.charcoal,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.gold,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.charcoal,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.violet,
        unselectedLabelColor: AppColors.slate,
        indicatorColor: AppColors.violet,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
    );
  }
}
