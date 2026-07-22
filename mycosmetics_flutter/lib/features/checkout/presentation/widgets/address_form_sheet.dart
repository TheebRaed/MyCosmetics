import 'package:flutter/material.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/pill_button.dart';

/// Bottom sheet form for adding or editing a shipping [Address] -- real,
/// persisted via `ProfileEndpoint.addAddress`/`updateAddress` (see
/// checkout_repository.dart / profile_repository.dart). Returns the
/// unsaved [Address] draft to the caller; the caller is responsible for the
/// actual `addAddress`/`updateAddress` call so it can show its own
/// loading/error state. Pass [initial] to pre-fill for editing -- the
/// returned draft preserves its `id`/`userId`/`createdAt` so the caller can
/// tell add from edit.
Future<Address?> showAddressFormSheet(BuildContext context, {Address? initial}) {
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddressFormSheet(initial: initial),
  );
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({this.initial});

  final Address? initial;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _fullName = TextEditingController(text: widget.initial?.fullName);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late final _line1 = TextEditingController(text: widget.initial?.line1);
  late final _line2 = TextEditingController(text: widget.initial?.line2);
  late final _city = TextEditingController(text: widget.initial?.city);
  late final _state = TextEditingController(text: widget.initial?.state);
  late final _postalCode = TextEditingController(text: widget.initial?.postalCode);
  late final _country = TextEditingController(text: widget.initial?.country);

  @override
  void dispose() {
    for (final c in [_fullName, _phone, _line1, _line2, _city, _state, _postalCode, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now().toUtc();
    final base = widget.initial;
    Navigator.of(context).pop(
      Address(
        id: base?.id,
        userId: base?.userId ?? 0, // overwritten server-side from the session in ProfileEndpoint.addAddress
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        line1: _line1.text.trim(),
        line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim().isEmpty ? null : _state.text.trim(),
        postalCode: _postalCode.text.trim().isEmpty ? null : _postalCode.text.trim(),
        country: _country.text.trim(),
        isDefault: base?.isDefault ?? false,
        createdAt: base?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initial == null ? 'New Address' : 'Edit Address', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              _field(_fullName, 'Full name'),
              _field(_phone, 'Phone'),
              _field(_line1, 'Address line 1'),
              _field(_line2, 'Address line 2 (optional)', required: false),
              _field(_city, 'City'),
              _field(_state, 'State (optional)', required: false),
              _field(_postalCode, 'Postal code (optional)', required: false),
              _field(_country, 'Country'),
              const SizedBox(height: AppSpacing.md),
              PillButton(label: widget.initial == null ? 'Save Address' : 'Update Address', expand: true, onPressed: _submit),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}
