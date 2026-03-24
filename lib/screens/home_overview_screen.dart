import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/book_repository.dart';
import '../models/book.dart';
import '../main.dart';

enum BookFilter { all, signed, firstEdition, condition }

class HomeOverviewScreen extends StatefulWidget {
  const HomeOverviewScreen({super.key});

  @override
  State<HomeOverviewScreen> createState() => _HomeOverviewScreenState();
}

class _HomeOverviewScreenState extends State<HomeOverviewScreen> {
  final _bookRepo = BookRepository();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  BookFilter _activeFilter = BookFilter.all;
  BookCondition? _conditionFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  String get username {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    return (name != null && name.isNotEmpty) ? name : 'there';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _applyFilters(List<Book> books) {
    List<Book> filtered = books.where((book) {
      final query = _searchQuery.toLowerCase();
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          (book.isbn?.toLowerCase().contains(query) ?? false);
    }).toList();

    switch (_activeFilter) {
      case BookFilter.all:
        break;
      case BookFilter.signed:
        filtered = filtered.where((book) => book.signed).toList();
        break;
      case BookFilter.firstEdition:
        filtered = filtered.where((book) {
          final edition = book.edition?.toLowerCase() ?? '';
          final printRun = book.printRun?.toLowerCase() ?? '';
          return edition.contains('1st') || edition.contains('first') ||
              printRun.contains('1st') || printRun.contains('first');
        }).toList();
        break;
      case BookFilter.condition:
        if (_conditionFilter != null) {
          filtered = filtered.where((book) => book.condition == _conditionFilter).toList();
        }
        break;
    }

    return filtered;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: kTextColor),
          decoration: InputDecoration(
            hintText: 'Search by title, author, or ISBN',
            hintStyle: TextStyle(color: kTextColor.withOpacity(0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            prefixIcon: const Icon(Icons.search, color: kTextColor),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _activeFilter == BookFilter.all, () {
              setState(() {
                _activeFilter = BookFilter.all;
                _conditionFilter = null;
              });
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Signed', _activeFilter == BookFilter.signed, () {
              setState(() {
                _activeFilter = BookFilter.signed;
                _conditionFilter = null;
              });
            }),
            const SizedBox(width: 8),
            _buildFilterChip('1st ed', _activeFilter == BookFilter.firstEdition, () {
              setState(() {
                _activeFilter = BookFilter.firstEdition;
                _conditionFilter = null;
              });
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Condition', _activeFilter == BookFilter.condition, () async {
              final condition = await showModalBottomSheet<BookCondition>(
                context: context,
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: BookCondition.values.map((cond) {
                        return ListTile(
                          title: Text(cond.label),
                          onTap: () => Navigator.of(context).pop(cond),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
              if (condition != null) {
                setState(() {
                  _conditionFilter = condition;
                  _activeFilter = BookFilter.condition;
                });
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kButtonRed : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Hello, $username!'),
      body: StreamBuilder<List<Book>>(
        stream: _bookRepo.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final books = snapshot.data ?? [];
          final filteredBooks = _applyFilters(books);
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Empty-shelf.png',
                    width: 220,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your collection is empty',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start by adding your first book!',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Column(
              children: [
                _buildSearchBar(),
                _buildFilterChips(),
                if (filteredBooks.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No books match your search',
                        style: TextStyle(color: kTextColor, fontSize: 16),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        return _BookCard(book: book);
                      },
                    ),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/book/${book.id}'),
      child: Card(
        color: Colors.white.withOpacity(0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildCoverImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                book.title,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
              child: _buildBadges(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    String? imageUrl;
    if (book.photoUrls.isNotEmpty) {
      imageUrl = book.photoUrls.first;
    } else if (book.coverImageUrl != null) {
      imageUrl = book.coverImageUrl;
    }

    if (imageUrl == null) {
      return Container(
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Icon(Icons.menu_book_outlined, size: 50, color: Colors.grey),
      );
    }

    // Local file path → FileImage, remote URL → NetworkImage
    final isLocal = imageUrl.startsWith('/') || imageUrl.startsWith('file://');

    return Image(
      image: isLocal ? FileImage(File(imageUrl.replaceFirst('file://', ''))) as ImageProvider
                     : NetworkImage(imageUrl),
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Icon(Icons.menu_book_outlined, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildBadges() {
    List<Widget> badges = [];
    if (book.signed) {
      badges.add(_buildBadge('Signed'));
    }
    return Row(
      children: badges,
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kButtonRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}