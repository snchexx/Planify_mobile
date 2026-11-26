import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:planify_mobile/services/auth_api.dart';

enum _RecoveryStep { requestCode, verifyCode, completed }

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    super.key,
    required this.authApi,
    this.initialEmail = '',
  });

  final AuthApi authApi;
  final String initialEmail;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  _RecoveryStep _step = _RecoveryStep.requestCode;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _informationMessage;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }
    if (email.length > 255 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (!RegExp(r'^\d{6}$').hasMatch((value ?? '').trim())) {
      return 'Ingresa el código de 6 dígitos.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (utf8.encode(password).length > 72) {
      return 'La contraseña no puede superar 72 bytes.';
    }
    return null;
  }

  Future<void> _requestCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _informationMessage = null;
    });

    try {
      await widget.authApi.requestPasswordReset(email: _emailController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _step = _RecoveryStep.verifyCode;
        _informationMessage = 'Si la cuenta existe, enviamos un código. Revisa también la carpeta de spam; el código vence en 10 minutos.';
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.authApi.resetPassword(
        email: _emailController.text,
        code: _codeController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _step = _RecoveryStep.completed;
        _informationMessage = null;
        _errorMessage = null;
        _codeController.clear();
        _passwordController.clear();
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.authApi.requestPasswordReset(email: _emailController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _informationMessage = 'Si la cuenta existe, enviamos un código. Si solicitaste uno hace poco, espera un minuto antes de volver a intentarlo.';
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRequestingCode = _step == _RecoveryStep.requestCode;
    final isVerifyingCode = _step == _RecoveryStep.verifyCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isRequestingCode) ...[
                      const Text(
                        'Ingresa el correo asociado a tu cuenta y te enviaremos un código de recuperación.',
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('recovery-email-field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: _validateEmail,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _requestCode(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('recovery-submit-button'),
                        onPressed: _isSubmitting ? null : _requestCode,
                        child: Text(
                          _isSubmitting ? 'Enviando...' : 'Enviar código',
                        ),
                      ),
                    ] else if (isVerifyingCode) ...[
                      TextFormField(
                        key: const Key('recovery-email-readonly-field'),
                        controller: _emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('recovery-code-field'),
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _validateCode,
                        decoration: const InputDecoration(
                          labelText: 'Código de 6 dígitos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('recovery-new-password-field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: _validatePassword,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            key: const Key('recovery-password-visibility'),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (_) => _resetPassword(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('recovery-reset-button'),
                        onPressed: _isSubmitting ? null : _resetPassword,
                        child: Text(
                          _isSubmitting
                              ? 'Restableciendo...'
                              : 'Restablecer contraseña',
                        ),
                      ),
                      TextButton(
                        key: const Key('recovery-resend-button'),
                        onPressed: _isSubmitting ? null : _resendCode,
                        child: const Text('Enviar otro código'),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 56,
                        color: Color(0xFF18A84F),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tu contraseña fue actualizada.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('recovery-finish-button'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Volver a iniciar sesión'),
                      ),
                    ],
                    if (_informationMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _informationMessage!,
                        key: const Key('recovery-information'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        key: const Key('recovery-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_step != _RecoveryStep.completed) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        key: const Key('recovery-back-button'),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Volver al inicio de sesión'),
                      ),
                    ],
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
