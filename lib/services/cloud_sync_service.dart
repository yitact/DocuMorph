import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import '../models/stored_document.dart';
import 'encryption_service.dart';

final logger = Logger();

/// Service for cloud synchronization with Firebase
class CloudSyncService {
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;
  late EncryptionService _encryptionService;
  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Initialize cloud sync service
  Future<void> initialize(EncryptionService encryptionService) async {
    try {
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _encryptionService = encryptionService;
      _isInitialized = true;
      logger.i('CloudSyncService initialized');
    } catch (e) {
      logger.e('Failed to initialize CloudSyncService', error: e);
      rethrow;
    }
  }

  /// Sync document to cloud with encryption
  Future<String> syncDocumentToCloud(
    StoredDocument document,
    String userId,
  ) async {
    try {
      _checkInitialized();

      if (_isSyncing) {
        logger.w('Sync already in progress');
        return '';
      }

      _isSyncing = true;

      // Prepare encrypted data
      final docJson = {
        'id': document.id,
        'title': document.title,
        'vendor': document.vendor,
        'amount': document.amount,
        'category': document.category,
        'ocrText': document.ocrText,
        'parsedData': document.parsedJsonData,
        'transactionDate': document.transactionDate?.toIso8601String(),
        'createdAt': document.createdAt.toIso8601String(),
        'tags': document.tags,
      };

      final encryptedData = _encryptionService.encryptJson(docJson);

      // Upload to Firestore
      final docRef =
          _firestore.collection('users').doc(userId).collection('documents');

      final result = await docRef.add({
        'encryptedData': encryptedData,
        'documentId': document.id,
        'syncedAt': FieldValue.serverTimestamp(),
        'isEncrypted': true,
      });

      final cloudSyncId = result.id;

      logger.i('Document synced to cloud: $cloudSyncId');
      _isSyncing = false;

      return cloudSyncId;
    } catch (e) {
      logger.e('Failed to sync document to cloud', error: e);
      _isSyncing = false;
      rethrow;
    }
  }

  /// Download document from cloud
  Future<StoredDocument?> downloadDocumentFromCloud(
    String userId,
    String cloudSyncId,
  ) async {
    try {
      _checkInitialized();

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc(cloudSyncId);

      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        logger.w('Document not found in cloud: $cloudSyncId');
        return null;
      }

      final data = docSnapshot.data();
      final encryptedData = data?['encryptedData'] as String?;

      if (encryptedData == null) {
        logger.e('No encrypted data in cloud document');
        return null;
      }

      // Decrypt data
      final decryptedJson = _encryptionService.decryptJson(encryptedData);

      // Reconstruct document
      final document = StoredDocument(
        id: decryptedJson['id'],
        title: decryptedJson['title'],
        documentType: 'receipt',
        imagePath: '',
        ocrText: decryptedJson['ocrText'] ?? '',
        vendor: decryptedJson['vendor'],
        amount: decryptedJson['amount']?.toDouble(),
        category: decryptedJson['category'] ?? 'Other',
        parsedJsonData: decryptedJson['parsedData'],
        tags: List<String>.from(decryptedJson['tags'] ?? []),
      );

      logger.i('Document downloaded from cloud: $cloudSyncId');
      return document;
    } catch (e) {
      logger.e('Failed to download document from cloud', error: e);
      rethrow;
    }
  }

  /// Sync all documents to cloud
  Future<List<String>> syncAllDocumentsToCloud(
    List<StoredDocument> documents,
    String userId,
  ) async {
    try {
      _checkInitialized();

      final syncedIds = <String>[];

      for (final doc in documents) {
        try {
          final cloudId = await syncDocumentToCloud(doc, userId);
          if (cloudId.isNotEmpty) {
            syncedIds.add(cloudId);
          }
        } catch (e) {
          logger.w('Failed to sync individual document: ${doc.id}');
        }
      }

      logger.i('Synced ${syncedIds.length}/${documents.length} documents to cloud');
      return syncedIds;
    } catch (e) {
      logger.e('Failed to sync all documents to cloud', error: e);
      rethrow;
    }
  }

  /// Get sync status
  Future<SyncStatus> getSyncStatus(String userId) async {
    try {
      _checkInitialized();

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('documents');

      final snapshot = await collection.get();

      logger.i('Sync status: ${snapshot.docs.length} documents synced');

      return SyncStatus(
        isSyncing: _isSyncing,
        documentsSynced: snapshot.docs.length,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      logger.e('Failed to get sync status', error: e);
      rethrow;
    }
  }

  /// Delete document from cloud
  Future<void> deleteDocumentFromCloud(
    String userId,
    String cloudSyncId,
  ) async {
    try {
      _checkInitialized();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc(cloudSyncId)
          .delete();

      logger.i('Document deleted from cloud: $cloudSyncId');
    } catch (e) {
      logger.e('Failed to delete document from cloud', error: e);
      rethrow;
    }
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception(
        'CloudSyncService not initialized. Call initialize() first.',
      );
    }
  }

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;
}

/// Cloud sync status model
class SyncStatus {
  final bool isSyncing;
  final int documentsSynced;
  final DateTime lastSyncTime;

  SyncStatus({
    required this.isSyncing,
    required this.documentsSynced,
    required this.lastSyncTime,
  });

  @override
  String toString() =>
      'SyncStatus(syncing: $isSyncing, docs: $documentsSynced, lastSync: $lastSyncTime)';
}
