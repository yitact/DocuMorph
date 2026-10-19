import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/stored_document.dart';
import '../services/document_store.dart';

/// Library of previously scanned documents, backed by [DocumentStore].
///
/// Supports full-text search, viewing a document's OCR text, copy/share,
/// and deletion.
class SavedDocumentsScreen extends StatefulWidget {
  final DocumentStore store;

  const SavedDocumentsScreen({super.key, required this.store});

  @override
  State<SavedDocumentsScreen> createState() => _SavedDocumentsScreenState();
}

class _SavedDocumentsScreenState extends State<SavedDocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<StoredDocument>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _documentsFuture = widget.store.loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    setState(() {
      _documentsFuture = widget.store.search(query);
    });
  }

  void _refresh() {
    setState(() {
      _documentsFuture = _searchController.text.isEmpty
          ? widget.store.loadAll()
          : widget.store.search(_searchController.text);
    });
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> _confirmDelete(StoredDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.store.delete(doc.id);
      _refresh();
    }
  }

  void _openDocument(StoredDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedDocumentDetailScreen(document: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Documents')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('library_search_field'),
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search saved documents…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _runSearch,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StoredDocument>>(
              future: _documentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data ?? const <StoredDocument>[];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No saved documents yet.\nScans you run will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return ListTile(
                      key: Key('saved_doc_${doc.id}'),
                      title: Text(
                        doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatDate(doc.createdAt)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(doc),
                      ),
                      onTap: () => _openDocument(doc),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only view of one saved document's extracted text, with copy/share.
class SavedDocumentDetailScreen extends StatelessWidget {
  final StoredDocument document;

  const SavedDocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Text',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: document.ocrText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Text copied to clipboard!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              Share.share(
                document.ocrText,
                subject: 'Digitized Document Content',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          document.ocrText.isEmpty
              ? 'No text was extracted from this document.'
              : document.ocrText,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}
