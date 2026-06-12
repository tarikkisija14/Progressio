

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/user_list.dart';
import 'package:progressio_mobile/providers/user_list_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';

Future<void> showAddToListSheet(
  BuildContext context, {
  required int contentId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddToListSheet(contentId: contentId),
  );
}

class _AddToListSheet extends StatefulWidget {
  final int contentId;
  const _AddToListSheet({required this.contentId});

  @override
  State<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<_AddToListSheet> {
  List<UserList> _lists = [];
  bool _loading = true;
  final Set<int> _adding = {};
  final Set<int> _added = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lists = await context.read<UserListProvider>().getMyLists();
      if (mounted) setState(() { _lists = lists; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(int listId) async {
    setState(() => _adding.add(listId));
    try {
      await context.read<UserListProvider>().addContent(listId, widget.contentId);
      if (mounted) setState(() { _adding.remove(listId); _added.add(listId); });
    } catch (e) {
      if (mounted) {
        setState(() => _adding.remove(listId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to list: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        top: 8, left: 20, right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Row(
            children: [
              const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Add to list',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_lists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const Icon(Icons.list_outlined, color: AppColors.textFaint, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    "You don't have any lists yet.",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Idealno navigate to Lists tab — ali samo zatvaramo
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Go to Lists to create one'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _lists.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.hairline, height: 1),
                itemBuilder: (_, i) {
                  final list = _lists[i];
                  final isAdding = _adding.contains(list.id);
                  final isDone = _added.contains(list.id);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.list_alt_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      list.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${list.itemCount} items${list.isPublic ? ' · Public' : ''}',
                      style: const TextStyle(
                          color: AppColors.textFaint, fontSize: 12),
                    ),
                    trailing: isDone
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 22)
                        : isAdding
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 2),
                              )
                            : TextButton(
                                onPressed: () => _add(list.id),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.primarySoft,
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Add',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}