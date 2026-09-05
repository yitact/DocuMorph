import 'package:logger/logger.dart';
import '../models/stored_document.dart';

final logger = Logger();

/// Service for managing budget thresholds and alerts
class BudgetService {
  static const Map<String, double> _defaultBudgets = {
    'Meals & Dining': 500,
    'Groceries': 400,
    'Travel': 300,
    'Office & Tech': 200,
    'Utilities': 200,
    'Healthcare': 150,
    'Entertainment': 100,
    'Shopping': 250,
    'Transportation': 150,
    'Subscriptions': 100,
    'Other': 100,
  };

  late Map<String, double> _budgets;

  BudgetService() {
    _budgets = Map.from(_defaultBudgets);
  }

  /// Initialize budgets (can load from storage)
  Future<void> initialize(Map<String, double>? customBudgets) async {
    try {
      if (customBudgets != null) {
        _budgets = customBudgets;
      }
      logger.i('BudgetService initialized with ${_budgets.length} budgets');
    } catch (e) {
      logger.e('Failed to initialize BudgetService', error: e);
    }
  }

  /// Set budget for a category
  Future<void> setBudget(String category, double amount) async {
    try {
      _budgets[category] = amount;
      logger.i('Budget set for $category: \$$amount');
    } catch (e) {
      logger.e('Failed to set budget', error: e);
      rethrow;
    }
  }

  /// Get budget for a category
  double getBudget(String category) {
    return _budgets[category] ?? _defaultBudgets[category] ?? 0;
  }

  /// Get all budgets
  Map<String, double> getAllBudgets() {
    return Map.from(_budgets);
  }

  /// Check if spending exceeds budget
  BudgetStatus checkBudgetStatus(
    String category,
    double spent,
  ) {
    try {
      final budget = getBudget(category);

      if (budget == 0) {
        return BudgetStatus(
          category: category,
          budget: budget,
          spent: spent,
          remaining: 0,
          percentageUsed: 100,
          status: BudgetStatusType.noBudget,
        );
      }

      final percentageUsed = (spent / budget) * 100;
      late BudgetStatusType status;

      if (spent > budget) {
        status = BudgetStatusType.exceeded;
      } else if (percentageUsed >= 90) {
        status = BudgetStatusType.critical;
      } else if (percentageUsed >= 75) {
        status = BudgetStatusType.warning;
      } else {
        status = BudgetStatusType.healthy;
      }

      return BudgetStatus(
        category: category,
        budget: budget,
        spent: spent,
        remaining: budget - spent,
        percentageUsed: percentageUsed,
        status: status,
      );
    } catch (e) {
      logger.e('Failed to check budget status', error: e);
      rethrow;
    }
  }

  /// Get budgets by spending across documents
  Map<String, BudgetStatus> getBudgetStatusForPeriod(
    List<StoredDocument> documents, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Group spending by category
      final spending = <String, double>{};

      for (final doc in documents) {
        final docDate = doc.transactionDate ?? doc.createdAt;
        if (docDate.isAfter(startDate) && docDate.isBefore(endDate)) {
          spending[doc.category] =
              (spending[doc.category] ?? 0) + (doc.amount ?? 0);
        }
      }

      // Check status for all categories
      final statuses = <String, BudgetStatus>{};

      for (final category in _budgets.keys) {
        final spent = spending[category] ?? 0;
        statuses[category] = checkBudgetStatus(category, spent);
      }

      logger.i('Budget status calculated for ${statuses.length} categories');
      return statuses;
    } catch (e) {
      logger.e('Failed to get budget status for period', error: e);
      return {};
    }
  }

  /// Get alerts for budgets that are exceeded or critical
  List<BudgetAlert> getBudgetAlerts(
    Map<String, BudgetStatus> budgetStatuses,
  ) {
    try {
      final alerts = <BudgetAlert>[];

      for (final status in budgetStatuses.values) {
        if (status.status == BudgetStatusType.exceeded) {
          alerts.add(
            BudgetAlert(
              category: status.category,
              message:
                  '${status.category} budget exceeded by \$${(status.spent - status.budget).toStringAsFixed(2)}',
              severity: AlertSeverity.critical,
              percentageOverBudget: status.percentageUsed - 100,
            ),
          );
        } else if (status.status == BudgetStatusType.critical) {
          alerts.add(
            BudgetAlert(
              category: status.category,
              message:
                  '${status.category} at ${status.percentageUsed.toStringAsFixed(1)}% of budget',
              severity: AlertSeverity.warning,
              percentageOverBudget: 0,
            ),
          );
        }
      }

      logger.i('Generated ${alerts.length} budget alerts');
      return alerts;
    } catch (e) {
      logger.e('Failed to get budget alerts', error: e);
      return [];
    }
  }

  /// Estimate remaining budget for month
  double estimateRemainingBudget(
    String category,
    double spent,
    int daysIntoMonth,
  ) {
    try {
      if (daysIntoMonth == 0) return getBudget(category);

      final budget = getBudget(category);
      final dailyBudget = budget / 30;
      final projectedSpend = (spent / daysIntoMonth) * 30;
      final remaining = budget - projectedSpend;

      return max(remaining, 0);
    } catch (e) {
      logger.e('Failed to estimate remaining budget', error: e);
      return 0;
    }
  }

  /// Reset budgets to defaults
  Future<void> resetToDefaults() async {
    try {
      _budgets = Map.from(_defaultBudgets);
      logger.i('Budgets reset to defaults');
    } catch (e) {
      logger.e('Failed to reset budgets', error: e);
      rethrow;
    }
  }

  double max(double a, double b) => a > b ? a : b;
}

/// Budget status information
class BudgetStatus {
  final String category;
  final double budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final BudgetStatusType status;

  BudgetStatus({
    required this.category,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.status,
  });

  @override
  String toString() =>
      'BudgetStatus($category: \$$spent/\$$budget - ${status.name})';
}

/// Budget alert
class BudgetAlert {
  final String category;
  final String message;
  final AlertSeverity severity;
  final double percentageOverBudget;

  BudgetAlert({
    required this.category,
    required this.message,
    required this.severity,
    required this.percentageOverBudget,
  });

  @override
  String toString() => 'BudgetAlert($category: $message)';
}

/// Budget status type enum
enum BudgetStatusType {
  healthy,
  warning,
  critical,
  exceeded,
  noBudget,
}

/// Alert severity enum
enum AlertSeverity {
  info,
  warning,
  critical,
}
