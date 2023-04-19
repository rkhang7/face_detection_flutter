import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_detection/camera_view.dart';
import 'package:face_detection/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  File? _imageFile;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Face Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
      initialDirection: CameraLensDirection.front,
    );
  }

  Future<void> processImage(
    InputImage inputImage,
  ) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      final Rect boundingBox = faces.first.boundingBox;
      final ui.Image image = await loadImageFromFile(imageFile);
      final ui.Image croppedImage = await cropImage(image, boundingBox);
      Get.offAll(Home());
      faces.clear();
    }
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<ui.Image> loadImageFromFile(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<ui.Image> cropImage(ui.Image image, Rect rect) async {
    final ui.Image croppedImage = await ui
        .instantiateImageCodec(
          await image.toByteData(format: ui.ImageByteFormat.png),
        )
        .then((codec) => codec.getNextFrame())
        .then(
          (frame) => frame.image
              .cloneCrop(rect)
              .toByteData(format: ui.ImageByteFormat.png),
        )
        .then((byteData) => ui.decodeImage(byteData.buffer.asUint8List()));

    return croppedImage;
  }
}
