import 'package:flutter/material.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/pill_button.dart';

/// Bottom sheet for writing a review on a delivered order item -- real,
/// persisted via `ReviewEndpoint.add` (see orders_repository.dart). Only
/// collects rating + comment; eligibility (Delivered order, not already
/// reviewed) is enforced server-side in `ReviewService.add`, and any
/// rejection surfaces back through the caller's error handling.
Future<({int rating, String? comment})?> showWriteReviewSheet(BuildContext context, {required String productLabel}) {
  return showModalBottomSheet<({int rating, String? comment})>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _WriteReviewSheet(productLabel: productLabel),
  );
}

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({required this.productLabel});

  final String productLabel;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Write a Review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.productLabel, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(5, (i) {
              final starValue = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = starValue),
                icon: Icon(
                  starValue <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 32,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Submit Review',
            expand: true,
            onPressed: () => Navigator.of(context).pop((
              rating: _rating,
              comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
            )),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
