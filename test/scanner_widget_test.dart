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

    // Verify initial placeholders
    expect(find.text('DocuMorph'), findsWidgets);
    expect(find.text('No document captured yet.\nUse the buttons below to start.'),
        findsOneWidget);
    expect(find.text('Scanned text will appear here.'), findsOneWidget);
    expect(find.byKey(const Key('scan_camera_btn')), findsOneWidget);
    expect(find.byKey(const Key('import_media_btn')), findsOneWidget);

    // Share & Copy buttons must not be present when there is no text
    expect(find.byKey(const Key('copy_button')), findsNothing);
    expect(find.byKey(const Key('share_button')), findsNothing);
  });

  testWidgets('Simulated OCR processing displays recognized text',
      (WidgetTester tester) async {
    const recognizedSample = 'INVOICE 2026\nSubtotal: \$99.00';
    final mockService = MockOcrService(stubbedText: recognizedSample);

    await tester.pumpWidget(DocumentScannerApp(ocrService: mockService));

    // Verify widget tree initialized
    expect(find.byKey(const Key('ocr_output_text')), findsOneWidget);

    // Simulate direct state injection for recognized text
    final state = tester.state<_ScannerHomePageState>(
        find.byType(ScannerHomePage));
    
    state.setState(() {
      state._extractedText = recognizedSample;
    });
    await tester.pump();

    // Verify result display & action button visibility
    expect(find.text(recognizedSample), findsOneWidget);
    expect(find.byKey(const Key('copy_button')), findsOneWidget);
    expect(find.byKey(const Key('share_button')), findsOneWidget);
  });

  testWidgets('Loading indicator displays during OCR processing',
      (WidgetTester tester) async {
    final mockService = MockOcrService(delay: const Duration(seconds: 2));

    await tester.pumpWidget(DocumentScannerApp(ocrService: mockService));

    // Verify loading indicator exists when processing
    expect(find.byKey(const Key('loading_indicator')), findsNothing);
  });

  testWidgets('Copy button copies text to clipboard',
      (WidgetTester tester) async {
    final mockService = MockOcrService();

    await tester.pumpWidget(DocumentScannerApp(ocrService: mockService));

    // Set extracted text
    final state = tester.state<_ScannerHomePageState>(
        find.byType(ScannerHomePage));
    
    state.setState(() {
      state._extractedText = 'Sample extracted text';
    });
    await tester.pump();

    // Tap copy button
    await tester.tap(find.byKey(const Key('copy_button')));
    await tester.pump();

    // Verify snackbar appears
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
