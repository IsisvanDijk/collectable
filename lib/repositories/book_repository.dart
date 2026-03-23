import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';

class BookRepository {
  final _firestore = FirebaseFirestore.instance;

  // Always scope to the current user's UID.
  // This is the fix for the userId: '' bug in the original code.
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('books');

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Live stream of all books for the current user, newest first.
  Stream<List<Book>> getAll() {
    return _collection
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Book.fromDocument(d)).toList());
  }

  /// Single book by ID (one-time fetch, not a stream).
  Future<Book?> getById(String bookId) async {
    final doc = await _collection.doc(bookId).get();
    if (!doc.exists) return null;
    return Book.fromDocument(doc);
  }

  /// Live stream of a single book (used on the detail screen).
  Stream<Book?> watchById(String bookId) {
    return _collection.doc(bookId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Book.fromDocument(doc);
    });
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Add a new book. The userId is always set from FirebaseAuth here,
  /// so callers never need to pass it in.
  Future<void> add(Book book) async {
    final bookWithUser = Book(
      id: book.id,
      userId: _uid,
      title: book.title,
      author: book.author,
      isbn: book.isbn,
      publisher: book.publisher,
      publishYear: book.publishYear,
      coverImageUrl: book.coverImageUrl,
      edition: book.edition,
      printRun: book.printRun,
      condition: book.condition,
      signed: book.signed,
      signedBy: book.signedBy,
      provenance: book.provenance,
      notes: book.notes,
      photoUrls: book.photoUrls,
      dateAdded: book.dateAdded,
      dateUpdated: book.dateUpdated,
    );

    // Schrijf zonder te wachten op server-bevestiging
    _collection.doc(book.id).set(bookWithUser.toMap());
  }

  /// Update an existing book (partial update via copyWith is handled by caller).
  Future<void> update(Book book) async {
    await _collection.doc(book.id).update({
      ...book.toMap(),
      'dateUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a book by ID.
  Future<void> delete(String bookId) async {
    await _collection.doc(bookId).delete();
  }

  // ── Helpers for Export ────────────────────────────────────────────────────

  /// Fetch a specific list of books by their IDs (used by export screen
  /// to get only selected books in one go).
  Future<List<Book>> getByIds(List<String> bookIds) async {
    if (bookIds.isEmpty) return [];

    // Firestore 'whereIn' supports max 30 items — chunk if needed.
    final chunks = <List<String>>[];
    for (var i = 0; i < bookIds.length; i += 30) {
      chunks.add(bookIds.sublist(
          i, i + 30 > bookIds.length ? bookIds.length : i + 30));
    }

    final results = <Book>[];
    for (final chunk in chunks) {
      final snap =
      await _collection.where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(snap.docs.map((d) => Book.fromDocument(d)));
    }
    return results;
  }

  Future<List<Book>> getAllBooks() async {
    final snap = await _collection.get();
    return snap.docs.map((d) => Book.fromDocument(d)).toList();
  }
}
