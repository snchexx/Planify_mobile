import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:planify_mobile/config/api_config.dart';
import 'package:planify_mobile/services/activities_api.dart';
import 'package:planify_mobile/home_screen.dart';
import 'package:planify_mobile/services/auth_api.dart';
import 'package:planify_mobile/password_recovery_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PlanifyApp());
}

class PlanifyApp extends StatelessWidget {
  const PlanifyApp({super.key});

  static const _green = Color(0xFF18A84F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFDADADA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFDADADA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
        ),
      ),
      home: const AuthDesignScreen(),
    );
  }
}

enum _AuthMode { login, register }

class AuthDesignScreen extends StatefulWidget {
  const AuthDesignScreen({super.key, this.authApi, this.activitiesApi});

  final AuthApi? authApi;
  final ActivitiesApi? activitiesApi;

  @override
  State<AuthDesignScreen> createState() => _AuthDesignScreenState();
}

class _AuthDesignScreenState extends State<AuthDesignScreen> {
  final _registrationFormKey = GlobalKey<FormState>();
  final _httpClient = http.Client();
  final _identificationController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  late final _authApi =
      widget.authApi ?? AuthApi(client: _httpClient, baseUrl: apiBaseUrl);

  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;
  String? _registrationError;
  String? _loginError;

  static const _loginFields = [
    _AuthFieldData(
      id: 'email',
      label: 'Correo electrónico',
      hint: 'Ingresa tu correo electrónico...',
      icon: Icons.person_rounded,
      keyboardType: TextInputType.emailAddress,
    ),
    _AuthFieldData(
      id: 'password',
      label: 'Contraseña',
      hint: 'Ingresa tu contraseña...',
      icon: Icons.lock_rounded,
      isPassword: true,
    ),
  ];

  static const _registerFields = [
    _AuthFieldData(
      id: 'identification',
      label: 'Identificación',
      hint: 'Ingresa tu identificación...',
      icon: Icons.badge_outlined,
    ),
    _AuthFieldData(
      id: 'first-name',
      label: 'Nombres',
      hint: 'Ingresa tus nombres...',
      icon: Icons.person_outline_rounded,
    ),
    _AuthFieldData(
      id: 'last-name',
      label: 'Apellidos',
      hint: 'Ingresa tus apellidos...',
      icon: Icons.person_outline_rounded,
    ),
    _AuthFieldData(
      id: 'register-email',
      label: 'Correo electrónico',
      hint: 'Ingresa tu correo electrónico...',
      icon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
    ),
    _AuthFieldData(
      id: 'register-password',
      label: 'Contraseña',
      hint: 'Crea una contraseña...',
      icon: Icons.lock_rounded,
      isPassword: true,
    ),
  ];

