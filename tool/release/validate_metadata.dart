import 'dart:io';

const _pngSignature = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

/// Checks the repository-owned Fastlane metadata before a release candidate is
/// built. This intentionally avoids a Fastlane installation so the same gate
/// can run in CI and in a clean source checkout.
Future<void> main() async {
  final root = Directory.current;
  final pubspec = File(_join(root.path, 'pubspec.yaml'));
  final version = RegExp(
    r'^version:\s+\d+\.\d+\.\d+\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(await pubspec.readAsString())?.group(1);
  if (version == null) {
    throw StateError(
      'pubspec.yaml must declare a semantic version and build number.',
    );
  }

  for (final locale in const ['en-US', 'zh-CN']) {
    final base = _join(root.path, 'fastlane', 'metadata', 'android', locale);
    _requireFile(_join(base, 'short_description.txt'));
    _requireFile(_join(base, 'full_description.txt'));
    final short = File(
      _join(base, 'short_description.txt'),
    ).readAsStringSync().trim();
    if (short.isEmpty || short.length > 80) {
      throw StateError(
        '$locale short_description.txt must be 1-80 characters.',
      );
    }
    final changelog = _join(base, 'changelogs', '$version.txt');
    _requireFile(changelog);
    final changelogText = File(changelog).readAsStringSync().trim();
    if (changelogText.isEmpty || changelogText.length > 500) {
      throw StateError(
        '$locale $version.txt changelog must be 1-500 characters.',
      );
    }
    final screenshotDirectory = Directory(
      _join(base, 'images', 'phoneScreenshots'),
    );
    if (!screenshotDirectory.existsSync()) {
      throw StateError('Missing screenshot directory for $locale.');
    }
    final screenshots =
        screenshotDirectory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.png'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    final images = <String>[
      _join(base, 'images', 'icon.png'),
      ...screenshots.map((file) => file.path),
    ];
    if (screenshots.length < 2) {
      throw StateError(
        '$locale must include an icon and at least two screenshots.',
      );
    }
    for (final image in images) {
      final expectedDimensions = _expectedDimensions(image);
      final decoded = await _decodePng(image);
      if (expectedDimensions != null &&
          (decoded.width != expectedDimensions.width ||
              decoded.height != expectedDimensions.height)) {
        throw StateError(
          '$image must be ${expectedDimensions.width}x${expectedDimensions.height}; '
          'found ${decoded.width}x${decoded.height}.',
        );
      }
    }
  }

  stdout.writeln(
    'Release metadata is present for en-US and zh-CN (versionCode $version).',
  );
}

