import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';

class BookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Book>> getAll() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('books')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Book.fromJson(doc.data())).toList());
  }

  Future<void> add(Book book) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');
    final bookWithUser = Book(
      id: book.id,
      userId: userId,
      title: book.title,
      author: book.author,
      isbn: book.isbn,
      edition: book.edition,
      printRun: book.printRun,
      condition: book.condition,
      signed: book.signed,
      notes: book.notes,
      photoUrls: book.photoUrls,
      dateAdded: book.dateAdded,
    );
    await _firestore.collection('books').doc(book.id).set(bookWithUser.toJson());
  }

  Future<void> update(Book book) async {
    await _firestore.collection('books').doc(book.id).update(book.toJson());
  }

  Future<void> delete(String id) async {
    await _firestore.collection('books').doc(id).delete();
  }
}
