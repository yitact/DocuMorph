//
// Copyright (c) 2026 Samuel. All rights reserved.
// Developed by Samuel with AI assistance.
//

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:documorph/main.dart';

class MockOcrService implements OcrService {
  final String stubbedText;
  final Duration delay;

  MockOcrService({
    this.stubbedText = 'Invoice #1042\nTotal Due: \$450.00',
    this.delay = Duration.zero,
  });

  @override
  Future<String> recognizeText(File imageFile) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return stubbedText;
  }

  @override
  void dispose() {}
}

void main() {
  testWidgets('Initial UI renders placeholder and scan triggers',
      (WidgetTester tester) async {
    final mockService = MockOcrService();

    await tester.pumpWidget(DocumentScannerApp(ocrService: mockService));

    expect(find.text('DocuMorph'), findsWidgets);
    expect(find.text('No document captured yet.\nUse the buttons below to start.'),
        findsOneWidget);
    expect(find.text('Scanned text will appear here.'), findsOneWidget);
    expect(find.byKey(const Key('scan_camera_btn')), findsOneWidget);
    expect(find.byKey(const Key('import_media_btn')), findsOneWidget);

    expect(find.byKey(const Key('copy_button')), findsNothing);
    expect(find.byKey(const Key('share_button')), findsNothing);
  });

  testWidgets('Loading indicator displays during processing',
      (WidgetTester tester) async {
    final mockService = MockOcrService(delay: const Duration(seconds: 2));

    await tester.pumpWidget(DocumentScannerApp(ocrService: mockService));

    expect(find.byKey(const Key('loading_indicator')), findsNothing);
  });
}
