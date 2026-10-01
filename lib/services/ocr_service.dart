import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_scan_result.dart';
import 'regex_parser_service.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Performs offline text recognition on the given image file using Google ML Kit.
  Future<ReceiptScanResult> processReceiptImage(File imageFile) async {
    _isProcessing = true;
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      debugPrint('[OcrService] Successfully extracted raw text: \n$rawText');

      // Feed recognized text into regex heuristic parser
      final parsedResult = RegexParserService.parseReceiptText(rawText);

      return parsedResult;
    } catch (e, stack) {
      debugPrint('[OcrService] Error processing image with ML Kit: $e\n$stack');
      return ReceiptScanResult(
        rawText: '',
        confidenceScore: 0.0,
        parsingNotes: ['Lỗi nhận diện văn bản: ${e.toString()}'],
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Extracts text from a raw String (useful for unit testing or pasted text)
  ReceiptScanResult processReceiptRawText(String rawText) {
    return RegexParserService.parseReceiptText(rawText);
  }

  /// Releases ML Kit native resources
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
