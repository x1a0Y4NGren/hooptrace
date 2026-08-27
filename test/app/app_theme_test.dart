import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

void main() {
  test('retired visual compatibility extension is not registered', () {
    final theme = buildHoopTraceTheme();
    expect(
      theme.extensions.values.any(
        (extension) =>
            extension.runtimeType.toString() == 'HoopTraceVisualTheme',
      ),
      isFalse,
    );
  });

  test('light theme uses the editorial canvas and shared tokens', () {
    final theme = buildHoopTraceTheme();

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, const Color(0xFFFF5A1F));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF4F3EF));
    expect(HoopTraceSpacing.page, 16);
    expect(HoopTraceRadii.card, 4);
    expect(theme.textTheme.bodyLarge?.fontSize, 16);
  });

  test('dark theme uses a black-court canvas with readable foregrounds', () {
    final theme = buildHoopTraceTheme(brightness: Brightness.dark);
    final surface = theme.colorScheme.surface.computeLuminance();
    final foreground = theme.colorScheme.onSurface.computeLuminance();
    final lighter = surface > foreground ? surface : foreground;
    final darker = surface > foreground ? foreground : surface;
    final contrast = (lighter + 0.05) / (darker + 0.05);

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.surface, const Color(0xFF151719));
    expect(contrast, greaterThan(4.5));
    expect(theme.appBarTheme.backgroundColor, const Color(0xFF0C0D0E));
  });

  test('primary actions meet WCAG text contrast in both themes', () {
    final light = buildHoopTraceTheme();
    final dark = buildHoopTraceTheme(brightness: Brightness.dark);

    for (final scheme in [light.colorScheme, dark.colorScheme]) {
      expect(
        _contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('team result colors meet WCAG contrast on light and dark surfaces', () {
    final light = buildHoopTraceTheme();
    final dark = buildHoopTraceTheme(brightness: Brightness.dark);

    for (final side in TeamSide.values) {
      expect(
        _contrast(
          teamColorForScheme(side, light.colorScheme),
          light.colorScheme.surfaceContainer,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          teamColorForScheme(side, dark.colorScheme),
          dark.colorScheme.surfaceContainer,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          teamColorForScheme(
            side,
            light.colorScheme,
            background: HoopTraceColors.ink,
          ),
          HoopTraceColors.ink,
        ),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}

double _contrast(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
