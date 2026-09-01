import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/brand_mark.dart';
import '../../shared/glass.dart';
import '../../shared/glass_dropdown.dart';
import '../../shared/theme_mode.dart';
import 'auth_api.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.connectionError});

  final String? connectionError;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _isSubmitting = false;
  String? _ageRange;
  String? _gender;
  String? _message;
  String? _successMessage;

  int _failedLoginAttempts = 0;
  bool _isForgotPassword = false;
  int _resetStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final controller = ref.read(authControllerProvider.notifier);
      if (_isRegistering) {
        await controller.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          ageRange: _ageRange!,
          gender: _gender,
        );
      } else {
        await controller.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text);
        _failedLoginAttempts = 0;
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          if (!_isRegistering) {
            _failedLoginAttempts++;
            if (_failedLoginAttempts >= 5) {
              _isForgotPassword = true;
              _message = null;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'We could not complete that request. Please try again.';
          if (!_isRegistering) {
            _failedLoginAttempts++;
            if (_failedLoginAttempts >= 5) {
              _isForgotPassword = true;
              _message = null;
            }
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final res = await ref.read(authApiProvider).requestPasswordReset(email);
      if (mounted) {
        final devCode = res['code'] as String?;
        if (devCode != null) {
          _resetCodeController.text = devCode;
        }
        setState(() {
          _resetStep = 1;
          _message = null;
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _message = 'We could not send the reset code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitConfirmReset() async {
    final email = _emailController.text.trim();
    final code = _resetCodeController.text.trim();
    final newPassword = _newPasswordController.text;

    if (code.length != 6) {
      setState(() => _message = 'Enter the 6-digit verification code.');
      return;
    }
    if (newPassword.length < 12) {
      setState(() => _message = 'Password must be at least 12 characters.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await ref.read(authApiProvider).confirmPasswordReset(
            email: email,
            code: code,
            newPassword: newPassword,
          );
      if (mounted) {
        setState(() {
          _isForgotPassword = false;
          _resetStep = 0;
          _failedLoginAttempts = 0;
          _passwordController.clear();
          _newPasswordController.clear();
          _resetCodeController.clear();
          _message = null;
          _successMessage =
              'Password updated successfully! Please sign in with your new password.';
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _message = 'Failed to reset password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _backToSignIn() {
    setState(() {
      _isForgotPassword = false;
      _resetStep = 0;
      _failedLoginAttempts = 0;
      _message = null;
      _resetCodeController.clear();
      _newPasswordController.clear();
    });
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _introPanel(isDark)),
                          const SizedBox(width: 64),
                          SizedBox(width: 430, child: _formCard(isDark)),
                        ],
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: _formCard(isDark),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _introPanel(bool isDark) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              BrandMark(),
              SizedBox(width: 12),
              Text('DueNest',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Spacer(),
              ThemeToggleButton(),
            ]),
            SizedBox(height: 56),
            Text('Never miss\nwhat’s due.',
                style: TextStyle(
                    fontSize: 52,
                    height: 1.04,
                    letterSpacing: -2,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 20),
            Text(
                'A calm, private home for the documents, licences, and subscriptions that matter.',
                style: TextStyle(
                    fontSize: 18,
                    height: 1.55,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF4B5563))),
            SizedBox(height: 38),
            _Benefit(
                icon: Icons.notifications_none_rounded,
                label: 'Clear reminders before each important date'),
            SizedBox(height: 18),
            _Benefit(
                icon: Icons.shield_outlined,
                label: 'Your active session stays protected'),
            SizedBox(height: 18),
            _Benefit(
                icon: Icons.layers_outlined,
                label: 'One simple space for everything due'),
          ],
        ),
      );

  Widget _formCard(bool isDark) => AdvancedGlassPanel(
        radius: 30,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _isForgotPassword
                ? _forgotPasswordContent(isDark)
                : _authFormContent(isDark),
          ),
        ),
      );

  Widget _forgotPasswordContent(bool isDark) => Column(
        key: const ValueKey<String>('forgot_password_view'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (MediaQuery.sizeOf(context).width < 900) ...[
            Row(children: const [
              BrandMark(size: 38),
              SizedBox(width: 10),
              Text('DueNest',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Spacer(),
              ThemeToggleButton(),
            ]),
            const SizedBox(height: 32),
          ],
          Text(
            _resetStep == 0 ? 'Reset password' : 'Enter reset code',
            style: const TextStyle(
                fontSize: 29, letterSpacing: -1, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _resetStep == 0
                ? '5 continuous failed sign-in attempts detected. Enter your email to recover access.'
                : 'Enter the 6-digit code and your new password below.',
            style: TextStyle(
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                height: 1.4),
          ),
          const SizedBox(height: 26),
          if (_message != null) _MessageBox(message: _message!),
          if (_resetStep == 0) ...[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline_rounded)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitForgotPassword,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Send reset code'),
            ),
            const SizedBox(height: 18),
          ] else ...[
            TextFormField(
              controller: _resetCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: '6-digit verification code',
                  counterText: '',
                  prefixIcon: Icon(Icons.pin_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'New password',
                helperText: 'Use at least 12 characters.',
                helperStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280)),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip:
                      _obscureNewPassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword),
                  icon: Icon(_obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitConfirmReset,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save new password'),
            ),
            const SizedBox(height: 18),
          ],
          TextButton.icon(
            onPressed: _backToSignIn,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to Sign in'),
          ),
          const SizedBox(height: 14),
          Text(
              'Your privacy is protected. Reset links expire after 15 minutes and can only be used once.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF6B7280))),
        ],
      );

  Widget _authFormContent(bool isDark) => AutofillGroup(
        key: const ValueKey<String>('auth_form_view'),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (MediaQuery.sizeOf(context).width < 900) ...[
                Row(children: [
                  BrandMark(size: 38),
                  SizedBox(width: 10),
                  Text('DueNest',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  const ThemeToggleButton(),
                ]),
                const SizedBox(height: 32),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey<bool>(_isRegistering),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isRegistering ? 'Create your space' : 'Welcome back',
                        style: const TextStyle(
                            fontSize: 29,
                            letterSpacing: -1,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegistering
                            ? 'Start with a secure DueNest account.'
                            : 'Sign in to see what’s coming due.',
                        style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              if (widget.connectionError != null && !_isSubmitting)
                const _MessageBox(
                    message:
                        'We could not restore your session. Please sign in again.'),
              if (_successMessage != null)
                _SuccessBox(message: _successMessage!),
              if (_message != null) _MessageBox(message: _message!),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                            labelText: 'Your name',
                            prefixIcon: Icon(Icons.person_outline_rounded)),
                        validator: (value) => _isRegistering &&
                                (value == null || value.trim().isEmpty)
                            ? 'Enter your name.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      GlassDropdownField<String>(
                        initialValue: _ageRange,
                        labelText: 'Age range',
                        prefixIcon: const Icon(Icons.cake_outlined),
                        items: const [
                          GlassDropdownItem(
                              value: 'UNDER_18', label: 'Under 18'),
                          GlassDropdownItem(value: 'AGE_18_24', label: '18–24'),
                          GlassDropdownItem(value: 'AGE_25_34', label: '25–34'),
                          GlassDropdownItem(value: 'AGE_35_44', label: '35–44'),
                          GlassDropdownItem(value: 'AGE_45_PLUS', label: '45+'),
                        ],
                        onChanged: (value) => setState(() => _ageRange = value),
                        validator: (value) => _isRegistering && value == null
                            ? 'Select your age range.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      GlassDropdownField<String>(
                        initialValue: _gender,
                        labelText: 'Gender',
                        hintText: 'Optional',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        items: const [
                          GlassDropdownItem(
                              value: 'MALE',
                              label: 'Male',
                              icon: Icons.male_rounded),
                          GlassDropdownItem(
                              value: 'FEMALE',
                              label: 'Female',
                              icon: Icons.female_rounded),
                        ],
                        onChanged: (value) => setState(() => _gender = value),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                crossFadeState: _isRegistering
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 320),
                sizeCurve: Curves.easeInOutCubic,
                firstCurve: Curves.easeOut,
                secondCurve: Curves.easeIn,
              ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email
                ],
                decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline_rounded)),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email address.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: [
                  _isRegistering
                      ? AutofillHints.newPassword
                      : AutofillHints.password
                ],
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText:
                      _isRegistering ? 'Use at least 12 characters.' : null,
                  helperStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF6B7280)),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip:
                        _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (value) => value == null || value.length < 12
                    ? 'Use at least 12 characters.'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Text(
                          _isRegistering ? 'Create account' : 'Sign in',
                          key: ValueKey<bool>(_isRegistering),
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _isSubmitting ? null : _toggleMode,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    _isRegistering
                        ? 'Already have an account? Sign in'
                        : 'New to DueNest? Create an account',
                    key: ValueKey<bool>(_isRegistering),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                  'By continuing, you keep access to a private reminder space. We do not ask for document scans or ID numbers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF6B7280))),
            ],
          ),
        ),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3F1212) : const Color(0xFFFFF1F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? const Color(0xFF7F1D1D)
                    : const Color(0xFFFCA5A5))),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color:
                    isDark ? const Color(0xFFF87171) : const Color(0xFFBA1A1A)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFECACA)
                            : const Color(0xFF8A1010),
                        height: 1.35))),
          ],
        ),
      ),
    );
  }
}

class _SuccessBox extends StatelessWidget {
  const _SuccessBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF063E26) : const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? const Color(0xFF047857)
                    : const Color(0xFF86EFAC))),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color:
                    isDark ? const Color(0xFF34D399) : const Color(0xFF137333)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFF0D652D),
                        height: 1.35))),
          ],
        ),
      ),
    );
  }
}
