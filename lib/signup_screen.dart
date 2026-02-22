import 'package:flutter/material.dart';
import 'gradient.dart';
import 'login_screen.dart';
import 'personalization_screen.dart';
import 'api_service.dart';
import 'user_session.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController            = TextEditingController();
  final _userIdController          = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController             = TextEditingController();

  bool _obscurePassword = true;

  /// 0 = fill form  |  1 = enter OTP
  int _phase = 0;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _fieldsFade;
  late Animation<Offset> _fieldsSlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.6, curve: Curves.easeIn),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    ));

    _fieldsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.8, curve: Curves.easeIn),
    );
    _fieldsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
    ));

    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _userIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── Phase 0: send OTP ─────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final name     = _nameController.text.trim();
    final userId   = _userIdController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmPasswordController.text;

    if (name.isEmpty || userId.isEmpty || email.isEmpty ||
        password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    final result = await ApiService.sendOtp(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      setState(() => _phase = 1);
      _controller.reset();
      _controller.forward();
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Failed to send OTP.');
    }
  }

  // ── Phase 1: register ─────────────────────────────────────────────────────
  Future<void> _register() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the OTP sent to your email.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await ApiService.register(
      name:     _nameController.text.trim(),
      userId:   _userIdController.text.trim(),
      email:    _emailController.text.trim(),
      password: _passwordController.text,
      otp:      otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      UserSession.instance.set(
        name:   _nameController.text.trim(),
        userId: _userIdController.text.trim(),
        email:  _emailController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const PersonalizationScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Registration failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AuroraGradient(
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).top -
                      MediaQuery.paddingOf(context).bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                      // ── Logo ──────────────────────────────────────────
                      Center(
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5CC)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'images/logo.jpeg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Title & subtitle ──────────────────────────────
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  _phase == 0 ? 'Create Account' : 'Verify Email',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _phase == 0
                                      ? 'Sign up to get started with\nCropIntel AI'
                                      : 'Enter the 6-digit code sent to\n${_emailController.text.trim()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF6B8FA0),
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Form fields ───────────────────────────────────
                      SlideTransition(
                        position: _fieldsSlide,
                        child: FadeTransition(
                          opacity: _fieldsFade,
                          child: _phase == 0
                              ? _buildRegistrationForm()
                              : _buildOtpForm(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Error message ────────────────────────────────
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A1010),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFEF9A9A)
                                      .withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Color(0xFFEF9A9A), fontSize: 13),
                            ),
                          ),
                        ),

                      // ── Action button ─────────────────────────────────
                      SlideTransition(
                        position: _buttonSlide,
                        child: FadeTransition(
                          opacity: _buttonFade,
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00EFDF),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5CC)
                                            .withValues(alpha: 0.40),
                                        blurRadius: 22,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : (_phase == 0 ? _sendOtp : _register),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Color(0xFF071218),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _phase == 0
                                                    ? 'Send OTP'
                                                    : 'Create Account',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF071218),
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Color(0xFF071218),
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Back link (OTP phase only)
                              if (_phase == 1)
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() {
                                            _phase = 0;
                                            _otpController.clear();
                                            _errorMessage = null;
                                          }),
                                  child: const Text(
                                    '← Back to edit details',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6B8FA0)),
                                  ),
                                ),

                              const SizedBox(height: 12),

                              // Already have an account
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B8FA0),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            const LoginScreen(),
                                        transitionsBuilder:
                                            (_, animation, __, child) =>
                                                FadeTransition(
                                                    opacity: animation,
                                                    child: child),
                                        transitionDuration: const Duration(
                                            milliseconds: 400),
                                      ),
                                    ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Phase-0 registration form ──────────────────────────────────────────
  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Full Name'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _nameController,
          hint: 'Your Name',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 20),
        _fieldLabel('Username'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _userIdController,
          hint: 'e.g. john_farmer',
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 20),
        _fieldLabel('Email Address'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _emailController,
          hint: 'user@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _fieldLabel('Password'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _passwordController,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: GestureDetector(
            onTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF8DAAB8),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _fieldLabel('Confirm Password'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _confirmPasswordController,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: GestureDetector(
            onTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF8DAAB8),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ── Phase-1 OTP form ───────────────────────────────────────────────────
  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('OTP Code'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _otpController,
          hint: '6-digit code',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _isLoading ? null : _sendOtp,
            child: const Text(
              'Resend OTP',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6BAABB),
        ),
      );

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B3340),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF6B8A99), fontSize: 15),
          prefixIcon:
              Icon(prefixIcon, color: const Color(0xFF8DAAB8), size: 20),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: suffixIcon,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        ),
      ),
    );
  }

}
