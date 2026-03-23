import 'dart:convert';
import 'package:http/http.dart' as http;

class BookLookupService {
  Future<Map<String, dynamic>> lookup(String isbn) async {
    // 1. Try Open Library first
    try {
      final olResult = await _fetchOpenLibrary(isbn);
      if (olResult.isNotEmpty) return olResult;
    } catch (_) {}

    // 2. Fall back to Google Books
    try {
      final gbResult = await _fetchGoogleBooks(isbn);
      if (gbResult.isNotEmpty) return gbResult;
    } catch (_) {}

    return {};
  }

  Future<Map<String, dynamic>> _fetchOpenLibrary(String isbn) async {
    final response = await http
        .get(Uri.parse('https://openlibrary.org/isbn/$isbn.json'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Get author name — data has author keys, need to fetch each
    String author = '';
    final authors = data['authors'] as List?;
    if (authors != null && authors.isNotEmpty) {
      final authorKey = (authors.first as Map)['key'] as String?;
      if (authorKey != null) {
        try {
          final authorRes = await http
              .get(Uri.parse('https://openlibrary.org$authorKey.json'))
              .timeout(const Duration(seconds: 5));
          if (authorRes.statusCode == 200) {
            final authorData = jsonDecode(authorRes.body);
            author = authorData['name'] as String? ?? '';
          }
        } catch (_) {}
      }
    }

    // Cover image
    String? coverUrl;
    final covers = data['covers'] as List?;
    if (covers != null && covers.isNotEmpty) {
      coverUrl = 'https://covers.openlibrary.org/b/id/${covers.first}-L.jpg';
    }

    // Publish year — parse from publish_date string e.g. "2001" or "January 2001"
    int? publishYear;
    final publishDate = data['publish_date'] as String?;
    if (publishDate != null) {
      final match = RegExp(r'\d{4}').firstMatch(publishDate);
      if (match != null) publishYear = int.tryParse(match.group(0)!);
    }

    final title = data['title'] as String? ?? '';
    if (title.isEmpty) return {};

    return {
      'title': title,
      'author': author,
      'publisher': (data['publishers'] as List?)?.first as String? ?? '',
      'publishYear': publishYear,
      'coverImageUrl': coverUrl,
    };
  }

  Future<Map<String, dynamic>> _fetchGoogleBooks(String isbn) async {
    final response = await http
        .get(Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List?;
    if (items == null || items.isEmpty) return {};

    final info = (items.first as Map)['volumeInfo'] as Map<String, dynamic>?;
    if (info == null) return {};

    final title = info['title'] as String? ?? '';
    if (title.isEmpty) return {};

    // Google Books gives full date like "2001-09-11" — take year only
    int? publishYear;
    final publishedDate = info['publishedDate'] as String?;
    if (publishedDate != null && publishedDate.length >= 4) {
      publishYear = int.tryParse(publishedDate.substring(0, 4));
    }

    // Thumbnail — replace http with https and remove zoom parameter
    String? coverUrl;
    final imageLinks = info['imageLinks'] as Map?;
    if (imageLinks != null) {
      coverUrl = (imageLinks['thumbnail'] as String?)
          ?.replaceFirst('http://', 'https://')
          .replaceAll('&zoom=1', '');
    }

    return {
      'title': title,
      'author': (info['authors'] as List?)?.first as String? ?? '',
      'publisher': info['publisher'] as String? ?? '',
      'publishYear': publishYear,
      'coverImageUrl': coverUrl,
    };
  }
}