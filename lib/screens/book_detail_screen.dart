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

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final photos = book.photoUrls;
    final hasPhotos = photos.isNotEmpty;
    final coverUrl = book.coverImageUrl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Details', showSettings: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                book.title,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/book/${book.id}/edit', extra: book),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                        color: kTextColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Large cover image ─────────────────────────────────────────
          if (hasPhotos) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    return _buildImage(photos[index]);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Dot indicators ────────────────────────────────────────
            if (photos.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (index) {
                  final isActive = index == _currentPage;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? kButtonRed
                            : kTextColor.withOpacity(0.2),
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
                height: 320,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              ),
            ),
          ] else ...[
            _imagePlaceholder(),
          ],

          const SizedBox(height: 20),

          // ── Author ────────────────────────────────────────────────────
          Text(
            book.author,
            style: const TextStyle(
              color: kButtonRed,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // ── Labeled fields ────────────────────────────────────────────
          if (book.edition != null) ...[
            _LabeledField(label: 'Edition', value: book.edition!),
            const SizedBox(height: 10),
          ],
          if (book.printRun != null) ...[
            _LabeledField(label: 'Print', value: book.printRun!),
            const SizedBox(height: 10),
          ],
          _LabeledField(label: 'Condition', value: book.condition.label),
          const SizedBox(height: 10),
          if (book.publisher != null) ...[
            _LabeledField(label: 'Publisher', value: book.publisher!),
            const SizedBox(height: 10),
          ],
          if (book.publishYear != null) ...[
            _LabeledField(
                label: 'Year', value: book.publishYear.toString()),
            const SizedBox(height: 10),
          ],
          if (book.isbn != null) ...[
            _LabeledField(label: 'ISBN', value: book.isbn!),
            const SizedBox(height: 10),
          ],
          _LabeledField(
            label: 'Signed',
            value: book.signed
                ? (book.signedBy != null ? 'Yes — by ${book.signedBy}' : 'Yes')
                : 'No',
          ),
          const SizedBox(height: 20),

          // ── Provenance ────────────────────────────────────────────────
          if (book.provenance != null && book.provenance!.isNotEmpty) ...[
            _SectionLabel(label: 'Provenance'),
            const SizedBox(height: 6),
            _InfoBox(text: book.provenance!),
            const SizedBox(height: 16),
          ],

          // ── Notes ─────────────────────────────────────────────────────
          if (book.notes != null && book.notes!.isNotEmpty) ...[
            _SectionLabel(label: 'Notes'),
            const SizedBox(height: 6),
            _InfoBox(text: book.notes!),
            const SizedBox(height: 16),
          ],

          // ── Dates ─────────────────────────────────────────────────────
          Text(
            'Added ${_formatDate(book.dateAdded)}',
            style: TextStyle(
              color: kTextColor.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          if (book.dateUpdated != null)
            Text(
              'Last edited ${_formatDate(book.dateUpdated!)}',
              style: TextStyle(
                color: kTextColor.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('/')) {
      return Image.file(
        File(path),
        width: double.infinity,
        height: 320,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return Image.network(
      path,
      width: double.infinity,
      height: 320,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 320,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final String label;
  final String value;
  const _LabeledField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: kTextColor.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: kTextColor.withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: kTextColor, fontSize: 14, height: 1.5),
      ),
    );
  }
}