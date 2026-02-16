import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

/// Generates BongoPortus app launcher icons with anti-aliasing via 4x supersampling.
/// Icon: Blue shopping bag with white "B" letter on dark navy background with rounded corners.

void main() async {
  final densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in densities.entries) {
    final dir = entry.key;
    final size = entry.value;
    final png = generateIcon(size);
    final path = 'android/app/src/main/res/$dir/ic_launcher.png';
    final file = File(path);
    await file.writeAsBytes(png);
    print('Generated $path (${size}x$size, ${png.length} bytes)');
  }

  // Also generate a high-res version for store listing
  final hiRes = generateIcon(512);
  await File('assets/icon/app_icon.png').create(recursive: true);
  await File('assets/icon/app_icon.png').writeAsBytes(hiRes);
  print('Generated assets/icon/app_icon.png (512x512, ${hiRes.length} bytes)');

  print('Done! All icons generated.');
}

/// Sample the icon at a specific coordinate (108x108 viewport)
/// Returns [r, g, b, a] as doubles 0-255
List<double> samplePixel(double fx, double fy) {
  const bgR = 0x1E, bgG = 0x3A, bgB = 0x5F;
  const bagR = 0x3B, bagG = 0x82, bagB = 0xF6;
  const whR = 0xFF, whG = 0xFF, whB = 0xFF;

  double r = bgR.toDouble(), g = bgG.toDouble(), b = bgB.toDouble(), a = 255.0;

  // Round icon mask
  if (!_inRoundedRect(fx, fy, 4, 4, 100, 100, 22)) {
    return [0, 0, 0, 0];
  }

  // Shopping bag body
  if (_inRoundedRect(fx, fy, 32, 40, 44, 44, 5)) {
    r = bagR.toDouble();
    g = bagG.toDouble();
    b = bagB.toDouble();
  }

  // Bag handle (arc)
  const hcx = 54.0, hcy = 32.0;
  const hrOuter = 13.0, hrInner = 9.0;
  final ddx = fx - hcx;
  final ddy = fy - hcy;
  final dist = sqrt(ddx * ddx + ddy * ddy);
  if (fy <= 42 &&
      fy >= 20 &&
      dist <= hrOuter &&
      dist >= hrInner &&
      fx >= 41 &&
      fx <= 67) {
    r = bagR.toDouble();
    g = bagG.toDouble();
    b = bagB.toDouble();
  }

  // Handle left stem
  if (fx >= 39 && fx <= 45 && fy >= 30 && fy <= 42) {
    r = bagR.toDouble();
    g = bagG.toDouble();
    b = bagB.toDouble();
  }
  // Handle right stem
  if (fx >= 63 && fx <= 69 && fy >= 30 && fy <= 42) {
    r = bagR.toDouble();
    g = bagG.toDouble();
    b = bagB.toDouble();
  }

  // Letter "B" on the bag
  if (_inRoundedRect(fx, fy, 32, 40, 44, 44, 5)) {
    bool isB = false;

    // Vertical bar
    if (fx >= 44 && fx <= 50 && fy >= 50 && fy <= 74) {
      isB = true;
    }

    // Top horizontal bar
    if (fx >= 44 && fx <= 57 && fy >= 50 && fy <= 55) {
      isB = true;
    }

    // Middle horizontal bar
    if (fx >= 44 && fx <= 58 && fy >= 60 && fy <= 64) {
      isB = true;
    }

    // Bottom horizontal bar
    if (fx >= 44 && fx <= 57 && fy >= 69 && fy <= 74) {
      isB = true;
    }

    // Top bump of B
    const tcx = 56.0, tcy = 57.0, tr = 7.0;
    final tdx = fx - tcx;
    final tdy = fy - tcy;
    if (tdx * tdx + tdy * tdy <= tr * tr && fx >= 50 && fy >= 50 && fy <= 63) {
      isB = true;
    }

    // Bottom bump of B
    const bcx = 57.0, bcy = 67.0, br = 8.0;
    final bdx = fx - bcx;
    final bdy = fy - bcy;
    if (bdx * bdx + bdy * bdy <= br * br && fx >= 50 && fy >= 61 && fy <= 74) {
      isB = true;
    }

    if (isB) {
      r = whR.toDouble();
      g = whG.toDouble();
      b = whB.toDouble();
    }
  }

  return [r, g, b, a];
}

