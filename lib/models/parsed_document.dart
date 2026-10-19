import 'dart:convert';

/// A single line item extracted from a receipt or invoice.
class LineItem {
  final String description;
  final double quantity;
  final double price;

  const LineItem({
    required this.description,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'price': price,
      };

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      description: json['description']?.toString() ?? '',
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toDouble()
          : 1.0,
      price: json['price'] is num ? (json['price'] as num).toDouble() : 0.0,
    );
  }
}

/// Structured data extracted from a document (receipt/invoice) by a parser.
///
/// This is the model `analytics_service.dart` originally imported; it was
/// missing from the repo, which broke compilation. Fields follow the design
/// in the project notes (vendor / date / invoiceNumber / subtotal / tax /
/// total / items).
class ParsedDocument {
  final String vendor;
  final String date;
  final String invoiceNumber;
  final double subtotal;
  final double tax;
  final double total;
  final List<LineItem> items;

  const ParsedDocument({
    required this.vendor,
    required this.date,
    required this.invoiceNumber,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'vendor': vendor,
        'date': date,
        'invoiceNumber': invoiceNumber,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory ParsedDocument.fromJson(Map<String, dynamic> json) {
    return ParsedDocument(
      vendor: json['vendor']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      subtotal:
          json['subtotal'] is num ? (json['subtotal'] as num).toDouble() : 0.0,
      tax: json['tax'] is num ? (json['tax'] as num).toDouble() : 0.0,
      total: json['total'] is num ? (json['total'] as num).toDouble() : 0.0,
      items: json['items'] is List
          ? (json['items'] as List)
              .whereType<Map>()
              .map((e) => LineItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  String toPrettyJson() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  /// Simple CSV export (header row + one row per line item).
  String toCsv() {
    String esc(dynamic v) {
      final s = v.toString();
      return s.contains(',') || s.contains('"')
          ? '"${s.replaceAll('"', '""')}"'
          : s;
    }

    final rows = <String>[
      'Vendor,Invoice #,Date,Subtotal,Tax,Total',
      [vendor, invoiceNumber, date, subtotal, tax, total].map(esc).join(','),
      '',
      'Item Description,Quantity,Price (USD)',
      ...items.map(
        (item) => [item.description, item.quantity, item.price]
            .map(esc)
            .join(','),
      ),
    ];
    return rows.join('\n');
  }
}

/// Aggregated expense metrics for a period, produced by AnalyticsService.
class ExpenseAnalytics {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalSpent;
  final double averageTransaction;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;
  final Map<String, int> vendorFrequency;

  const ExpenseAnalytics({
    required this.periodStart,
    required this.periodEnd,
    required this.totalSpent,
    required this.averageTransaction,
    required this.transactionCount,
    required this.categoryBreakdown,
    required this.vendorFrequency,
  });

  Map<String, dynamic> toJson() => {
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'totalSpent': totalSpent,
        'averageTransaction': averageTransaction,
        'transactionCount': transactionCount,
        'categoryBreakdown': categoryBreakdown,
        'vendorFrequency': vendorFrequency,
      };
}
