import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';

/// Static content screen -- `/profile/help`. No backend concept exists for
/// a support ticket/FAQ system, so this is a plain FAQ list rather than a
/// faked support inbox.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = [
    (
      'How do I track my order?',
      'Go to Profile > Orders and tap an order to see its live status and tracking timeline.',
    ),
    (
      'Can I cancel an order?',
      'Orders can be cancelled from the order detail screen while they are still Pending or Processing.',
    ),
    (
      'How do I return a delivered item?',
      'Returns are handled after delivery -- contact support with your order number for now.',
    ),
    (
      'What payment methods are supported?',
      'Cash on Delivery is available at checkout today; card payments are coming soon.',
    ),
    (
      'How do I write a product review?',
      'Once an order is marked Delivered, open it from Profile > Orders and tap "Write a review" on any item.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _faqs.length,
        itemBuilder: (context, i) {
          final (question, answer) = _faqs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question, style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(answer, style: TextStyle(color: muted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
