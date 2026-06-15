import 'package:flutter/material.dart';
import 'package:progressio_mobile/core/api_client.dart';
import 'package:progressio_mobile/screens/login_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (token.isEmpty) {
      setState(() => _error = 'Password reset token is required.');
      return;
    }
    if (password.length < 8 || !RegExp(r'[0-9]').hasMatch(password)) {
      setState(() => _error = 'Password must contain at least 8 characters and one digit.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Password confirmation does not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiClient.post(
        'auth/reset-password',
        requiresAuth: false,
        body: {
          'email': widget.email,
          'token': token,
          'newPassword': password,
          'confirmPassword': confirm,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password was reset successfully.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set new password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste the token sent to ${widget.email}.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _tokenController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Reset token'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'Resetting...' : 'Reset password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}