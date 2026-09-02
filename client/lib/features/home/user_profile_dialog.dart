import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens.dart';
import '../../shared/glass_dropdown.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';

class UserProfileDialog extends ConsumerStatefulWidget {
  const UserProfileDialog({super.key, required this.user});

  final DeuNestUser user;

  @override
  ConsumerState<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends ConsumerState<UserProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _currPassCtrl;
  late final TextEditingController _newPassCtrl;

  String? _selectedAgeRange;
  String? _selectedGender;

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  final _ageRanges = {
    'UNDER_18': 'Under 18',
    'AGE_18_24': '18–24',
    'AGE_25_34': '25–34',
    'AGE_35_44': '35–44',
    'AGE_45_PLUS': '45+',
  };

  final _genders = {
    'MALE': 'Male',
    'FEMALE': 'Female',
    'PREFER_NOT_TO_SAY': 'Prefer not to say',
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName ?? '');
    _currPassCtrl = TextEditingController();
    _newPassCtrl = TextEditingController();

    _selectedAgeRange = widget.user.ageRange;
    if (_selectedAgeRange != null &&
        !_ageRanges.containsKey(_selectedAgeRange)) {
      _selectedAgeRange = null;
    }

    _selectedGender = widget.user.gender;
    if (_selectedGender != null && !_genders.containsKey(_selectedGender)) {
      _selectedGender = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name cannot be empty.')));
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            displayName: name,
            ageRange: _selectedAgeRange,
            gender: _selectedGender,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _updatePassword() async {
    final current = _currPassCtrl.text;
    final newPass = _newPassCtrl.text;

    if (current.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill in both password fields.')));
      return;
    }
    if (newPass.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('New password must be at least 12 characters.')));
      return;
    }

    setState(() => _isSavingPassword = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updatePassword(current, newPass);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password updated. Please sign in again.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('User Profile',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      color: AppColors.gray,
                    )
                  ],
                ),
              ),
              const Divider(height: 1),

              // Profile Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('General Information',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: widget.user.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GlassDropdownField<String>(
                            initialValue: _selectedAgeRange,
                            labelText: 'Age Range',
                            items: _ageRanges.entries
                                .map((e) => GlassDropdownItem(
                                    value: e.key, label: e.value))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedAgeRange = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GlassDropdownField<String>(
                            initialValue: _selectedGender,
                            labelText: 'Gender',
                            items: _genders.entries
                                .map((e) => GlassDropdownItem(
                                    value: e.key, label: e.value))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedGender = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _isSavingProfile ? null : _updateProfile,
                        child: _isSavingProfile
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Security Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Security',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _isSavingPassword ? null : _updatePassword,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.charcoal,
                        ),
                        child: _isSavingPassword
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Update Password'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await ref.read(authControllerProvider.notifier).signOut();
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent),
                    label: const Text('Sign Out',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
