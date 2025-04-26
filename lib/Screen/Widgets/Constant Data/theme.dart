import 'package:flutter/material.dart';

import 'constant.dart';

abstract class AcnooTheme {
  static const _fontFamily = 'NotoSans';
  static ThemeData kLightTheme(BuildContext context) {
    final mainTheme = ThemeData.light();
    final textTheme = _getTextTheme(mainTheme.textTheme);
    return mainTheme.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      snackBarTheme: _getSnackBarTheme(),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: kTitleColor),
        inputDecorationTheme: InputDecorationTheme(
          iconColor: kGreyTextColor,
          contentPadding: EdgeInsets.only(left: 10.0, right: 7.0),
        ),
      ),
      dialogBackgroundColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        suffixIconColor: kGreyTextColor,
        iconColor: kGreyTextColor,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        focusColor: kMainColor,
        outlineBorder: const BorderSide(color: Color(0xFFD7D9DE), width: 1.0),
        hintStyle: const TextStyle(color: kTextSecondaryColor, fontSize: 16.0, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(color: kTextPrimaryColor, fontSize: 16.0, fontWeight: FontWeight.w500),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: kMainColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Color(0xffD7D9DE), width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Color(0xFFb00020), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Color(0xFFb00020), width: 1.0),
        ),
        contentPadding: const EdgeInsets.only(left: 10.0, right: 7.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Color(0xffD7D9DE), width: 1.0),
        ),
        filled: false,
        fillColor: Colors.white,
      ),
      colorScheme: const ColorScheme.light(
        surface: Colors.white,
        primary: kMainColor,
        primaryContainer: kWhite,
        outline: kOutlineColor,
        secondary: kTextSecondaryColor,
      ),
      elevatedButtonTheme: _getElevatedButtonTheme(textTheme),
      outlinedButtonTheme: _getOutlineButtonTheme(textTheme),
    );
  }

  //------------------Elevated Button Theme------------------//
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 12,
  );
  //------------------snack bar theme------------------------
  static SnackBarThemeData _getSnackBarTheme() {
    return const SnackBarThemeData(
      backgroundColor: Color(0xff333333),
      actionTextColor: Colors.white,
      contentTextStyle: TextStyle(color: Colors.white),
    );
  }

  static const _buttonDensity = VisualDensity.standard;
  static _getElevatedButtonTheme(TextTheme baseTextTheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: _buttonPadding,
        // minimumSize: const Size(double.infinity, 48),
        visualDensity: _buttonDensity,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: kMainColor,
        foregroundColor: kWhite,
        textStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static _getOutlineButtonTheme(TextTheme baseTextTheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: _buttonPadding,
        // minimumSize: const Size(double.infinity, 48),
        visualDensity: _buttonDensity,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: Colors.red),
        foregroundColor: Colors.red,
        textStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.red),
      ),
    );
  }

  static TextTheme _getTextTheme(TextTheme baseTextTheme) {
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: _fontFamily,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: _fontFamily,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontFamily: _fontFamily,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: _fontFamily,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: _fontFamily,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: _fontFamily,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: _fontFamily,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: _fontFamily,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontFamily: _fontFamily,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontFamily: _fontFamily,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontFamily: _fontFamily,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: _fontFamily, color: kNeutral600),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontFamily: _fontFamily,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontFamily: _fontFamily,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontFamily: _fontFamily,
      ),
    );
  }
}
