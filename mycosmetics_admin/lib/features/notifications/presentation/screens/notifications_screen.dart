import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';

part 'notifications_screen.g.dart';

@riverpod
Future<List<AdminNotificationModel>> adminNotificationsList(Ref ref) async {
  final rows = await ref.watch(adminRepositoryProvider).listNotifications();
  return rows.map((r) => AdminNotificationModel.fromJson(r)).toList();
}

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  static const _audiences = [
    ('allUsers', 'All Users', Icons.people),
    ('selectedUsers', 'Selected Users', Icons.person_search),
    ('byCategory', 'By Category', Icons.category_outlined),
    ('byPurchaseHistory', 'By Purchase History', Icons.shopping_bag_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminNotificationsListProvider);
    return Padding(
      padding: AdminSpacing.pagePadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AdminPageHeader(
          title: 'Notifications',
          subtitle: 'Push notification campaigns',
          actions: [ElevatedButton.icon(onPressed: () => _showCreate(context, ref), icon: const Icon(Icons.add, size: 18), label: const Text('Create Notification'))],
        ),
        Expanded(child: async.when(
          loading: () => const AdminLoading(),
          error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(adminNotificationsListProvider)),
          data: (list) => list.isEmpty
              ? const AdminEmpty(message: 'No notifications yet', icon: Icons.notifications_outlined)
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _NotifCard(n: list[i]),
                ),
        )),
      ]),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final bodyCtrl  = TextEditingController();
    String audience = 'allUsers';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (_, ss) => AlertDialog(
      title: const Text('Create Notification'),
      content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title'), maxLength: 80),
        const SizedBox(height: 12),
        TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Message'), maxLines: 3, maxLength: 250),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: audience, decoration: const InputDecoration(labelText: 'Audience'),
          items: _audiences.map((a) => DropdownMenuItem(value: a.$1, child: Row(children: [Icon(a.$3, size: 18), const SizedBox(width: 8), Text(a.$2)]))).toList(),
          onChanged: (v) => ss(() => audience = v!),
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            await ref.read(adminRepositoryProvider).createNotification(title: titleCtrl.text.trim(), body: bodyCtrl.text.trim(), audience: audience);
            ref.invalidate(adminNotificationsListProvider);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification created!')));
          },
          child: const Text('Send / Schedule'),
        ),
      ],
    ))).whenComplete(() { titleCtrl.dispose(); bodyCtrl.dispose(); });
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n});
  final AdminNotificationModel n;

  Color get _statusColor => switch (n.status) {
    'sent' => AdminColors.success, 'failed' => AdminColors.error,
    'scheduled' => AdminColors.info, _ => AdminColors.textSec,
  };

  IconData get _audienceIcon => switch (n.audience) {
    'allUsers' => Icons.people, 'selectedUsers' => Icons.person_search,
    'byCategory' => Icons.category_outlined, _ => Icons.shopping_bag_outlined,
  };

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: AdminSpacing.cardPadding,
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AdminColors.blush, borderRadius: BorderRadius.circular(10)), child: Icon(_audienceIcon, color: AdminColors.primary)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(n.title, style: AdminTextStyles.title.copyWith(fontSize: 15)),
                const SizedBox(width: 8),
                AdminStatusBadge(label: n.status.toUpperCase(), color: _statusColor),
              ]),
              Text(n.body, style: AdminTextStyles.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${n.audience} · ${n.recipientCount} recipients · ${n.createdAt.substring(0, 10)}', style: AdminTextStyles.caption),
            ])),
          ]),
        ),
      );
}
