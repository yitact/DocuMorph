//
// Copyright (c) 2026 Samuel. All rights reserved.
// Developed by Samuel with AI assistance.
//

import 'dart:io';

abstract class OcrService {
  Future<String> recognizeText(File imageFile);
  void dispose();
}
