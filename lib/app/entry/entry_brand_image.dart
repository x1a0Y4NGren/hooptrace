import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:hooptrace/app/entry/entry_motion_pose.dart';

const entryBrandAsset = 'assets/icons/hooptrace-app-icon-foreground.png';

/// Decode for the physical size of the fixed native/Flutter canvas. The
/// approved source remains unchanged and the caller owns the returned image.
Future<ui.Image> decodeEntryBrandImage({
  required double devicePixelRatio,
}) async {
  final data = await rootBundle.load(entryBrandAsset);
  final targetWidth =
      (EntryMotionPose.canvasExtent *
              EntryMotionPose.baseScale *
              devicePixelRatio)
          .ceil();
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    targetWidth: targetWidth,
    allowUpscaling: false,
  );
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}
