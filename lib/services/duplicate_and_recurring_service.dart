import 'package:logger/logger.dart';
import '../models/stored_document.dart';

final logger = Logger();

/// Service for detecting duplicate receipts and recurring subscriptions
class DuplicateAndRecurringService {
  static const double _hashSimilarityThreshold = 0.85; // 85% similarity
  static const int _daysBetweenRecurring = 25; // 25-35 days = monthly pattern

  /// Detect if a document is a duplicate of existing documents
  bool isDuplicate(
    StoredDocument newDoc,
    List<StoredDocument> existingDocs, {
    bool checkAmount = true,
    bool checkVendor = true,
    bool checkDate = true,
  }) {
    try {
      for (final existing in existingDocs) {
        if (_isSimilar(
          newDoc,
          existing,
          checkAmount: checkAmount,
          checkVendor: checkVendor,
          checkDate: checkDate,
        )) {
          logger.w('Duplicate detected: ${newDoc.id} similar to ${existing.id}');
          return true;
        }
      }
      return false;
    } catch (e) {
      logger.e('Duplicate detection failed', error: e);
      return false;
    }
  }

  /// Calculate similarity between two documents
  double calculateSimilarity(
    StoredDocument doc1,
    StoredDocument doc2,
  ) {
    try {
      var score = 0.0;
      var maxScore = 0.0;

      // Vendor similarity (weight: 0.3)
      if (doc1.vendor != null && doc2.vendor != null) {
        final vendorSim =
            _stringSimilarity(doc1.vendor!, doc2.vendor!) * 0.3;
        score += vendorSim;
      }
      maxScore += 0.3;

      // Amount similarity (weight: 0.4)
      if (doc1.amount != null && doc2.amount != null) {
        final amountDiff =
            (doc1.amount! - doc2.amount!).abs() / doc1.amount!;
        final amountSim = (1 - amountDiff.clamp(0, 1)) * 0.4;
        score += amountSim;
      }
      maxScore += 0.4;

      // OCR text similarity (weight: 0.3)
      final textSim = _stringSimilarity(doc1.ocrText, doc2.ocrText) * 0.3;
      score += textSim;
      maxScore += 0.3;

      final finalScore = maxScore > 0 ? score / maxScore : 0;
      return finalScore;
    } catch (e) {
      logger.e('Similarity calculation failed', error: e);
      return 0;
    }
  }

  /// Detect recurring subscriptions
  List<RecurringExpense> detectRecurringExpenses(
    List<StoredDocument> documents, {
    int minOccurrences = 3,
  }) {
    try {
      // Group by vendor and amount
      final grouped = <String, List<StoredDocument>>{};

      for (final doc in documents) {
        if (doc.vendor != null && doc.amount != null) {
          final key = '${doc.vendor}_${doc.amount}';
          grouped.putIfAbsent(key, () => []).add(doc);
        }
      }

      final recurring = <RecurringExpense>[];

      for (final entry in grouped.entries) {
        final docs = entry.value;

        if (docs.length >= minOccurrences) {
          // Check if dates are evenly spaced
          final sortedDocs =
              docs..sort((a, b) => a.transactionDate?.compareTo(b.transactionDate ?? b.createdAt) ?? 0);
          
          final intervals = <int>[];
          for (var i = 1; i < sortedDocs.length; i++) {
            final date1 = sortedDocs[i - 1].transactionDate ?? sortedDocs[i - 1].createdAt;
            final date2 = sortedDocs[i].transactionDate ?? sortedDocs[i].createdAt;
            intervals.add(date2.difference(date1).inDays);
          }

          // Calculate average interval
          if (intervals.isNotEmpty) {
            final avgInterval =
                intervals.reduce((a, b) => a + b) / intervals.length;

            // Check if reasonably consistent (within 10 days variance)
            final isConsistent = intervals.every((interval) =>
                (interval - avgInterval).abs() <= 10);

            if (isConsistent && avgInterval.toInt() >= _daysBetweenRecurring) {
              recurring.add(
                RecurringExpense(
                  vendor: sortedDocs.first.vendor!,
                  amount: sortedDocs.first.amount!,
                  occurrences: docs.length,
                  averageIntervalDays: avgInterval.toInt(),
                  lastOccurrence: sortedDocs.last.transactionDate ??
                      sortedDocs.last.createdAt,
                  category: sortedDocs.first.category,
                  confidence: _calculateConfidence(intervals, avgInterval),
                ),
              );
              
              logger.i(
                'Recurring subscription detected: ${sortedDocs.first.vendor} every ${avgInterval.toStringAsFixed(0)} days',
              );
            }
          }
        }
      }

      return recurring;
    } catch (e) {
      logger.e('Recurring detection failed', error: e);
      return [];
    }
  }

