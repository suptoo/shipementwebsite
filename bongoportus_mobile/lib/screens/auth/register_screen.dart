import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _agreeToTerms = false;

  late AnimationController _bgAnimCtrl;
  late AnimationController _formAnimCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // Password strength
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;
  List<_PwRequirement> _pwRequirements = [];

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    _formAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _formAnimCtrl, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formAnimCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _formAnimCtrl.forward();
    _passwordController.addListener(_evaluatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgAnimCtrl.dispose();
    _formAnimCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _evaluatePasswordStrength() {
    final pw = _passwordController.text;
    double strength = 0;
    final reqs = <_PwRequirement>[
      _PwRequirement('6+ characters', pw.length >= 6),
      _PwRequirement('Uppercase letter', RegExp(r'[A-Z]').hasMatch(pw)),
      _PwRequirement('Number', RegExp(r'[0-9]').hasMatch(pw)),
      _PwRequirement('Special character', RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pw)),
    ];
    for (final r in reqs) {
      if (r.met) strength += 0.25;
    }

    String label;
    Color color;
    if (pw.isEmpty) {
      label = '';
      color = Colors.transparent;
    } else if (strength <= 0.25) {
      label = 'Weak';
      color = const Color(0xFFEF4444);
    } else if (strength <= 0.5) {
      label = 'Fair';
      color = const Color(0xFFF59E0B);
    } else if (strength <= 0.75) {
      label = 'Good';
      color = const Color(0xFF3B82F6);
    } else {
      label = 'Strong';
      color = const Color(0xFF22C55E);
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
      _pwRequirements = reqs;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      _showSnack(
        'Please agree to the Terms & Conditions',
        Icons.warning_amber_rounded,
        const Color(0xFFF59E0B),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthProvider>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      if (mounted) {
        _showSnack(
          'Account created! Check your email to verify.',
          Icons.check_circle_rounded,
          const Color(0xFF22C55E),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceAll(RegExp(r'^Exception:\s*'), ''),
          Icons.error_outline_rounded,
          const Color(0xFFEF4444),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceAll(RegExp(r'^Exception:\s*'), ''),
          Icons.error_outline_rounded,
          const Color(0xFFEF4444),
        );
      }
    }
  }

  void _showSnack(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ──
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (_, __) {
              final t = _bgAnimCtrl.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF4F46E5), const Color(0xFF7C3AED), t)!,
                      Color.lerp(const Color(0xFF0F172A), const Color(0xFF1E1B4B), t)!,
                    ],
                    stops: [0.0, 0.55 + t * 0.35],
                  ),
                ),
              );
            },
          ),

          // ── Floating orbs ──
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final p = _pulseCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + p * 20,
                    left: -40,
                    child: _buildOrb(size.width * 0.6, const Color(0xFF818CF8), 0.08 + p * 0.04),
                  ),
                  Positioned(
                    bottom: -80 + p * 15,
                    right: -60,
                    child: _buildOrb(size.width * 0.5, const Color(0xFFA78BFA), 0.06 + p * 0.03),
                  ),
                  Positioned(
                    top: size.height * 0.4,
                    right: -30,
                    child: _buildOrb(size.width * 0.25, const Color(0xFF6366F1), 0.05 + p * 0.03),
                  ),
                ],
              );
            },
          ),

          // ── Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height - pad.top - pad.bottom,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildGlassCard(),
                        const SizedBox(height: 20),
                        _buildLoginLink(),
                        const SizedBox(height: 32),
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

  Widget _buildOrb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha((opacity * 255).round()),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Animated icon
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            return Transform.scale(
              scale: 1.0 + _pulseCtrl.value * 0.04,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withAlpha(102),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, size: 36, color: Colors.white),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join BongoPortus — shop from around the world',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withAlpha(153),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Your full name',
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 18),

                // Email
                _buildField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: _toggleVisibility(
                    _obscurePassword,
                    () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),

                // Password strength bar + requirements
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPasswordStrengthBar(),
                  const SizedBox(height: 10),
                  _buildPasswordRequirements(),
                ],
                const SizedBox(height: 18),

                // Confirm Password
                _buildField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleRegister(),
                  suffixIcon: _toggleVisibility(
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Terms checkbox
                _buildTermsCheckbox(),
                const SizedBox(height: 24),

                // Gradient register button
                _buildRegisterButton(),
                const SizedBox(height: 20),

                // Divider
                _buildDivider(),
                const SizedBox(height: 18),

                // Google sign-up
                _buildGoogleButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.white.withAlpha(25),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _passwordStrength,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      _passwordStrengthColor.withAlpha(204),
                      _passwordStrengthColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _passwordStrengthColor.withAlpha(102),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _passwordStrengthLabel,
            key: ValueKey(_passwordStrengthLabel),
            style: TextStyle(
              color: _passwordStrengthColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: _pwRequirements.map((r) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: r.met ? const Color(0xFF22C55E).withAlpha(38) : Colors.white.withAlpha(13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: r.met ? const Color(0xFF22C55E).withAlpha(76) : Colors.white.withAlpha(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                r.met ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 12,
                color: r.met ? const Color(0xFF22C55E) : Colors.white.withAlpha(76),
              ),
              const SizedBox(width: 4),
              Text(
                r.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: r.met ? const Color(0xFF22C55E) : Colors.white.withAlpha(102),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: _agreeToTerms
                  ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                  : null,
              color: _agreeToTerms ? null : Colors.transparent,
              border: Border.all(
                color: _agreeToTerms ? Colors.transparent : Colors.white.withAlpha(51),
                width: 2,
              ),
              boxShadow: _agreeToTerms
                  ? [BoxShadow(color: const Color(0xFF6366F1).withAlpha(76), blurRadius: 8)]
                  : [],
            ),
            child: _agreeToTerms
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(140)),
                children: const [
                  TextSpan(
                    text: 'Terms & Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF818CF8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _handleRegister,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 56,
        decoration: BoxDecoration(
          gradient: _isSubmitting
              ? LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade700])
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSubmitting
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(102),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withAlpha(25))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or sign up with',
            style: TextStyle(color: Colors.white.withAlpha(89), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withAlpha(25))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _handleGoogleSignUp,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(3),
              child: Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                width: 18,
                height: 18,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 18,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType inputType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha(178),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: inputType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          cursorColor: const Color(0xFF818CF8),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withAlpha(56), fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white.withAlpha(102), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withAlpha(15),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withAlpha(20)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withAlpha(20)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _toggleVisibility(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.white.withAlpha(89),
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.white.withAlpha(127), fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF818CF8),
              fontWeight: FontWeight.w700,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF818CF8),
            ),
          ),
        ),
      ],
    );
  }
}

class _PwRequirement {
  final String label;
  final bool met;
  const _PwRequirement(this.label, this.met);
}
