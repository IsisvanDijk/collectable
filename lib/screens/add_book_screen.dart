import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../main.dart';

const kButtonRed = Color(0xFF521121);
const kButtonPink = Color(0xFFE6C5CA);

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _editionController = TextEditingController();
  final _printRunController = TextEditingController();
  final _notesController = TextEditingController();
  BookCondition _condition = BookCondition.mint;
  bool _signed = false;
  List<String> _photoUrls = [];
  bool _isLoading = false;
  bool _isManual = true;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('book_photos/${Uuid().v4()}.jpg');
        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();
        setState(() => _photoUrls.add(url));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final book = Book(
        id: const Uuid().v4(),
        userId: '',
        title: _titleController.text,
        author: _authorController.text,
        isbn: _isbnController.text.isEmpty ? null : _isbnController.text,
        edition: _editionController.text.isEmpty ? null : _editionController.text,
        printRun: _printRunController.text.isEmpty ? null : _printRunController.text,
        condition: _condition,
        signed: _signed,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        photoUrls: _photoUrls,
        dateAdded: DateTime.now(),
      );
      await BookRepository().add(book);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save book: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPillField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
    return Container(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isManual = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isManual ? kButtonPink : Colors.white,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(40)),
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
              onTap: () => setState(() => _isManual = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isManual ? kButtonPink : Colors.white,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(40)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Add book'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _buildToggleBar(),
            const SizedBox(height: 24),

            if (_isManual) ...[
              Row(
                children: [
                  Expanded(child: _buildPillField(
                    controller: _titleController,
                    hint: 'Title',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPillField(
                    controller: _authorController,
                    hint: 'Author',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildPillField(
                    controller: _isbnController,
                    hint: 'ISBN?',
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPillField(
                    controller: _printRunController,
                    hint: 'Print',
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildPillField(
                    controller: _editionController,
                    hint: 'Edition',
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
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
                          hint: const Text('Condition',
                              style: TextStyle(color: kTextColor)),
                          items: BookCondition.values
                              .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name),
                          ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _condition = value!),
                        ),
                      ),
                    ),
                  ),
                ],
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
                    const Text('Signed?',
                        style: TextStyle(color: kTextColor, fontSize: 16)),
                    Switch(
                      value: _signed,
                      onChanged: (value) => setState(() => _signed = value),
                      activeColor: kButtonRed,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildPillField(
                controller: _notesController,
                hint: 'Notes',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Add photo's",
                          style: TextStyle(
                              color: kTextColor.withOpacity(0.5), fontSize: 16)),
                      Icon(Icons.camera_alt_outlined,
                          color: kTextColor.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
              if (_photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _photoUrls
                      .map((url) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url,
                        width: 80, height: 80, fit: BoxFit.cover),
                  ))
                      .toList(),
                ),
              ],
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
                      : const Text('Save to collection',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
              // ISBN scan placeholder — you'll fill this in later
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'ISBN scanning coming soon',
                  style: TextStyle(color: kTextColor.withOpacity(0.6)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}