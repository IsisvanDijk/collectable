import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';
import 'add_book_screen.dart';
import '../widgets/narrow_layout.dart';
import '../repositories/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        // Save user profile with first and last names
        final userRepo = UserRepository();
        await userRepo.saveUser(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
      }
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error')),
      );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
    }
  }

  Widget _buildPillField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: kTextColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kTextColor.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildToggleBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isLogin = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isLogin ? kButtonPink : Colors.white,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(40),
                ),
              ),
              child: Text(
                'Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isLogin ? kButtonRed : kTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isLogin = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !_isLogin ? kButtonPink : Colors.white,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(40),
                ),
              ),
              child: Text(
                'Register',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: !_isLogin ? kButtonRed : kTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/images/Background.svg',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: bottomInset + 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight * 0.75),
                child: NarrowLayout(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: screenHeight * 0.10),
        const Text(
          'COLLECTABLE',
          style: TextStyle(
            color: kTextColor,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),

        const SizedBox(height: 32),

        Icon(
          Icons.menu_book_outlined,
          size: 64,
          color: kTextColor.withOpacity(0.4),
        ),

        const SizedBox(height: 32),

        _buildToggleBar(),

        const SizedBox(height: 32),

        AnimatedOpacity(
          opacity: _isLogin ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: _isLogin,
            child: Column(
              children: [
                _buildPillField(
                  controller: _firstNameController,
                  hint: 'First name...',
                ),
                const SizedBox(height: 12),
                _buildPillField(
                  controller: _lastNameController,
                  hint: 'Last name...',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        _buildPillField(
          controller: _emailController,
          hint: 'Email...',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 12),
        _buildPillField(
          controller: _passwordController,
          hint: 'Password...',
          obscure: true,
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: kButtonRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white)
                : Text(
                    _isLogin ? 'LOGIN' : 'Register',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: _isLogin ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_isLogin,
            child: GestureDetector(
              onTap: _forgotPassword,
              child: Text(
                'forgot password',
                style: TextStyle(
                  color: kTextColor.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: screenHeight * 0.08),
      ],
    ),
  ),
),
              ),
            ),
          ),
        ],
      ),
    );
  }
}