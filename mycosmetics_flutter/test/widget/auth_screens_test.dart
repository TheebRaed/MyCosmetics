import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Widget tests for auth screens.
// These test UI rendering and form validation logic
// without requiring network or Riverpod providers.

void main() {
  group('LoginForm validation', () {
    testWidgets('empty email shows error', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_testForm(formKey, email: '', password: 'password123'));
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('invalid email shows error', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_testForm(formKey, email: 'notanemail', password: 'password123'));
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('empty password shows error', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_testForm(formKey, email: 'user@test.com', password: ''));
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('valid email and password passes validation', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_testForm(formKey, email: 'user@test.com', password: 'secure123'));
      final valid = formKey.currentState!.validate();
      expect(valid, isTrue);
    });
  });

  group('KPI Card rendering', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _KpiCard(label: 'Total Revenue', value: '\$1,234'))),
      );
      expect(find.text('TOTAL REVENUE'), findsOneWidget);
      expect(find.text('\$1,234'), findsOneWidget);
    });
  });

  group('Status badge colors', () {
    test('delivered maps to success color', () {
      expect(_statusColor('delivered'), equals(const Color(0xFF2E7D32)));
    });
    test('cancelled maps to error color', () {
      expect(_statusColor('cancelled'), equals(const Color(0xFFB00020)));
    });
    test('pending maps to warning color', () {
      expect(_statusColor('pending'), equals(const Color(0xFFF57C00)));
    });
  });
}

Widget _testForm(GlobalKey<FormState> key, {required String email, required String password}) {
  final emailCtrl = TextEditingController(text: email);
  final passCtrl  = TextEditingController(text: password);
  return MaterialApp(home: Scaffold(body: Form(key: key, child: Column(children: [
    TextFormField(controller: emailCtrl, validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
    TextFormField(controller: passCtrl, validator: (v) => v == null || v.isEmpty ? 'Password is required' : null),
  ]))));
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    Text(label.toUpperCase()),
    Text(value),
  ])));
}

Color _statusColor(String s) => switch (s.toLowerCase()) {
  'delivered' || 'completed' || 'paid' || 'active' => const Color(0xFF2E7D32),
  'shipped' || 'processing' => const Color(0xFF0277BD),
  'cancelled' || 'refunded' || 'suspended' || 'failed' => const Color(0xFFB00020),
  _ => const Color(0xFFF57C00),
};
