import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../core/router/admin_router.dart';
import '../providers/auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _State();
}
class _State extends ConsumerState<AdminLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _loading = false, _obscure = true;

  @override void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final err = await ref.read(adminAuthProvider.notifier).login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AdminColors.error));
    } else {
      context.go(AdminRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(children: [
      if (MediaQuery.of(context).size.width >= 900)
        Expanded(child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [AdminColors.primary, Color(0xFFC2185B)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.spa, color: Colors.white, size: 64),
            SizedBox(height: 20),
            Text('MyCosmetics', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            Text('Enterprise Admin Dashboard', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ])),
        )),
      Expanded(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Welcome Back', style: AdminTextStyles.headline),
          const SizedBox(height: 6),
          const Text('Sign in to access the admin dashboard', style: AdminTextStyles.subtitle),
          const SizedBox(height: 32),
          TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _pass, obscureText: _obscure,
            decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure))),
            validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
            onFieldSubmitted: (_) => _submit()),
          const SizedBox(height: 28),
          ElevatedButton(onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In')),
          const SizedBox(height: 16),
          const Text('Admin, Staff, and Manager roles only.', style: AdminTextStyles.caption, textAlign: TextAlign.center),
        ]))),
      ))),
    ]),
  );
}
