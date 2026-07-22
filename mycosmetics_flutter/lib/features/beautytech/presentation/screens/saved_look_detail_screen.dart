import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/beautytech_repository.dart';
import '../providers/beautytech_providers.dart';

/// Saved look detail -- rename, favorite toggle, delete (with confirmation
/// dialog, a destructive action per CLAUDE.md convention). The `SavedLook`
/// is passed via `extra` from the list screen (same pattern as
/// `order_confirmation_screen.dart` -- no separate re-fetch-by-id endpoint
/// exists on `SavedLookEndpoint`).
class SavedLookDetailScreen extends ConsumerStatefulWidget {
  const SavedLookDetailScreen({super.key, required this.look});

  final SavedLook look;

  @override
  ConsumerState<SavedLookDetailScreen> createState() => _SavedLookDetailScreenState();
}

class _SavedLookDetailScreenState extends ConsumerState<SavedLookDetailScreen> {
  late SavedLook _look;
  bool _renaming = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _look = widget.look;
    _nameController = TextEditingController(text: _look.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveRename() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _look.name) {
      setState(() => _renaming = false);
      return;
    }
    final error = await ref.read(savedLooksControllerProvider.notifier).rename(_look, newName);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      setState(() {
        _look = _look.copyWith(name: newName);
        _renaming = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final error = await ref.read(savedLooksControllerProvider.notifier).toggleFavorite(_look);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      setState(() => _look = _look.copyWith(isFavorite: !_look.isFavorite));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this look?'),
        content: const Text('This permanently removes the saved look. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await ref.read(savedLooksControllerProvider.notifier).delete(_look.id!);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final variantIds = parseAppliedVariantIds(_look.appliedVariantIds);

    return Scaffold(
      appBar: AppBar(
        title: _renaming
            ? TextField(
                controller: _nameController,
                autofocus: true,
                style: TextStyle(color: heading),
                onSubmitted: (_) => _saveRename(),
              )
            : Text(_look.name),
        actions: [
          IconButton(
            icon: Icon(_renaming ? Icons.check : Icons.edit_outlined),
            onPressed: () => _renaming ? _saveRename() : setState(() => _renaming = true),
          ),
          IconButton(
            icon: Icon(_look.isFavorite ? Icons.favorite : Icons.favorite_border, color: chipText),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                _look.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: muted.withValues(alpha: 0.12),
                  child: Icon(Icons.spa_outlined, size: 48, color: muted),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Applied products', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          if (variantIds.isEmpty)
            Text('No product variants recorded for this look.', style: TextStyle(color: muted))
          else
            AppCard(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: variantIds
                    .map((id) => Chip(label: Text('Variant #$id'), backgroundColor: chipText.withValues(alpha: 0.12)))
                    .toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete Look', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
