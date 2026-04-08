import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../widgets/narrow_layout.dart';
import '../repositories/user_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String? _profileImagePath;
  final UserRepository _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    final user = FirebaseAuth.instance.currentUser;
    _emailController.text = user?.email ?? '';
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final appUser = await _userRepo.getUser();
      if (appUser != null && mounted) {
        setState(() {
          _firstNameController.text = appUser.firstName ?? '';
          _lastNameController.text = appUser.lastName ?? '';
        });
      }
    } catch (_) {
      // User profile might not exist yet
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profileImagePath');
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _isLoading = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final localPath = p.join(appDir.path, 'profile_photos', fileName);
      await Directory(p.dirname(localPath)).create(recursive: true);
      await File(image.path).copy(localPath);
      _profileImagePath = localPath;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', localPath);
      setState(() {});
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

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Update first and last name in user repository
      await _userRepo.updateName(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (_emailController.text.isNotEmpty &&
          _emailController.text != user?.email) {
        await user?.verifyBeforeUpdateEmail(_emailController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent to new address')),
        );
        }
      }
      if (_passwordController.text.isNotEmpty) {
        await user?.updatePassword(_passwordController.text);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPillButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: kTextColor, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _firstNameController.text.isEmpty && _lastNameController.text.isEmpty
        ? 'User'
        : '${_firstNameController.text} ${_lastNameController.text}'.trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Settings', showSettings: false, showBack: true),
      body: NarrowLayout(
  child: ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            fullName,
            style: const TextStyle(
              color: kTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFFE6C5CA),
                backgroundImage:
                _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                child: _profileImagePath == null
                    ? const Icon(Icons.person, size: 48, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Divider(color: kTextColor, thickness: 0.5),
          const SizedBox(height: 20),

           _buildPillButton('Edit profile picture', onTap: _pickProfileImage),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: TextFormField(
                controller: _firstNameController,
                style: const TextStyle(color: kTextColor),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Edit first name',
                  hintStyle: TextStyle(color: kTextColor.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: TextFormField(
                controller: _lastNameController,
                style: const TextStyle(color: kTextColor),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Edit last name',
                  hintStyle: TextStyle(color: kTextColor.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: kTextColor),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Update password',
                hintStyle: TextStyle(color: kTextColor.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: kTextColor),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Update email',
                hintStyle: TextStyle(color: kTextColor.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
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
                'Save settings',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),

          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Log out',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextColor,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
),
    );
  }
}