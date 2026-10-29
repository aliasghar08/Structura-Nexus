// ============================================================================
// Structura Nexus — Authentication Screen (Login, Sign-Up, Forgot Password)
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/floating_copyright_watermark.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final String? redirectMessage;

  const AuthScreen({
    super.key,
    this.onLoginSuccess,
    this.redirectMessage,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _cleanError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No registered account found with this email address.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password. Please verify your credentials.';
        case 'email-already-in-use':
          return 'An account already exists with this email. Try signing in.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'The email address is improperly formatted.';
        case 'network-request-failed':
          return 'Network error: please verify your internet connection.';
        case 'popup-closed-by-user':
          return 'Sign-in popup was closed before completion.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email format.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isLogin) {
        await _authService.signInWithEmail(email, password);
      } else {
        await _authService.registerWithEmail(
          email,
          password,
          displayName: name.isNotEmpty ? name : null,
        );
      }

      if (mounted) {
        widget.onLoginSuccess?.call();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _cleanError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        widget.onLoginSuccess?.call();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _cleanError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGuestAccess() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInAnonymously();
      if (mounted) {
        widget.onLoginSuccess?.call();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      // Fallback: if anonymous auth fails on network, invoke success directly
      if (mounted) {
        widget.onLoginSuccess?.call();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    String? localError;
    bool localLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131822),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF00F0FF), size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your email address to receive a secure link to reset your password.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00F0FF), size: 18),
                      filled: true,
                      fillColor: const Color(0xFF0D1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                      ),
                    ),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: localLoading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              FilledButton(
                onPressed: localLoading
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(() => localError = 'Please enter a valid email address.');
                          return;
                        }
                        setDialogState(() {
                          localLoading = true;
                          localError = null;
                        });
                        try {
                          await _authService.sendPasswordReset(email);
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.mark_email_read_rounded, color: Color(0xFF00F0FF), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Password reset link dispatched to $email! Check your inbox.'),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF131822),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            localError = _cleanError(e);
                            localLoading = false;
                          });
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6FEB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: localLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Dispatch Reset Link'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: Stack(
        children: [
          // Background Gradient Circles
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1F6FEB).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Card View
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + (Navigator.of(context).canPop() ? 64 : 28),
                16,
                48,
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: 460,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 480 ? 20 : 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with App Icon
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/structura_nexus_icon.jpeg',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1F6FEB), Color(0xFF00F0FF)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.architecture_rounded, size: 36, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'STRUCTURA NEXUS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AI-Augmented Structural Engineering Workstation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),

                      if (widget.redirectMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F6FEB).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1F6FEB).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            widget.redirectMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Mode Switcher (Login vs Sign Up)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isLogin = true;
                                  _errorMessage = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isLogin ? const Color(0xFF1F6FEB) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'SIGN IN',
                                      style: TextStyle(
                                        color: _isLogin ? Colors.white : const Color(0xFF8B949E),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isLogin = false;
                                  _errorMessage = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isLogin ? const Color(0xFF1F6FEB) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'REGISTER',
                                      style: TextStyle(
                                        color: !_isLogin ? Colors.white : const Color(0xFF8B949E),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Input Fields
                      if (!_isLogin) ...[
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF00F0FF), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF161B22),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00F0FF), size: 18),
                          filled: true,
                          fillColor: const Color(0xFF161B22),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF00F0FF), size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF8B949E),
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF161B22),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                          ),
                        ),
                      ),

                      // Forgot Password Link (Login mode only)
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _showResetPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(0xFF00F0FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_successMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Primary Submit Button
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1F6FEB), Color(0xFF00F0FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1F6FEB).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Text(
                                  _isLogin ? 'AUTHENTICATE & ENTER' : 'CREATE ENGINEERING ACCOUNT',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Google Sign In
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 22, color: Colors.white),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Guest / Visitor Access
                      TextButton.icon(
                        onPressed: _isLoading ? null : _handleGuestAccess,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF8B949E)),
                        label: const Text(
                          'Explore Workstation as Guest Engineer',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Optional Back Button (rendered above scroll view so it is never covered on mobile)
          if (Navigator.of(context).canPop())
            Positioned(
              top: MediaQuery.paddingOf(context).top + 14,
              left: 16,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 16),
                label: const Text(
                  'Back to Workstation',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF161B22),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
              ),
            ),

          // Floating Copyright Watermark
          const FloatingCopyrightWatermark(),
        ],
      ),
    );
  }
}
