//
// Copyright (c) 2026 Samuel. All rights reserved.
// Developed by Samuel with AI assistance.
//

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_service.dart';

class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final RecognizedText recognizedText =
        await _recognizer.processImage(inputImage);
    return recognizedText.text.trim();
  }

  @override
  void dispose() {
    _recognizer.close();
  }
}