Future<_PngInfo> _decodePng(String path) async {
  final bytes = await File(path).readAsBytes();
  if (bytes.length < _pngSignature.length ||
      !_sameBytes(bytes, _pngSignature, 0)) {
    throw StateError('$path is not a PNG file.');
  }

  var offset = _pngSignature.length;
  var sawChunk = false;
  var sawHeader = false;
  var sawImageData = false;
  var sawEnd = false;
  var width = 0;
  var height = 0;
  var bitDepth = 0;
  var colorType = 0;
  var interlaceMethod = 0;
  final compressedImageData = <int>[];

  while (offset < bytes.length) {
    if (offset + 8 > bytes.length) {
      throw StateError('$path has a truncated PNG chunk.');
    }
    final length = _readUint32(bytes, offset);
    offset += 4;
    final typeOffset = offset;
    final dataOffset = typeOffset + 4;
    final dataEnd = dataOffset + length;
    final crcEnd = dataEnd + 4;
    if (dataEnd < dataOffset || crcEnd < dataEnd || crcEnd > bytes.length) {
      throw StateError('$path has a PNG chunk outside the file.');
    }
    final type = String.fromCharCodes(bytes.sublist(typeOffset, dataOffset));
    final expectedCrc = _readUint32(bytes, dataEnd);
    final actualCrc = _crc32(bytes.sublist(typeOffset, dataEnd));
    if (actualCrc != expectedCrc) {
      throw StateError('$path has an invalid $type chunk CRC.');
    }
    if (type == 'IHDR') {
      if (sawChunk || sawHeader || length != 13) {
        throw StateError('$path has an invalid IHDR chunk.');
      }
      sawHeader = true;
      width = _readUint32(bytes, dataOffset);
      height = _readUint32(bytes, dataOffset + 4);
      bitDepth = bytes[dataOffset + 8];
      colorType = bytes[dataOffset + 9];
      final compressionMethod = bytes[dataOffset + 10];
      final filterMethod = bytes[dataOffset + 11];
      interlaceMethod = bytes[dataOffset + 12];
      if (width == 0 ||
          height == 0 ||
          compressionMethod != 0 ||
          filterMethod != 0 ||
          interlaceMethod != 0 ||
          !_validBitDepth(colorType, bitDepth)) {
        throw StateError('$path has unsupported PNG image parameters.');
      }
    } else if (type == 'IDAT') {
      if (!sawHeader || sawEnd) {
        throw StateError('$path has IDAT outside the image data stream.');
      }
      sawImageData = true;
      compressedImageData.addAll(bytes.sublist(dataOffset, dataEnd));
    } else if (type == 'IEND') {
      if (!sawHeader || !sawImageData || length != 0) {
        throw StateError('$path has an invalid IEND chunk.');
      }
      sawEnd = true;
    }
    sawChunk = true;
    offset = crcEnd;
    if (sawEnd) break;
  }

  if (!sawHeader || !sawImageData || !sawEnd || offset != bytes.length) {
    throw StateError('$path is missing a complete PNG image stream.');
  }

  final channels = switch (colorType) {
    0 => 1,
    2 => 3,
    3 => 1,
    4 => 2,
    6 => 4,
    _ => throw StateError('$path has an unsupported PNG color type.'),
  };
  final rowBits = width * channels * bitDepth;
  final rowBytes = (rowBits + 7) >> 3;
  final decoded = _decodeZlib(path, compressedImageData);
  final expectedLength = (rowBytes + 1) * height;
  if (decoded.length != expectedLength) {
    throw StateError(
      '$path decoded to ${decoded.length} bytes; expected $expectedLength.',
    );
  }
  final bytesPerPixel = ((channels * bitDepth + 7) >> 3)
      .clamp(1, rowBytes)
      .toInt();
  var previousRow = List<int>.filled(rowBytes, 0);
  for (var row = 0; row < height; row++) {
    final rowOffset = row * (rowBytes + 1);
    final filter = decoded[rowOffset];
    if (filter > 4) {
      throw StateError('$path contains an invalid PNG row filter.');
    }
    final rawRow = decoded.sublist(rowOffset + 1, rowOffset + rowBytes + 1);
    final reconstructedRow = List<int>.filled(rowBytes, 0);
    for (var column = 0; column < rowBytes; column++) {
      final left = column >= bytesPerPixel
          ? reconstructedRow[column - bytesPerPixel]
          : 0;
      final above = previousRow[column];
      final upperLeft = column >= bytesPerPixel
          ? previousRow[column - bytesPerPixel]
          : 0;
      final predictor = switch (filter) {
        0 => 0,
        1 => left,
        2 => above,
        3 => (left + above) >> 1,
        4 => _paeth(left, above, upperLeft),
        _ => throw StateError('$path contains an invalid PNG row filter.'),
      };
      reconstructedRow[column] = (rawRow[column] + predictor) & 0xff;
    }
    previousRow = reconstructedRow;
  }
  return _PngInfo(width: width, height: height);
}

int _paeth(int left, int above, int upperLeft) {
  final estimate = left + above - upperLeft;
  final leftDistance = (estimate - left).abs();
  final aboveDistance = (estimate - above).abs();
  final upperLeftDistance = (estimate - upperLeft).abs();
  if (leftDistance <= aboveDistance && leftDistance <= upperLeftDistance) {
    return left;
  }
  if (aboveDistance <= upperLeftDistance) return above;
  return upperLeft;
}

List<int> _decodeZlib(String path, List<int> compressed) {
  try {
    return ZLibCodec().decode(compressed);
  } on Object catch (error) {
    throw StateError('$path has invalid compressed image data: $error');
  }
}

bool _validBitDepth(int colorType, int bitDepth) {
  return switch (colorType) {
    0 => const [1, 2, 4, 8, 16].contains(bitDepth),
    2 || 4 || 6 => const [8, 16].contains(bitDepth),
    3 => const [1, 2, 4, 8].contains(bitDepth),
    _ => false,
  };
}

_PngDimensions? _expectedDimensions(String path) {
  final fileName = path.split(Platform.pathSeparator).last;
  return switch (fileName) {
    'icon.png' => const _PngDimensions(512, 512),
    '1-home.png' || '4-history.png' => const _PngDimensions(1080, 1920),
    '2-scoring.png' || '3-replay.png' => const _PngDimensions(1920, 1080),
    _ => null,
  };
}

int _readUint32(List<int> bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

bool _sameBytes(List<int> bytes, List<int> expected, int offset) {
  for (var index = 0; index < expected.length; index++) {
    if (bytes[offset + index] != expected[index]) return false;
  }
  return true;
}

class _PngInfo {
  const _PngInfo({required this.width, required this.height});

  final int width;
  final int height;
}

class _PngDimensions {
  const _PngDimensions(this.width, this.height);

  final int width;
  final int height;
}

void _requireFile(String path) {
  if (!File(path).existsSync()) {
    throw StateError('Missing release metadata: $path');
  }
}

String _join(
  String first, [
  String? second,
  String? third,
  String? fourth,
  String? fifth,
  String? sixth,
]) {
  final parts = [
    first,
    second,
    third,
    fourth,
    fifth,
    sixth,
  ].whereType<String>();
  return parts.fold(
    '',
    (path, part) => path.isEmpty ? part : '$path${Platform.pathSeparator}$part',
  );
}