  /// Find potential duplicates
  List<DuplicateMatch> findPotentialDuplicates(
    List<StoredDocument> documents, {
    double threshold = _hashSimilarityThreshold,
  }) {
    try {
      final matches = <DuplicateMatch>[];

      for (var i = 0; i < documents.length; i++) {
        for (var j = i + 1; j < documents.length; j++) {
          final similarity =
              calculateSimilarity(documents[i], documents[j]);

          if (similarity >= threshold) {
            matches.add(
              DuplicateMatch(
                doc1Id: documents[i].id,
                doc2Id: documents[j].id,
                vendor: documents[i].vendor,
                amount: documents[i].amount,
                similarity: similarity,
              ),
            );
          }
        }
      }

      logger.i('Found ${matches.length} potential duplicates');
      return matches;
    } catch (e) {
      logger.e('Duplicate finding failed', error: e);
      return [];
    }
  }

  /// Calculate string similarity using Jaro-Winkler distance
  double _stringSimilarity(String s1, String s2) {
    final s1Lower = s1.toLowerCase();
    final s2Lower = s2.toLowerCase();

    if (s1Lower == s2Lower) return 1.0;
    if (s1Lower.isEmpty || s2Lower.isEmpty) return 0.0;

    // Simple substring match for efficiency
    if (s1Lower.contains(s2Lower) || s2Lower.contains(s1Lower)) {
      return 0.9;
    }

    // Levenshtein distance
    final distance = _levenshteinDistance(s1Lower, s2Lower);
    final maxLength = max(s1Lower.length, s2Lower.length);

    return 1 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance
  int _levenshteinDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;
    final dp = List<List<int>>.generate(
      m + 1,
      (i) => List<int>.generate(n + 1, (j) => 0),
    );

    for (var i = 0; i <= m; i++) dp[i][0] = i;
    for (var j = 0; j <= n; j++) dp[0][j] = j;

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] =
              1 + min(dp[i - 1][j], min(dp[i][j - 1], dp[i - 1][j - 1]));
        }
      }
    }

    return dp[m][n];
  }

  /// Check if two documents are similar
  bool _isSimilar(
    StoredDocument doc1,
    StoredDocument doc2, {
    required bool checkAmount,
    required bool checkVendor,
    required bool checkDate,
  }) {
    var checks = 0;
    var passedChecks = 0;

    // Vendor check
    if (checkVendor && doc1.vendor != null && doc2.vendor != null) {
      checks++;
      if (_stringSimilarity(doc1.vendor!, doc2.vendor!) > 0.85) {
        passedChecks++;
      }
    }

    // Amount check
    if (checkAmount && doc1.amount != null && doc2.amount != null) {
      checks++;
      final amountDiff =
          (doc1.amount! - doc2.amount!).abs() / doc1.amount!;
      if (amountDiff < 0.05) {
        // Within 5%
        passedChecks++;
      }
    }

    // Date check (within 3 days)
    if (checkDate &&
        doc1.transactionDate != null &&
        doc2.transactionDate != null) {
      checks++;
      final daysDiff =
          doc1.transactionDate!.difference(doc2.transactionDate!).inDays;
      if (daysDiff.abs() <= 3) {
        passedChecks++;
      }
    }

    return checks > 0 && (passedChecks / checks) > 0.7;
  }

  /// Calculate confidence score for recurring detection
  double _calculateConfidence(List<int> intervals, double avgInterval) {
    if (intervals.isEmpty) return 0;

    final variance = intervals
        .map((i) => (i - avgInterval).abs())
        .reduce((a, b) => a + b) /
        intervals.length;

    // Confidence decreases with variance
    return (1 - (variance / avgInterval * 0.2)).clamp(0, 1);
  }

  /// Helper min function
  int min(int a, int b) => a < b ? a : b;
  int max(int a, int b) => a > b ? a : b;
}

/// Model for recurring expense
class RecurringExpense {
  final String vendor;
  final double amount;
  final int occurrences;
  final int averageIntervalDays;
  final DateTime lastOccurrence;
  final String category;
  final double confidence;

  RecurringExpense({
    required this.vendor,
    required this.amount,
    required this.occurrences,
    required this.averageIntervalDays,
    required this.lastOccurrence,
    required this.category,
    required this.confidence,
  });

  /// Estimate next occurrence
  DateTime getNextExpectedDate() {
    return lastOccurrence.add(Duration(days: averageIntervalDays));
  }

  /// Calculate estimated yearly cost
  double getEstimatedYearlyCost() {
    return (amount * 365 / averageIntervalDays);
  }

  @override
  String toString() =>
      'RecurringExpense($vendor, \$$amount, every $averageIntervalDays days)';
}

/// Model for duplicate match
class DuplicateMatch {
  final String doc1Id;
  final String doc2Id;
  final String? vendor;
  final double? amount;
  final double similarity;

  DuplicateMatch({
    required this.doc1Id,
    required this.doc2Id,
    this.vendor,
    this.amount,
    required this.similarity,
  });

  @override
  String toString() =>
      'DuplicateMatch($vendor \$$amount, ${(similarity * 100).toStringAsFixed(1)}% match)';
}
