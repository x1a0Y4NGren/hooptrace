import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS build configuration targets version 14 or newer', () {
    const minimumVersion = 14.0;
    final podfile = File('ios/Podfile');

    expect(podfile.existsSync(), isTrue, reason: 'The Podfile must be pinned.');
    expect(
      podfile.readAsStringSync(),
      contains("platform :ios, '14.0'"),
      reason: 'CocoaPods must resolve plugins against iOS 14 or newer.',
    );

    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final targets = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);',
    ).allMatches(project).toList();

    expect(targets, isNotEmpty);
    for (final target in targets) {
      final version = double.parse(target.group(1)!);
      expect(
        version,
        greaterThanOrEqualTo(minimumVersion),
        reason: 'Every Xcode build configuration must target iOS 14 or newer.',
      );
    }
  });
}
