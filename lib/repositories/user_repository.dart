import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  Future<AppUser?> getUser() async {
    try {
      final doc = await _userDoc.get();
      if (!doc.exists) return null;
      return AppUser.fromDocument(doc);
    } catch (_) {
      return null;
    }
  }

  Stream<AppUser?> watchUser() {
    return _userDoc.snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDocument(doc);
    });
  }

  Future<void> saveUser({
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    // Use set+merge so createdAt is only written on first save
    await _userDoc.set({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> updateName({
    required String? firstName,
    required String? lastName,
  }) async {
    // Use set+merge instead of update() so it works even if the doc doesn't exist yet
     _userDoc.set({
      'firstName': firstName,
      'lastName': lastName,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
}