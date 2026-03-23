enum BookCondition {
  mint,
  nearMint,
  veryGood,
  good,
  fair,
  poor,
}

class Book {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String? isbn;
  final String? edition;
  final String? printRun;
  final BookCondition condition;
  final bool signed;
  final String? notes;
  final List<String> photoUrls;
  final DateTime dateAdded;

  Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    this.isbn,
    this.edition,
    this.printRun,
    required this.condition,
    this.signed = false,
    this.notes,
    required this.photoUrls,
    required this.dateAdded,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      author: json['author'],
      isbn: json['isbn'],
      edition: json['edition'],
      printRun: json['printRun'],
      condition: BookCondition.values[json['condition']],
      signed: json['signed'] ?? false,
      notes: json['notes'],
      photoUrls: List<String>.from(json['photoUrls']),
      dateAdded: DateTime.parse(json['dateAdded']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'edition': edition,
      'printRun': printRun,
      'condition': condition.index,
      'signed': signed,
      'notes': notes,
      'photoUrls': photoUrls,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }
}