Uint8List generateIcon(int size) {
  final pixels = Uint8List(size * size * 4);
  final scale = size / 108.0;
  const ssCount = 4;
  const ssTotal = ssCount * ssCount;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      double rSum = 0, gSum = 0, bSum = 0, aSum = 0;

      for (int sy = 0; sy < ssCount; sy++) {
        for (int sx = 0; sx < ssCount; sx++) {
          final ffx = (x + (sx + 0.5) / ssCount) / scale;
          final ffy = (y + (sy + 0.5) / ssCount) / scale;
          final sample = samplePixel(ffx, ffy);
          rSum += sample[0];
          gSum += sample[1];
          bSum += sample[2];
          aSum += sample[3];
        }
      }

      final idx = (y * size + x) * 4;
      pixels[idx] = (rSum / ssTotal).round().clamp(0, 255);
      pixels[idx + 1] = (gSum / ssTotal).round().clamp(0, 255);
      pixels[idx + 2] = (bSum / ssTotal).round().clamp(0, 255);
      pixels[idx + 3] = (aSum / ssTotal).round().clamp(0, 255);
    }
  }

  return _encodePng(pixels, size, size);
}

bool _inRoundedRect(double x, double y, double rx, double ry, double w,
    double h, double radius) {
  if (x < rx || x > rx + w || y < ry || y > ry + h) return false;

  if (x < rx + radius && y < ry + radius) {
    final dx = x - (rx + radius);
    final dy = y - (ry + radius);
    return dx * dx + dy * dy <= radius * radius;
  }
  if (x > rx + w - radius && y < ry + radius) {
    final dx = x - (rx + w - radius);
    final dy = y - (ry + radius);
    return dx * dx + dy * dy <= radius * radius;
  }
  if (x < rx + radius && y > ry + h - radius) {
    final dx = x - (rx + radius);
    final dy = y - (ry + h - radius);
    return dx * dx + dy * dy <= radius * radius;
  }
  if (x > rx + w - radius && y > ry + h - radius) {
    final dx = x - (rx + w - radius);
    final dy = y - (ry + h - radius);
    return dx * dx + dy * dy <= radius * radius;
  }

  return true;
}

Uint8List _encodePng(Uint8List rgba, int width, int height) {
  final rawData = <int>[];
  for (int y = 0; y < height; y++) {
    rawData.add(0);
    for (int x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      rawData.add(rgba[idx]);
      rawData.add(rgba[idx + 1]);
      rawData.add(rgba[idx + 2]);
      rawData.add(rgba[idx + 3]);
    }
  }

  final compressed = zlib.encode(rawData);

  final out = BytesBuilder();
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);

  final ihdr = BytesBuilder();
  ihdr.add(_uint32be(width));
  ihdr.add(_uint32be(height));
  ihdr.addByte(8);
  ihdr.addByte(6);
  ihdr.addByte(0);
  ihdr.addByte(0);
  ihdr.addByte(0);
  _writeChunk(out, 'IHDR', ihdr.toBytes());

  _writeChunk(out, 'IDAT', Uint8List.fromList(compressed));

  _writeChunk(out, 'IEND', Uint8List(0));

  return out.toBytes();
}

void _writeChunk(BytesBuilder out, String type, Uint8List data) {
  out.add(_uint32be(data.length));
  final typeBytes = type.codeUnits;
  out.add(typeBytes);
  out.add(data);
  final crcData = <int>[...typeBytes, ...data];
  out.add(_uint32be(_crc32(crcData)));
}

Uint8List _uint32be(int value) {
  return Uint8List.fromList([
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ]);
}

int _crc32(List<int> data) {
  int crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      if (crc & 1 == 1) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
