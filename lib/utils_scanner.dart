import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class UtilsScanner {
  UtilsScanner._();

  static Future<CameraDescription> getCamera(
      CameraLensDirection cameraLensDirection) async {
    return await availableCameras().then((value) => value.firstWhere(
          (element) => element.lensDirection == cameraLensDirection,
        ));
  }

  static InputImageRotation rotationIntToInputImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;

      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      default:
        assert(rotation == 270);
        return InputImageRotation.rotation270deg;
    }
  }

  static Uint8List conactenatePlans(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();

    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }

    return allBytes.done().buffer.asUint8List();
  }
}
