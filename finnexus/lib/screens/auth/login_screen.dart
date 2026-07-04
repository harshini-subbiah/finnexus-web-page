import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().signInWithEmail(
          _emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') ||
        raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Invalid email or password';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }
    return 'Login failed. Please try again';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    const Color(0xFF6C63FF).withOpacity(0.3)),
          ),
          // Enter key on physical keyboard submits the form
          // from anywhere inside this widget
          child: Shortcuts(
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.enter):
                  const ActivateIntent(),
            },
            child: Actions(
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (intent) {
                    if (!_loading) _login();
                    return null;
                  },
                ),
              },
              child: Focus(
                autofocus: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FinNexus',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
                            letterSpacing: 2)),
                    const SizedBox(height: 4),
                    const Text('Sign in to your account',
                        style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context)
                              .requestFocus(_passwordFocus),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle:
                            const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0D0D1A),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF2D2D4E))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF2D2D4E))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF6C63FF))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle:
                            const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0D0D1A),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white38,
                              size: 18),
                          onPressed: () => setState(
                              () => _obscure = !_obscure),
                        ),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF2D2D4E))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF2D2D4E))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF6C63FF))),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13)),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2)
                            : const Text('Sign In',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?",
                            style:
                                TextStyle(color: Colors.white54)),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Register',
                              style: TextStyle(
                                  color: Color(0xFF6C63FF))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}