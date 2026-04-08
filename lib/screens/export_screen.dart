import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../repositories/user_repository.dart';
import '../main.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGenerating = false;
  final UserRepository _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _applySearch(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    final query = _searchQuery.toLowerCase();
    return books.where((book) {
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          (book.isbn?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _selectAll(List<Book> books) {
    setState(() {
      _selectedIds.addAll(books.map((b) => b.id));
    });
  }

  void _clearAll() {
    setState(() => _selectedIds.clear());
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            prefixIcon: const Icon(Icons.search, color: kTextColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.close, color: kTextColor.withOpacity(0.5)),
              onPressed: () => _searchController.clear(),
            )
                : null,
          ),
        ),
      ),
    );
  }

  Future<pw.ImageProvider?> _loadImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportPdf(List<Book> allBooks) async {
    final selected =
    allBooks.where((b) => _selectedIds.contains(b.id)).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one book to export')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final appUser = await _userRepo.getUser();
      
      // Use first name + last name, fallback to displayName, then email
      final ownerName = appUser?.fullName.isNotEmpty == true
          ? appUser!.fullName
          : (user?.displayName ?? user?.email ?? 'Unknown');
      
      final exportDate =
          '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';
      const footer = 'Made with Collectable';

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.notoSansRegular(),
          bold: await PdfGoogleFonts.notoSansBold(),
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Book Collection',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Insurance documentation',
                style: const pw.TextStyle(
                    fontSize: 16, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Owner: $ownerName',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text('Date of export: $exportDate',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text('Total books: ${selected.length}',
                  style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );

      for (final book in selected) {
        final urls = book.photoUrls;
        final coverIdx =
        urls.isEmpty ? 0 : book.coverPhotoIndex.clamp(0, urls.length - 1);

        pw.ImageProvider? coverImage;
        if (urls.isNotEmpty) {
          coverImage = await _loadImage(urls[coverIdx]);
        }

        final List<pw.ImageProvider> extraImages = [];
        for (int i = 0; i < urls.length; i++) {
          if (i == coverIdx) continue;
          final img = await _loadImage(urls[i]);
          if (img != null) extraImages.add(img);
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  book.title,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  book.author,
                  style: const pw.TextStyle(
                      fontSize: 14, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (coverImage != null)
                      pw.Container(
                        width: 140,
                        height: 180,
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(coverImage, fit: pw.BoxFit.cover),
                        ),
                      )
                    else
                      pw.Container(
                        width: 140,
                        height: 180,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text('No photo',
                              style: const pw.TextStyle(
                                  color: PdfColors.grey500)),
                        ),
                      ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfField('Condition', book.condition.label),
                          if (book.edition != null)
                            _pdfField('Edition', book.edition!),
                          if (book.printRun != null)
                            _pdfField('Print run', book.printRun!),
                          if (book.publisher != null)
                            _pdfField('Publisher', book.publisher!),
                          if (book.publishYear != null)
                            _pdfField('Year', book.publishYear.toString()),
                          if (book.isbn != null)
                            _pdfField('ISBN', book.isbn!),
                          _pdfField(
                            'Signed',
                            book.signed
                                ? (book.signedBy != null
                                ? 'Yes \u2014 ${book.signedBy}'
                                : 'Yes')
                                : 'No',
                          ),
                          if (book.provenance != null &&
                              book.provenance!.isNotEmpty)
                            _pdfField('Provenance', book.provenance!),
                        ],
                      ),
                    ),
                  ],
                ),
                if (book.notes != null && book.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text('Notes',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 4),
                  pw.Text(book.notes!,
                      style: const pw.TextStyle(fontSize: 12)),
                ],
                pw.Spacer(),
                pw.Divider(),
                pw.Text(
                  footer,
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey500),
                ),
              ],
            ),
          ),
        );

        if (extraImages.isNotEmpty) {
          const imagesPerPage = 4;
          for (int pageStart = 0;
          pageStart < extraImages.length;
          pageStart += imagesPerPage) {
            final pageImages = extraImages.sublist(
              pageStart,
              (pageStart + imagesPerPage).clamp(0, extraImages.length),
            );

            final rows = <pw.Widget>[];
            for (int i = 0; i < pageImages.length; i += 2) {
              final left = pageImages[i];
              final right =
              i + 1 < pageImages.length ? pageImages[i + 1] : null;
              rows.add(
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        height: 340,
                        child: pw.ClipRRect(
                          horizontalRadius: 6,
                          verticalRadius: 6,
                          child: pw.Image(left, fit: pw.BoxFit.cover),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: right != null
                          ? pw.Container(
                        height: 340,
                        child: pw.ClipRRect(
                          horizontalRadius: 6,
                          verticalRadius: 6,
                          child: pw.Image(right, fit: pw.BoxFit.cover),
                        ),
                      )
                          : pw.SizedBox(),
                    ),
                  ],
                ),
              );
              if (i + 2 < pageImages.length) rows.add(pw.SizedBox(height: 12));
            }

            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                margin: const pw.EdgeInsets.all(40),
                build: (pw.Context ctx) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${book.title} \u2014 Additional photos',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                    pw.SizedBox(height: 16),
                    ...rows,
                    pw.Spacer(),
                    pw.Divider(),
                    pw.Text(
                      footer,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'collectable-export-$exportDate.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  pw.Widget _pdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Export'),
      body: StreamBuilder<List<Book>>(
        stream: BookRepository().getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return Center(
              child: Text(
                'No books in your collection yet',
                style: TextStyle(
                  color: kTextColor.withOpacity(0.6),
                  fontSize: 15,
                ),
              ),
            );
          }

          final filteredBooks = _applySearch(books);

          return Column(
            children: [
              _buildSearchBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    _ActionChip(
                      label: 'Select all',
                      filled: true,
                      onTap: () => _selectAll(filteredBooks),
                    ),
                    const SizedBox(width: 10),
                    _ActionChip(
                      label: 'Clear',
                      filled: false,
                      onTap: _clearAll,
                    ),
                    const Spacer(),
                    if (_selectedIds.isNotEmpty)
                      Text(
                        '${_selectedIds.length} selected',
                        style: TextStyle(
                          color: kTextColor.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (filteredBooks.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No books match your search',
                      style: TextStyle(
                        color: kTextColor.withOpacity(0.6),
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      final isSelected = _selectedIds.contains(book.id);
                      return _BookExportTile(
                        book: book,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(book.id);
                            } else {
                              _selectedIds.add(book.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isGenerating || _selectedIds.isEmpty)
                        ? null
                        : () => _exportPdf(books),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonRed,
                      disabledBackgroundColor: kButtonRed.withOpacity(0.4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: _isGenerating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      _selectedIds.isEmpty
                          ? 'Export to PDF'
                          : 'Export ${_selectedIds.length} book${_selectedIds.length == 1 ? '' : 's'} to PDF',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookExportTile extends StatelessWidget {
  final Book book;
  final bool isSelected;
  final VoidCallback onTap;

  const _BookExportTile({
    required this.book,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = book.photoUrls.isNotEmpty
        ? book.photoUrls[
    book.coverPhotoIndex.clamp(0, book.photoUrls.length - 1)]
        : book.coverImageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? kButtonRed : Colors.white,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: _buildThumbnail(imageUrl),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                book.title,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? kButtonRed : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                  isSelected ? kButtonRed : kTextColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? path) {
    if (path == null) {
      return Container(
        color: const Color(0xFFF0EAE0),
        child: Icon(Icons.menu_book_outlined,
            size: 22, color: kTextColor.withOpacity(0.3)),
      );
    }
    if (path.startsWith('/')) {
      return Image.file(File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFF0EAE0),
            child: Icon(Icons.menu_book_outlined,
                size: 22, color: kTextColor.withOpacity(0.3)),
          ));
    }
    return Image.network(path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFF0EAE0),
          child: Icon(Icons.menu_book_outlined,
              size: 22, color: kTextColor.withOpacity(0.3)),
        ));
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? kButtonRed : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: filled ? kButtonRed : Colors.white,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : kTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}