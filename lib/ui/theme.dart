import 'package:flutter/material.dart';

ColorScheme catalogScheme(Brightness brightness) {
  ColorScheme seeded(int color) =>
      ColorScheme.fromSeed(seedColor: Color(color), brightness: brightness);
  final forest = seeded(0xFF315C38);
  final sage = seeded(0xFF7B8F71);
  final cream = seeded(0xFFD8C9A7);
  return forest.copyWith(
    secondary: sage.secondary,
    onSecondary: sage.onSecondary,
    secondaryContainer: sage.secondaryContainer,
    onSecondaryContainer: sage.onSecondaryContainer,
    tertiary: cream.primary,
    onTertiary: cream.onPrimary,
    tertiaryContainer: cream.primaryContainer,
    onTertiaryContainer: cream.onPrimaryContainer,
    surface: cream.surface,
    onSurface: cream.onSurface,
    onSurfaceVariant: cream.onSurfaceVariant,
    surfaceDim: cream.surfaceDim,
    surfaceBright: cream.surfaceBright,
    surfaceContainerLowest: cream.surfaceContainerLowest,
    surfaceContainerLow: cream.surfaceContainerLow,
    surfaceContainer: cream.surfaceContainer,
    surfaceContainerHigh: cream.surfaceContainerHigh,
    surfaceContainerHighest: cream.surfaceContainerHighest,
    outline: cream.outline,
    outlineVariant: cream.outlineVariant,
    inverseSurface: cream.inverseSurface,
    onInverseSurface: cream.onInverseSurface,
  );
}

ThemeData catalogTheme(Brightness brightness) => ThemeData(
  useMaterial3: true,
  colorScheme: catalogScheme(brightness),
  iconButtonTheme: const IconButtonThemeData(
    style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
  ),
  filledButtonTheme: const FilledButtonThemeData(
    style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
  ),
  textButtonTheme: const TextButtonThemeData(
    style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
  ),
  outlinedButtonTheme: const OutlinedButtonThemeData(
    style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
  ),
);
