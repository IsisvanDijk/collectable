import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';
import 'add_book_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (_nameController.text.isNotEmpty) {
          await credential.user?.updateDisplayName(_nameController.text.trim());
        }
      }
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error')),
      );
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
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
      // Let the scaffold stay full-screen; we handle keyboard insets manually.
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
              // Pad the bottom by the keyboard height so the content scrolls
              // up just enough to stay visible — without any layout jump.
              padding: EdgeInsets.only(bottom: bottomInset + 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight * 0.75),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.10),

                      // Title
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

                      // Book icon
                      Icon(
                        Icons.menu_book_outlined,
                        size: 64,
                        color: kTextColor.withOpacity(0.4),
                      ),

                      const SizedBox(height: 32),

                      // Toggle
                      _buildToggleBar(),

                      const SizedBox(height: 32),

                      // Name field — always takes up space, fades in/out for register
                      AnimatedOpacity(
                        opacity: _isLogin ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: _isLogin,
                          child: _buildPillField(
                            controller: _nameController,
                            hint: 'Name...',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Email
                      _buildPillField(
                        controller: _emailController,
                        hint: 'Email...',
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 12),

                      // Password
                      _buildPillField(
                        controller: _passwordController,
                        hint: 'Password...',
                        obscure: true,
                      ),

                      const SizedBox(height: 32),

                      // Submit button
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

                      // Forgot password — always takes up space, fades in/out for login
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
        ],
      ),
    );
  }
}