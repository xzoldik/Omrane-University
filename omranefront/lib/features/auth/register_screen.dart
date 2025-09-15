import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      name: _nameCtrl.text.trim(),
      studentId: _studentIdCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      final err = context.read<AuthProvider>().error ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottomInset),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter email';
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Min 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          _PasswordStrengthHint(password: _passwordCtrl),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                            ),
                            validator: (v) => v != _passwordCtrl.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _studentIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Student ID',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter your Student ID'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: loading ? null : _submit,
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Create account'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back to sign in'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PasswordStrengthHint extends StatelessWidget {
  const _PasswordStrengthHint({required this.password});
  final TextEditingController password;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: password,
      builder: (context, value, _) {
        final p = value.text;
        String label;
        Color color;
        if (p.length >= 12 &&
            _hasLetters(p) &&
            _hasDigits(p) &&
            _hasSymbols(p)) {
          label = 'Strong password';
          color = Colors.green;
        } else if (p.length >= 8 && _hasLetters(p) && _hasDigits(p)) {
          label = 'Medium password';
          color = Colors.orange;
        } else if (p.isEmpty) {
          label = '';
          color = Colors.transparent;
        } else {
          label = 'Weak password';
          color = Colors.red;
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: label.isEmpty
              ? const SizedBox.shrink()
              : Row(
                  key: ValueKey(label),
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(color: color)),
                  ],
                ),
        );
      },
    );
  }

  static bool _hasLetters(String s) => RegExp(r'[A-Za-z]').hasMatch(s);
  static bool _hasDigits(String s) => RegExp(r'[0-9]').hasMatch(s);
  static bool _hasSymbols(String s) => RegExp(r'[^A-Za-z0-9]').hasMatch(s);
}
