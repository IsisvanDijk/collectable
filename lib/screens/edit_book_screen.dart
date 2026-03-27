import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../main.dart';


class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _editionController = TextEditingController();
  final _printRunController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publishYearController = TextEditingController();
  final _signedByController = TextEditingController();
  final _provenanceController = TextEditingController();
  final _notesController = TextEditingController();

  late BookCondition _condition;
  late bool _signed;
  int? _publishYear;
  String? _prefillCoverUrl;
  late List<String> _photoUrls;
  bool _isLoading = false;
  late int _coverIndex;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.book.title;
    _authorController.text = widget.book.author;
    _isbnController.text = widget.book.isbn ?? '';
    _editionController.text = widget.book.edition ?? '';
    _printRunController.text = widget.book.printRun ?? '';
    _publisherController.text = widget.book.publisher ?? '';
    _publishYearController.text = widget.book.publishYear?.toString() ?? '';
    _signedByController.text = widget.book.signedBy ?? '';
    _provenanceController.text = widget.book.provenance ?? '';
    _notesController.text = widget.book.notes ?? '';
    _condition = widget.book.condition;
    _signed = widget.book.signed;
    _publishYear = widget.book.publishYear;
    _photoUrls = List.from(widget.book.photoUrls);
    _prefillCoverUrl = widget.book.coverImageUrl;
    _coverIndex = widget.book.coverPhotoIndex.clamp(
      0,
      widget.book.photoUrls.isEmpty ? 0 : widget.book.photoUrls.length - 1,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _editionController.dispose();
    _printRunController.dispose();
    _publisherController.dispose();
    _publishYearController.dispose();
    _signedByController.dispose();
    _provenanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: kTextColor),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
              const Icon(Icons.photo_library_outlined, color: kTextColor),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${const Uuid().v4()}.jpg';
        final localPath = p.join(appDir.path, 'book_photos', fileName);
        await Directory(p.dirname(localPath)).create(recursive: true);
        await File(image.path).copy(localPath);
        setState(() => _photoUrls.add(localPath));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save photo: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBook(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete book'),
        content: const Text(
            'Are you sure you want to remove this book from your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await BookRepository().delete(widget.book.id);
      if (context.mounted) context.go('/');
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final updated = widget.book.copyWith(
        title: _titleController.text,
        author: _authorController.text,
        isbn: _isbnController.text.isEmpty ? null : _isbnController.text,
        publisher: _publisherController.text.isEmpty
            ? null
            : _publisherController.text,
        publishYear: _publishYear,
        coverImageUrl: _prefillCoverUrl,
        edition: _editionController.text.isEmpty ? null : _editionController.text,
        printRun: _printRunController.text.isEmpty ? null : _printRunController.text,
        condition: _condition,
        signed: _signed,
        signedBy: _signedByController.text.isEmpty ? null : _signedByController.text,
        provenance: _provenanceController.text.isEmpty ? null : _provenanceController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        photoUrls: _photoUrls,
        coverPhotoIndex: _coverIndex,
      );
      await BookRepository().update(updated);
      if (!mounted) return;
      context.go('/book/${widget.book.id}');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Widget _buildPillField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(color: kTextColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kTextColor.withOpacity(0.8)),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(Widget left, Widget right) {
    final isNarrow = MediaQuery.of(context).size.width < 360;
    if (isNarrow) {
      return Column(
        children: [left, const SizedBox(height: 12), right],
      );
    }
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Edit book', showSettings: false, showBack: false),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.book.title,
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                            color: kTextColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildResponsiveRow(
                _buildPillField(
                  controller: _titleController,
                  hint: 'Title',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                _buildPillField(
                  controller: _authorController,
                  hint: 'Author',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 12),

              _buildResponsiveRow(
                _buildPillField(
                  controller: _isbnController,
                  hint: 'ISBN?',
                  keyboardType: TextInputType.number,
                ),
                _buildPillField(
                  controller: _printRunController,
                  hint: 'Print',
                ),
              ),
              const SizedBox(height: 12),

              _buildResponsiveRow(
                _buildPillField(
                  controller: _editionController,
                  hint: 'Edition',
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BookCondition>(
                      value: _condition,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: kTextColor),
                      items: BookCondition.values
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label),
                      ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _condition = value!),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildResponsiveRow(
                _buildPillField(
                  controller: _publisherController,
                  hint: 'Publisher',
                ),
                _buildPillField(
                  controller: _publishYearController,
                  hint: 'Year published',
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      setState(() => _publishYear = int.tryParse(v)),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Signed?',
                        style:
                        TextStyle(color: kTextColor, fontSize: 16)),
                    Switch(
                      value: _signed,
                      onChanged: (v) => setState(() => _signed = v),
                      activeThumbColor: kButtonRed,
                    ),
                  ],
                ),
              ),

              if (_signed) ...[
                const SizedBox(height: 12),
                _buildPillField(
                  controller: _signedByController,
                  hint: 'Signed by...',
                ),
              ],
              const SizedBox(height: 12),

              _buildPillField(
                controller: _provenanceController,
                hint: 'Provenance / where acquired',
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              _buildPillField(
                controller: _notesController,
                hint: 'Notes',
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 116,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._photoUrls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
                      final isCover = index == _coverIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _coverIndex = index),
                        child: Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCover ? kButtonRed : Colors.white,
                                  width: isCover ? 2.5 : 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: path.startsWith('/')
                                    ? Image.file(File(path),
                                    width: 100, height: 100, fit: BoxFit.cover)
                                    : Image.network(path,
                                    width: 100, height: 100, fit: BoxFit.cover),
                              ),
                            ),
                            if (isCover)
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kButtonRed,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Cover',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _photoUrls.removeAt(index);
                                    if (_coverIndex >= _photoUrls.length) {
                                      _coverIndex =
                                          (_photoUrls.length - 1).clamp(0, 999);
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: kTextColor.withOpacity(0.5)),
                            const SizedBox(height: 4),
                            Text('Add photo',
                                style: TextStyle(
                                    color: kTextColor.withOpacity(0.5),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Save to collection',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              GestureDetector(
                onTap: () => _deleteBook(context),
                child: const Text(
                  'Remove book from collection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}