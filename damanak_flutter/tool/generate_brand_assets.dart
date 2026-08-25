import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as image;

void main() {
  final root = Directory.current;
  final sourceFile = File(
    '${root.path}/assets/branding/damanak_app_icon_generated.png',
  );
  if (!sourceFile.existsSync()) {
    throw StateError('Missing generated icon: ${sourceFile.path}');
  }

  final decoded = image.decodePng(sourceFile.readAsBytesSync());
  if (decoded == null) throw StateError('Unable to decode generated icon.');

  final side = math.min(decoded.width, decoded.height);
  final square = image.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final master = _flattenIcon(
    image.copyResize(
      square,
      width: 1024,
      height: 1024,
      interpolation: image.Interpolation.average,
    ),
  );
  _writePng(
    File('${root.path}/assets/branding/damanak_app_icon_master.png'),
    master,
  );

  const iosIcons = <String, int>{
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };
  final iosIconDirectory = Directory(
    '${root.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset',
  );
  for (final entry in iosIcons.entries) {
    _writePng(
      File('${iosIconDirectory.path}/${entry.key}'),
      image.copyResize(
        master,
        width: entry.value,
        height: entry.value,
        interpolation: image.Interpolation.average,
      ),
    );
  }

  const androidIcons = <String, int>{
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  for (final entry in androidIcons.entries) {
    _writePng(
      File(
        '${root.path}/android/app/src/main/res/'
        'mipmap-${entry.key}/ic_launcher.png',
      ),
      image.copyResize(
        master,
        width: entry.value,
        height: entry.value,
        interpolation: image.Interpolation.average,
      ),
    );
  }

  final launchDirectory = Directory(
    '${root.path}/ios/Runner/Assets.xcassets/LaunchImage.imageset',
  );
  for (final entry in const <String, int>{
    'LaunchImage.png': 64,
    'LaunchImage@2x.png': 128,
    'LaunchImage@3x.png': 192,
  }.entries) {
    _writePng(
      File('${launchDirectory.path}/${entry.key}'),
      _createTransparentLaunchMark(master, entry.value),
    );
  }

  for (final entry in const <String, int>{
    'mdpi': 64,
    'hdpi': 96,
    'xhdpi': 128,
    'xxhdpi': 192,
    'xxxhdpi': 256,
  }.entries) {
    _writePng(
      File(
        '${root.path}/android/app/src/main/res/'
        'drawable-${entry.key}/launch_mark.png',
      ),
      _createTransparentLaunchMark(master, entry.value),
    );
  }
}

image.Image _flattenIcon(image.Image source) {
  final output = image.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final luminance =
          (0.2126 * pixel.rNormalized) +
          (0.7152 * pixel.gNormalized) +
          (0.0722 * pixel.bNormalized);
      final mix = ((luminance - 0.54) / 0.28).clamp(0.0, 1.0);
      output.setPixelRgb(
        x,
        y,
        8 + ((247 - 8) * mix).round(),
        127 + ((244 - 127) * mix).round(),
        91 + ((234 - 91) * mix).round(),
      );
    }
  }
  return output;
}

image.Image _createTransparentLaunchMark(image.Image source, int size) {
  final scaled = image.copyResize(
    source,
    width: size,
    height: size,
    interpolation: image.Interpolation.average,
  );
  final output = image.Image(width: size, height: size, numChannels: 4);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final pixel = scaled.getPixel(x, y);
      final luminance =
          (0.2126 * pixel.rNormalized) +
          (0.7152 * pixel.gNormalized) +
          (0.0722 * pixel.bNormalized);
      final alpha = (((luminance - 0.53) / 0.24) * 255).round().clamp(0, 255);
      output.setPixelRgba(x, y, 247, 244, 234, alpha);
    }
  }
  return output;
}

void _writePng(File file, image.Image value) {
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(image.encodePng(value, level: 9));
}
