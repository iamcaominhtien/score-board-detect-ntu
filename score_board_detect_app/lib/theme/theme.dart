import 'package:flutter/material.dart';

const Color _darkBackground = Color(0xFF0C134F);
const Color _darkPrimary = Color(0xFF1D267D);
const Color _darkContainer = Color(0xFF1D267D);
const Color _darkSecondary = Color(0xFF5C469C);
const Color _darkOnBackground = Color(0xFFD4ADFC);

ThemeData get darkTheme => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        background: _darkBackground,
        primary: _darkPrimary,
        primaryContainer: _darkContainer,
        onPrimaryContainer: _darkOnBackground,
        secondary: _darkSecondary,
        onBackground: _darkOnBackground,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: _darkOnBackground,
        ),
        bodyMedium: TextStyle(
          color: _darkOnBackground,
        ),
        bodySmall: TextStyle(
          color: _darkOnBackground,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkPrimary,
        foregroundColor: _darkOnBackground,
        titleTextStyle: TextStyle(
          color: _darkOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        toolbarTextStyle: TextStyle(
          color: _darkOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkOnBackground,
          // textStyle: const TextStyle(
          //   color: _darkOnBackground,
          // ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: _darkOnBackground,
          side: const BorderSide(
            color: _darkOnBackground,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: _darkOnBackground,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        focusColor: _darkOnBackground,
        labelStyle: TextStyle(
          color: _darkOnBackground,
        ),
      ),
    );

const Color _lightBackground = Color(0xFFF6F1E9);
const Color _lightPrimary = Color(0xFFFF8400);
const Color _lightContainer = Colors.white;
const Color _lightSecondary = Color(0xFFFFD93D);
const Color _lightOnBackground = Color(0xFF4F200D);

ThemeData get lightTheme => ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        background: _lightBackground,
        primary: _lightPrimary,
        primaryContainer: _lightContainer,
        onPrimaryContainer: _lightOnBackground,
        secondary: _lightSecondary,
        onBackground: _lightOnBackground,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: _lightOnBackground,
        ),
        bodyMedium: TextStyle(
          color: _lightOnBackground,
        ),
        bodySmall: TextStyle(
          color: _lightOnBackground,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightPrimary,
        foregroundColor: _lightOnBackground,
        titleTextStyle: TextStyle(
          color: _lightOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        toolbarTextStyle: TextStyle(
          color: _lightOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
