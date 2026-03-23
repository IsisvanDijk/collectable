import 'package:cloud_firestore/cloud_firestore.dart';

enum BookCondition { mint, fine, good, fair, poor }

extension BookConditionLabel on BookCondition {
  String get label {
    switch (this) {
      case BookCondition.mint:
        return 'Mint';
      case BookCondition.fine:
        return 'Fine';
      case BookCondition.good:
        return 'Good';
      case BookCondition.fair:
        return 'Fair';
      case BookCondition.poor:
        return 'Poor';
    }
  }
}

class Book {
  final String id;
  final String userId;

  // ── Basic bibliographic info (auto-filled by ISBN scan) ──────────────────
  final String title;
  final String author;
  final String? isbn;
  final String? publisher;
  final int? publishYear;
  final String? coverImageUrl; // from Open Library / Google Books

  // ── Collector-specific fields ─────────────────────────────────────────────
  final String? edition;       // e.g. "1st edition"
  final String? printRun;      // e.g. "3rd printing"
  final BookCondition condition;
  final bool signed;
  final String? signedBy;      // who signed it

  // ── Insurance fields ──────────────────────────────────────────────────────
  final String? provenance;       // herkomst / where/how acquired

  // ── Free-text & media ────────────────────────────────────────────────────
  final String? notes;
  final List<String> photoUrls; // Firebase Storage URLs

  // ── Metadata ─────────────────────────────────────────────────────────────
  final DateTime dateAdded;
  final DateTime? dateUpdated;

  // ── Computed ──────────────────────────────────

  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    this.isbn,
    this.publisher,
    this.publishYear,
    this.coverImageUrl,
    this.edition,
    this.printRun,
    required this.condition,
    required this.signed,
    this.signedBy,
    this.provenance,
    this.notes,
    required this.photoUrls,
    required this.dateAdded,
    this.dateUpdated,
  });

  // ── Firestore serialization ───────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publisher': publisher,
      'publishYear': publishYear,
      'coverImageUrl': coverImageUrl,
      'edition': edition,
      'printRun': printRun,
      'condition': condition.name,
      'signed': signed,
      'signedBy': signedBy,
      'provenance': provenance,
      'notes': notes,
      'photoUrls': photoUrls,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'dateUpdated':
      dateUpdated != null ? Timestamp.fromDate(dateUpdated!) : null,
    };
  }

  factory Book.fromMap(String id, Map<String, dynamic> map) {
    return Book(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      isbn: map['isbn'] as String?,
      publisher: map['publisher'] as String?,
      publishYear: map['publishYear'] as int?,
      coverImageUrl: map['coverImageUrl'] as String?,
      edition: map['edition'] as String?,
      printRun: map['printRun'] as String?,
      condition: BookCondition.values.firstWhere(
            (c) => c.name == (map['condition'] as String? ?? 'good'),
        orElse: () => BookCondition.good,
      ),
      signed: map['signed'] as bool? ?? false,
      signedBy: map['signedBy'] as String?,
      provenance: map['provenance'] as String?,
      notes: map['notes'] as String?,
      photoUrls: List<String>.from(map['photoUrls'] as List? ?? []),
      dateAdded: (map['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateUpdated: (map['dateUpdated'] as Timestamp?)?.toDate(),
    );
  }

  factory Book.fromDocument(DocumentSnapshot doc) {
    return Book.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Book copyWith({
    String? title,
    String? author,
    String? isbn,
    String? publisher,
    int? publishYear,
    String? coverImageUrl,
    String? edition,
    String? printRun,
    BookCondition? condition,
    bool? signed,
    String? signedBy,
    String? provenance,
    String? notes,
    List<String>? photoUrls,
  }) {
    return Book(
      id: id,
      userId: userId,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      edition: edition ?? this.edition,
      printRun: printRun ?? this.printRun,
      condition: condition ?? this.condition,
      signed: signed ?? this.signed,
      signedBy: signedBy ?? this.signedBy,
      provenance: provenance ?? this.provenance,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      dateAdded: dateAdded,
      dateUpdated: DateTime.now(),
    );
  }
}