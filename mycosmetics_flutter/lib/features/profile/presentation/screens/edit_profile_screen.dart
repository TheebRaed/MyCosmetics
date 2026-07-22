import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../providers/profile_providers.dart';

/// Edit Profile -- `/profile/edit`. Real via `ProfileEndpoint.updateProfile`
/// (see profile_repository.dart). Only full name is editable -- email isn't
/// (no `updateEmail` on `ProfileEndpoint`, and changing an auth login
/// identifier is a security-sensitive flow that isn't wired up), and
/// avatar upload isn't wired (see profile_repository.dart doc comment).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await ref.read(profileControllerProvider.notifier).updateFullName(_fullNameController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    _showMessage(error ?? 'Profile updated.');
    if (error == null) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    final asyncProfile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: asyncProfile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text("Couldn't load your profile", style: TextStyle(color: muted))),
        data: (user) {
          if (!_initialized) {
            _fullNameController.text = user.fullName;
            _initialized = true;
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email', style: TextStyle(color: muted, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(user.email, style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PillButton(
                    label: _saving ? 'Saving...' : 'Save Changes',
                    expand: true,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
