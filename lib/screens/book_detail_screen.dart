import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../main.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Book?>(
      stream: BookRepository().watchById(bookId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final book = snapshot.data;
        if (book == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: buildAppBar(context, title: 'Details', showSettings: false),
            body: const Center(child: Text('Book not found')),
          );
        }
        return _BookDetailView(book: book);
      },
    );
  }
}

class _BookDetailView extends StatefulWidget {
  final Book book;
  const _BookDetailView({required this.book});

  @override
  State<_BookDetailView> createState() => _BookDetailViewState();
}

class _BookDetailViewState extends State<_BookDetailView> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.coverPhotoIndex.clamp(
      0,
      widget.book.photoUrls.isEmpty ? 0 : widget.book.photoUrls.length - 1,
    );
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // IntrinsicHeight makes both pills in a row share the same height.
  Widget _buildResponsiveRow(Widget left, Widget right, {double breakpoint = 300}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 12), right],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration get _pillDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.3),
    borderRadius: BorderRadius.circular(40),
    border: Border.all(color: Colors.white, width: 1.5),
  );

  Widget _buildPillDisplay({required String label, required String? value}) {
    final displayValue = (value == null || value.isEmpty) ? '—' : value;
    return Container(
      decoration: _pillDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      // Column layout: label top-left, value bottom-right.
      // The value now has the full pill width available, so Flutter can wrap
      // at word boundaries instead of breaking words mid-character.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: kTextColor.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displayValue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final photos = book.photoUrls;
    final hasPhotos = photos.isNotEmpty;
    final coverUrl = book.coverImageUrl;

    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = (screenHeight * 0.38).clamp(200.0, 360.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Details', showSettings: false, showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  book.title,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push('/book/${book.id}/edit', extra: book),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: kTextColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (hasPhotos) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: imageHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) => _buildImage(photos[index], imageHeight),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (photos.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (index) {
                  final isActive = index == _currentPage;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? kButtonRed : kTextColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
          ] else if (coverUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                coverUrl,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(imageHeight),
              ),
            ),
          ] else ...[
            _imagePlaceholder(imageHeight),
          ],

          const SizedBox(height: 20),

          Text(
            book.author,
            style: const TextStyle(
              color: kButtonRed,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          _buildResponsiveRow(
            _buildPillDisplay(label: 'Edition', value: book.edition),
            _buildPillDisplay(label: 'Print', value: book.printRun),
          ),
          const SizedBox(height: 12),

          _buildResponsiveRow(
            _buildPillDisplay(label: 'Publisher', value: book.publisher),
            _buildPillDisplay(label: 'Year', value: book.publishYear?.toString()),
          ),
          const SizedBox(height: 12),

          _buildResponsiveRow(
            _buildPillDisplay(label: 'Condition', value: book.condition.label),
            _buildPillDisplay(label: 'Signed', value: book.signed ? 'Yes' : 'No'),
          ),
          const SizedBox(height: 12),

          _buildPillDisplay(label: 'ISBN', value: book.isbn),
          const SizedBox(height: 12),

          if (book.provenance != null && book.provenance!.isNotEmpty) ...[
            _buildPillDisplay(label: 'Provenance', value: book.provenance),
            const SizedBox(height: 12),
          ],

          if (book.notes != null && book.notes!.isNotEmpty)
            _buildPillDisplay(label: 'Notes', value: book.notes),
        ],
      ),
    );
  }

  Widget _buildImage(String path, double height) {
    if (path.startsWith('/')) {
      return Image.file(
        File(path),
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(height),
      );
    }
    return Image.network(
      path,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(height),
    );
  }

  Widget _imagePlaceholder(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 64,
          color: kTextColor.withOpacity(0.25),
        ),
      ),
    );
  }
}