import 'package:logger/logger.dart';
import '../models/stored_document.dart';
import '../models/parsed_document.dart';

final logger = Logger();

/// Service for analytics and financial metrics aggregation
class AnalyticsService {
  /// Calculate analytics for a time period
  ExpenseAnalytics calculateAnalytics(
    List<StoredDocument> documents, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Filter documents by date range
      final filteredDocs = documents.where((doc) {
        final docDate = doc.transactionDate ?? doc.createdAt;
        return docDate.isAfter(startDate!) && docDate.isBefore(endDate!);
      }).toList();

      if (filteredDocs.isEmpty) {
        return ExpenseAnalytics(
          periodStart: startDate,
          periodEnd: endDate,
          totalSpent: 0,
          averageTransaction: 0,
          transactionCount: 0,
          categoryBreakdown: {},
          vendorFrequency: {},
        );
      }

      // Calculate totals
      final totalSpent = filteredDocs.fold<double>(
        0,
        (sum, doc) => sum + (doc.amount ?? 0),
      );

      final averageTransaction =
          filteredDocs.isEmpty ? 0 : totalSpent / filteredDocs.length;

      // Category breakdown
      final categoryBreakdown = <String, double>{};
      for (final doc in filteredDocs) {
        final amount = doc.amount ?? 0;
        categoryBreakdown[doc.category] =
            (categoryBreakdown[doc.category] ?? 0) + amount;
      }

      // Vendor frequency
      final vendorFrequency = <String, int>{};
      for (final doc in filteredDocs) {
        if (doc.vendor != null) {
          vendorFrequency[doc.vendor!] =
              (vendorFrequency[doc.vendor!] ?? 0) + 1;
        }
      }

      logger.i(
        'Analytics calculated: \$$totalSpent over ${filteredDocs.length} transactions',
      );

      return ExpenseAnalytics(
        periodStart: startDate,
        periodEnd: endDate,
        totalSpent: totalSpent,
        averageTransaction: averageTransaction,
        transactionCount: filteredDocs.length,
        categoryBreakdown: categoryBreakdown,
        vendorFrequency: vendorFrequency,
      );
    } catch (e) {
      logger.e('Analytics calculation failed', error: e);
      rethrow;
    }
  }

  /// Get top spending categories
  List<MapEntry<String, double>> getTopCategories(
    ExpenseAnalytics analytics, {
    int limit = 5,
  }) {
    try {
      final sorted = analytics.categoryBreakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(limit).toList();
    } catch (e) {
      logger.e('Failed to get top categories', error: e);
      return [];
    }
  }

  /// Get top vendors by frequency
  List<MapEntry<String, int>> getTopVendors(
    ExpenseAnalytics analytics, {
    int limit = 5,
  }) {
    try {
      final sorted = analytics.vendorFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(limit).toList();
    } catch (e) {
      logger.e('Failed to get top vendors', error: e);
      return [];
    }
  }

  /// Get daily spending trend
  Map<DateTime, double> getDailyTrend(List<StoredDocument> documents) {
    try {
      final trend = <DateTime, double>{};

      for (final doc in documents) {
        final date = DateTime(
          doc.transactionDate?.year ?? doc.createdAt.year,
          doc.transactionDate?.month ?? doc.createdAt.month,
          doc.transactionDate?.day ?? doc.createdAt.day,
        );

        trend[date] = (trend[date] ?? 0) + (doc.amount ?? 0);
      }

      logger.i('Daily trend calculated for ${trend.length} days');
      return trend;
    } catch (e) {
      logger.e('Failed to calculate daily trend', error: e);
      return {};
    }
  }

  /// Get monthly spending summary
  Map<String, double> getMonthlySummary(List<StoredDocument> documents) {
    try {
      final summary = <String, double>{};

      for (final doc in documents) {
        final date = doc.transactionDate ?? doc.createdAt;
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';

        summary[monthKey] = (summary[monthKey] ?? 0) + (doc.amount ?? 0);
      }

      logger.i('Monthly summary calculated for ${summary.length} months');
      return summary;
    } catch (e) {
      logger.e('Failed to calculate monthly summary', error: e);
      return {};
    }
  }

  /// Get spending comparison between periods
  Map<String, double> comparePeriods(
    List<StoredDocument> documents,
    DateTime period1Start,
    DateTime period1End,
    DateTime period2Start,
    DateTime period2End,
  ) {
    try {
      final period1Docs = documents.where((doc) {
        final date = doc.transactionDate ?? doc.createdAt;
        return date.isAfter(period1Start) && date.isBefore(period1End);
      }).toList();

      final period2Docs = documents.where((doc) {
        final date = doc.transactionDate ?? doc.createdAt;
        return date.isAfter(period2Start) && date.isBefore(period2End);
      }).toList();

      final period1Total = period1Docs.fold<double>(
        0,
        (sum, doc) => sum + (doc.amount ?? 0),
      );

      final period2Total = period2Docs.fold<double>(
        0,
        (sum, doc) => sum + (doc.amount ?? 0),
      );

      final percentageChange = period1Total == 0
          ? 0
          : ((period2Total - period1Total) / period1Total) * 100;

      logger.i(
        'Period comparison: Period 1: \$$period1Total, Period 2: \$$period2Total (${percentageChange.toStringAsFixed(1)}% change)',
      );

      return {
        'period1_total': period1Total,
        'period2_total': period2Total,
        'difference': period2Total - period1Total,
        'percentage_change': percentageChange,
      };
    } catch (e) {
      logger.e('Failed to compare periods', error: e);
      return {};
    }
  }

  /// Calculate category spending trend
  Map<String, Map<String, double>> getCategoryTrend(
    List<StoredDocument> documents,
  ) {
    try {
      final trend = <String, Map<String, double>>{};

      for (final doc in documents) {
        final date = DateTime(
          doc.transactionDate?.year ?? doc.createdAt.year,
          doc.transactionDate?.month ?? doc.createdAt.month,
          doc.transactionDate?.day ?? doc.createdAt.day,
        );

        final dateKey = date.toIso8601String().split('T')[0];

        if (!trend.containsKey(doc.category)) {
          trend[doc.category] = {};
        }

        trend[doc.category]![dateKey] =
            (trend[doc.category]![dateKey] ?? 0) + (doc.amount ?? 0);
      }

      logger.i('Category trend calculated for ${trend.length} categories');
      return trend;
    } catch (e) {
      logger.e('Failed to calculate category trend', error: e);
      return {};
    }
  }
}
