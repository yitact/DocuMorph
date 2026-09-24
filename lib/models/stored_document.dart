class StoredDocument {
  final String id;
  final String title;
  final String documentType;
  final String imagePath;
  final String ocrText;
  final String? vendor;
  final double? amount;
  final String category;
  final Map<String, dynamic>? parsedJsonData;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? transactionDate;

  StoredDocument({
    required this.id,
    required this.title,
    this.documentType = 'receipt',
    this.imagePath = '',
    this.ocrText = '',
    this.vendor,
    this.amount,
    this.category = 'Other',
    this.parsedJsonData,
    List<String>? tags,
    DateTime? createdAt,
    this.transactionDate,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? const [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'documentType': documentType,
      'imagePath': imagePath,
      'ocrText': ocrText,
      'vendor': vendor,
      'amount': amount,
      'category': category,
      'parsedJsonData': parsedJsonData,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'transactionDate': transactionDate?.toIso8601String(),
    };
  }

  factory StoredDocument.fromJson(Map<String, dynamic> json) {
    return StoredDocument(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      documentType: json['documentType']?.toString() ?? 'receipt',
      imagePath: json['imagePath']?.toString() ?? '',
      ocrText: json['ocrText']?.toString() ?? '',
      vendor: json['vendor']?.toString(),
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : null,
      category: json['category']?.toString() ?? 'Other',
      parsedJsonData: json['parsedJsonData'] is Map<String, dynamic>
          ? json['parsedJsonData'] as Map<String, dynamic>
          : (json['parsedJsonData'] is Map ? Map<String, dynamic>.from(json['parsedJsonData'] as Map) : null),
      tags: json['tags'] is List ? List<String>.from(json['tags']) : const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      transactionDate: json['transactionDate'] != null
          ? DateTime.tryParse(json['transactionDate'].toString())
          : null,
    );
  }
}