  void _selectMode(_AuthMode mode) {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _mode = mode;
      _obscurePassword = true;
      _registrationError = null;
      _loginError = null;
    });
  }

  TextEditingController? _controllerFor(String fieldId) {
    switch (fieldId) {
      case 'email':
        return _loginEmailController;
      case 'password':
        return _loginPasswordController;
      case 'identification':
        return _identificationController;
      case 'first-name':
        return _firstNameController;
      case 'last-name':
        return _lastNameController;
      case 'register-email':
        return _registerEmailController;
      case 'register-password':
        return _registerPasswordController;
      default:
        return null;
    }
  }

  String? _validateRegistrationField(_AuthFieldData field, String? value) {
    final input = value ?? '';
    if (field.isPassword) {
      if (input.isEmpty) {
        return 'Completa este campo.';
      }
      if (input.length < 8) {
        return 'La contraseña debe tener al menos 8 caracteres.';
      }
      if (utf8.encode(input).length > 72) {
        return 'La contraseña no puede superar 72 bytes.';
      }
      return null;
    }

    final normalized = input.trim();
    if (normalized.isEmpty) {
      return 'Completa este campo.';
    }

    if (field.id == 'register-email') {
      if (normalized.length > 255) {
        return 'El correo no puede superar 255 caracteres.';
      }
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
        return 'Ingresa un correo electrónico válido.';
      }
      return null;
    }

    final maxLength = field.id == 'identification' ? 50 : 100;
    if (normalized.length > maxLength) {
      return 'Este campo no puede superar $maxLength caracteres.';
    }
    return null;
  }

  String? _validateLoginField(_AuthFieldData field, String? value) {
    final input = value ?? '';
    if (field.id == 'email') {
      final email = input.trim();
      if (email.isEmpty) {
        return 'Ingresa tu correo electrónico.';
      }
      if (email.length > 255 ||
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        return 'Ingresa un correo electrónico válido.';
      }
      return null;
    }

    if (input.isEmpty) {
      return 'Ingresa tu contraseña.';
    }
    if (input.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (utf8.encode(input).length > 72) {
      return 'La contraseña no puede superar 72 bytes.';
    }
    return null;
  }

  Future<void> _submitRegistration() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_registrationFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _registrationError = null;
    });

    try {
      await _authApi.register(
        identificacion: _identificationController.text.trim(),
        nombres: _firstNameController.text.trim(),
        apellidos: _lastNameController.text.trim(),
        email: _registerEmailController.text.trim().toLowerCase(),
        password: _registerPasswordController.text,
      );
      if (!mounted) {
        return;
      }

      _loginEmailController.text = _registerEmailController.text
          .trim()
          .toLowerCase();
      _registerPasswordController.clear();
      setState(() {
        _mode = _AuthMode.login;
        _obscurePassword = true;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Ya puedes iniciar sesión.'),
          ),
        );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _registrationError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_registrationFormKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _loginError = null;
    });

    try {
      final session = await _authApi.login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              HomeScreen(session: session, activitiesApi: widget.activitiesApi),
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loginError = error.message;
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
  void dispose() {
    _httpClient.close();
    _identificationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth < 560
                ? constraints.maxWidth
                : 560.0;
            final imageHeight = contentWidth * 761 / 1090;
            final panelHeight = (constraints.maxHeight - imageHeight)
                .clamp(0.0, constraints.maxHeight)
                .toDouble();
            final isLogin = _mode == _AuthMode.login;
            final fields = isLogin ? _loginFields : _registerFields;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 1090 / 761,
                        child: Image.asset(
                          'assets/planify_presentation.png',
                          key: const Key('presentation-image'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: panelHeight),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                          child: Form(
                            key: _registrationFormKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final buttonWidth =
                                        ((constraints.maxWidth - 12) / 2)
                                            .clamp(0.0, 148.0)
                                            .toDouble();

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: buttonWidth,
                                          child: _ModeButton(
                                            key: const Key('login-tab'),
                                            label: 'Iniciar sesión',
                                            icon: Icons.person_rounded,
                                            selected: isLogin,
                                            onTap: () =>
                                                _selectMode(_AuthMode.login),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: buttonWidth,
                                          child: _ModeButton(
                                            key: const Key('register-tab'),
                                            label: 'Crear cuenta',
                                            icon:
                                                Icons.person_add_alt_1_rounded,
                                            selected: !isLogin,
                                            onTap: () =>
                                                _selectMode(_AuthMode.register),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                if (isLogin) ...[
                                  for (final field in fields)
                                    _buildField(field),
                                  _buildAccountOptions(),
                                ] else ...[
                                  const SizedBox(height: 24),
                                  for (final field in fields) ...[
                                    _buildField(field),
                                    const SizedBox(height: 18),
                                  ],
                                ],
                                if (_registrationError != null)
                                  Text(
                                    _registrationError!,
                                    key: const Key('registration-error'),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                      fontSize: 13,
                                    ),
                                  ),
                                if (_loginError != null)
                                  Text(
                                    _loginError!,
                                    key: const Key('login-error'),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                      fontSize: 13,
                                    ),
                                  ),
                                _buildSubmitButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isLogin = _mode == _AuthMode.login;

    return SizedBox(
      height: 46,
      child: FilledButton.icon(
        key: const Key('submit-button'),
        onPressed: _isSubmitting
            ? null
            : isLogin
            ? _submitLogin
            : _submitRegistration,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.login_rounded),
        label: Text(
          isLogin
              ? _isSubmitting
                    ? 'Ingresando...'
                    : 'Iniciar sesión'
              : _isSubmitting
              ? 'Creando cuenta...'
              : 'Crear cuenta',
          style: const TextStyle(fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: PlanifyApp._green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _buildField(_AuthFieldData field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(field.icon, color: Colors.black87, size: 18),
            const SizedBox(width: 7),
            Text(
              field.label,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          key: Key('${field.id}-field'),
          controller: _controllerFor(field.id),
          keyboardType: field.keyboardType,
          obscureText: field.isPassword && _obscurePassword,
          validator: (value) => _mode == _AuthMode.register
              ? _validateRegistrationField(field, value)
              : _validateLoginField(field, value),
          decoration: InputDecoration(
            hintText: field.hint,
            suffixIcon: field.isPassword
                ? IconButton(
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
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountOptions() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
        ),
        const Expanded(
          child: Text(
            'Recordar mi cuenta',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12),
          ),
        ),
        Flexible(
          child: TextButton(
            key: const Key('forgot-password-button'),
            onPressed: _isSubmitting
                ? null
                : () {
                    _loginPasswordController.clear();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PasswordRecoveryScreen(
                          authApi: _authApi,
                          initialEmail: _loginEmailController.text.trim(),
                        ),
                      ),
                    );
                  },
            style: TextButton.styleFrom(
              foregroundColor: PlanifyApp._green,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '¿Olvidaste tu contraseña?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF222222);

    return Material(
      color: selected ? PlanifyApp._green : const Color(0xFFE5E5E5),
      borderRadius: BorderRadius.circular(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: foreground),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthFieldData {
  const _AuthFieldData({
    required this.id,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
  });

  final String id;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isPassword;
}
