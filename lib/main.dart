import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DocumentScannerApp(ocrService: MlKitOcrService()));
}

abstract class OcrService {
  Future<String> recognizeText(File imageFile);
  void dispose();
}

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

class DocumentScannerApp extends StatelessWidget {
  final OcrService ocrService;

  const DocumentScannerApp({super.key, required this.ocrService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocuMorph',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: ScannerHomePage(ocrService: ocrService),
    );
  }
}

class ScannerHomePage extends StatefulWidget {
  final OcrService ocrService;

  const ScannerHomePage({super.key, required this.ocrService});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  File? _imageFile;
  String _extractedText = '';
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    widget.ocrService.dispose();
    super.dispose();
  }

  Future<void> _processImageFile(File file) async {
    setState(() {
      _imageFile = file;
      _isProcessing = true;
      _extractedText = '';
    });

    try {
      final text = await widget.ocrService.recognizeText(file);
      setState(() {
        _extractedText = text.isEmpty ? 'No readable text detected.' : text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning document: $e')),
        );
      }
    }
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        await _processImageFile(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to acquire image: $e')),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_extractedText.isEmpty ||
        _extractedText == 'No readable text detected.') return;
    Clipboard.setData(ClipboardData(text: _extractedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Extracted text copied to clipboard!')),
    );
  }

  void _shareDigitalText() {
    if (_extractedText.isEmpty ||
        _extractedText == 'No readable text detected.') return;
    Share.share(
      _extractedText,
      subject: 'Digitized Document Content',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidText = _extractedText.isNotEmpty &&
        _extractedText != 'No readable text detected.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocuMorph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About & Legal',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'DocuMorph',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.document_scanner,
                    size: 40, color: Colors.indigo),
                applicationLegalese:
                    '© 2026 Samuel. All rights reserved.\nBuilt by Samuel with the help of AI.',
                children: const [
                  SizedBox(height: 16),
                  Text(
                    'DocuMorph transforms physical documents into actionable digital text and structured media. Designed and developed by Samuel with AI co-engineering assistance.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              );
            },
          ),
          if (hasValidText) ...[
            IconButton(
              key: const Key('copy_button'),
              icon: const Icon(Icons.copy),
              tooltip: 'Copy Text',
              onPressed: _copyToClipboard,
            ),
            IconButton(
              key: const Key('share_button'),
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: _shareDigitalText,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Text(
                        'No document captured yet.\nUse the buttons below to start.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('scan_camera_btn'),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcessImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('import_media_btn'),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Import Media'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcessImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Digital Output (Editable)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_isProcessing)
                  const SizedBox(
                    key: Key('loading_indicator'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                _extractedText.isEmpty
                    ? (_isProcessing
                        ? 'Processing document with on-device OCR...'
                        : 'Scanned text will appear here.')
                    : _extractedText,
                key: const Key('ocr_output_text'),
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                '© 2026 Samuel • Built with the help of AI',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
