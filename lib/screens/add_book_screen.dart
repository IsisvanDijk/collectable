import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../services/book_lookup_service.dart';
import '../main.dart';

const kButtonPink = Color(0xFFE6C5CA);

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;
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

  // condition starts null so we can detect "not chosen yet"
  BookCondition? _condition;
  bool _conditionError = false;

  bool _signed = false;
  int? _publishYear;
  String? _prefillCoverUrl;
  List<String> _photoUrls = [];
  bool _isLoading = false;
  bool _isManual = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _scannerController.dispose();
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

  void _resetForm() {
    _titleController.clear();
    _authorController.clear();
    _isbnController.clear();
    _editionController.clear();
    _printRunController.clear();
    _publisherController.clear();
    _publishYearController.clear();
    _signedByController.clear();
    _provenanceController.clear();
    _notesController.clear();
    setState(() {
      _condition = null;
      _conditionError = false;
      _signed = false;
      _publishYear = null;
      _prefillCoverUrl = null;
      _photoUrls = [];
      _isLoading = false;
      _isManual = true;
      _hasScanned = false;
    });
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
              leading: const Icon(Icons.photo_library_outlined, color: kTextColor),
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
      } catch (e, stackTrace) {
        print('=== PHOTO ERROR: $e');
        print(stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save photo: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasScanned || _isLoading) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null) return;
    if (value.length != 13 && value.length != 10) return;

    _hasScanned = true;
    try { _scannerController.stop(); } catch (_) {}
    setState(() => _isLoading = true);

    final result = await BookLookupService().lookup(value);

    if (result.isNotEmpty) {
      _titleController.text = result['title'] ?? '';
      _authorController.text = result['author'] ?? '';
      _publisherController.text = result['publisher'] ?? '';
      _isbnController.text = value;
      if (result['publishYear'] != null) {
        _publishYear = result['publishYear'];
        _publishYearController.text = result['publishYear'].toString();
      }
      if (result['coverImageUrl'] != null) {
        _prefillCoverUrl = result['coverImageUrl'];
      }
    } else {
      // Pre-fill the ISBN even when the lookup fails, so the user
      // doesn't have to type it again in the manual form.
      _isbnController.text = value;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No book found — please fill in manually')),
        );
      }
    }

    setState(() {
      _isManual = true;
      _isLoading = false;
    });
  }

  Future<void> _saveBook() async {
    // Validate the Form fields (title, author, year)
    final formValid = _formKey.currentState!.validate();

    // Validate condition separately (it's a dropdown, not a TextFormField)
    final conditionValid = _condition != null;
    setState(() => _conditionError = !conditionValid);

    if (!formValid || !conditionValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final book = Book(
        id: const Uuid().v4(),
        userId: '',
        title: _titleController.text,
        author: _authorController.text,
        isbn: _isbnController.text.isEmpty ? null : _isbnController.text,
        publisher: _publisherController.text.isEmpty ? null : _publisherController.text,
        publishYear: _publishYear,
        coverImageUrl: _prefillCoverUrl,
        coverPhotoIndex: 0,
        edition: _editionController.text.isEmpty ? null : _editionController.text,
        printRun: _printRunController.text.isEmpty ? null : _printRunController.text,
        condition: _condition!,
        signed: _signed,
        signedBy: _signedByController.text.isEmpty ? null : _signedByController.text,
        provenance: _provenanceController.text.isEmpty ? null : _provenanceController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        photoUrls: _photoUrls,
        dateAdded: DateTime.now(),
      );
      BookRepository().add(book);
      if (!mounted) return;
      _resetForm();
      if (mounted) context.push('/book/${book.id}');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save book: $e'),
            backgroundColor: Color(0xFFf44336),
          ),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildToggleBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _scannerController.dispose();
              setState(() {
                _scannerController = MobileScannerController();
                _isManual = false;
                _hasScanned = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !_isManual ? kButtonPink : Colors.white,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(40)),
              ),
              child: Text(
                'Scan ISBN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: !_isManual ? kButtonRed : kTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              try { _scannerController.stop(); } catch (_) {}
              setState(() => _isManual = true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isManual ? kButtonPink : Colors.white,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(40)),
              ),
              child: Text(
                'Manual entry',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isManual ? kButtonRed : kTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
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
    final scanSize = (MediaQuery.of(context).size.width * 0.6).clamp(200.0, 300.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Add book'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _buildToggleBar(),
              const SizedBox(height: 24),

              if (_isManual) ...[
                _buildResponsiveRow(
                  _buildPillField(
                    controller: _titleController,
                    hint: 'Title *',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  _buildPillField(
                    controller: _authorController,
                    hint: 'Author *',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 12),
                _buildResponsiveRow(
                  _buildPillField(
                    controller: _isbnController,
                    hint: 'ISBN',
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
                  // Condition dropdown with inline error indication
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: _conditionError ? Colors.red : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<BookCondition>(
                            value: _condition,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: kTextColor),
                            hint: Text(
                              'Condition *',
                              style: TextStyle(
                                color: _conditionError
                                    ? Colors.red
                                    : kTextColor.withOpacity(0.8),
                              ),
                            ),
                            items: BookCondition.values
                                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                                .toList(),
                            onChanged: (value) => setState(() {
                              _condition = value;
                              _conditionError = false;
                            }),
                          ),
                        ),
                      ),
                      if (_conditionError)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Text(
                            'Required',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
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
                    hint: 'Year *',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final year = int.tryParse(v.trim());
                      if (year == null) return 'Invalid year';
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _publishYear = int.tryParse(value);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Signed?', style: TextStyle(color: kTextColor, fontSize: 16)),
                      Switch(
                        value: _signed,
                        onChanged: (value) => setState(() => _signed = value),
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
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._photoUrls.asMap().entries.map((entry) {
                        final index = entry.key;
                        final path = entry.value;
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() => _photoUrls.removeAt(index)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
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
                              Icon(Icons.add_a_photo_outlined, color: kTextColor.withOpacity(0.5)),
                              const SizedBox(height: 4),
                              Text(
                                'Add photo',
                                style: TextStyle(color: kTextColor.withOpacity(0.5), fontSize: 12),
                              ),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 40),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: scanSize,
                      height: scanSize,
                      child: _isLoading
                          ? Container(
                        color: Colors.white.withOpacity(0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                          : MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Center the ISBN in the frame',
                    style: TextStyle(color: kTextColor.withOpacity(0.5), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonRed,
                      disabledBackgroundColor: kButtonRed.withOpacity(0.4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

