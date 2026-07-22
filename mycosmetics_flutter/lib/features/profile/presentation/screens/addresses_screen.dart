import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../checkout/presentation/widgets/address_form_sheet.dart';
import '../providers/profile_providers.dart';

/// Manage-addresses screen -- `/profile/addresses`. Real full CRUD via the
/// same `ProfileEndpoint` address methods checkout uses (see
/// profile_repository.dart), unlike checkout's inline radio-picker this is
/// a dedicated list/add/edit/delete screen.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    final draft = await showAddressFormSheet(context);
    if (draft == null) return;
    final error = await ref.read(profileAddressListProvider.notifier).add(draft);
    if (!context.mounted) return;
    if (error != null) _showMessage(context, error);
  }

  Future<void> _editAddress(BuildContext context, WidgetRef ref, Address address) async {
    final draft = await showAddressFormSheet(context, initial: address);
    if (draft == null) return;
    final error = await ref.read(profileAddressListProvider.notifier).updateAddress(draft);
    if (!context.mounted) return;
    if (error != null) _showMessage(context, error);
  }

  Future<void> _deleteAddress(BuildContext context, WidgetRef ref, Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Remove "${address.fullName}, ${address.city}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref.read(profileAddressListProvider.notifier).delete(address.id!);
    if (!context.mounted) return;
    if (error != null) _showMessage(context, error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    final asyncAddresses = ref.watch(profileAddressListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addAddress(context, ref),
        child: const Icon(Icons.add),
      ),
      body: asyncAddresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load your addresses", style: TextStyle(color: muted)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(profileAddressListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 48, color: muted),
                  const SizedBox(height: AppSpacing.sm),
                  Text('No saved addresses', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Add an address to speed up checkout.', style: TextStyle(color: muted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: addresses.length,
            itemBuilder: (context, i) {
              final address = addresses[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(address.fullName, style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                          ),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: chipText.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.chip),
                              ),
                              child: Text('Default', style: TextStyle(color: chipText, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(address.phone, style: TextStyle(color: muted, fontSize: 12)),
                      Text(
                        '${address.line1}${address.line2 != null ? ', ${address.line2}' : ''}, ${address.city}, ${address.country}',
                        style: TextStyle(color: muted),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _editAddress(context, ref, address),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteAddress(context, ref, address),
                            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                            label: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
