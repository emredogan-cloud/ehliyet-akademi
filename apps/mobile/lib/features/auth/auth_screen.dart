import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../domain/auth/auth_controller.dart';

/// Login / register screen. Full-screen over the tab shell. Guests reach it from Profil.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ctrl = ref.read(authControllerProvider.notifier);
    final err = _isRegister
        ? await ctrl.register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          )
        : await ctrl.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      if (context.canPop()) context.pop();
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Kayıt ol' : 'Giriş yap')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.s2),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: p.primary.withValues(alpha: 0.16),
                      child: Icon(Icons.school_rounded, color: p.primary, size: 30),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      _isRegister ? 'Hesabını oluştur' : 'Tekrar hoş geldin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'İlerlemen kaydedilir ve cihazlar arası eşitlenir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.text3, fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 2) ? 'Adını gir.' : null,
                      ),
                      const SizedBox(height: AppSpacing.s3),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) => (v == null || !v.contains('@') || !v.contains('.'))
                          ? 'Geçerli bir e-posta gir.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Parola',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'En az 8 karakter.' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.s3),
                      Text(_error!, style: TextStyle(color: p.red, fontSize: 13)),
                    ],
                    const SizedBox(height: AppSpacing.s5),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isRegister ? 'Kayıt ol' : 'Giriş yap'),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _isRegister = !_isRegister;
                                _error = null;
                              }),
                      child: Text(_isRegister
                          ? 'Zaten hesabın var mı? Giriş yap'
                          : 'Hesabın yok mu? Kayıt ol'),
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
