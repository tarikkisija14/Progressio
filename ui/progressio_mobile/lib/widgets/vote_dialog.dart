import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/character.dart';
import 'package:progressio_mobile/providers/vote_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';

Future<void> showVoteDialog(
  BuildContext context, {
  required List<Character> characters,
  int? episodeId,
  int? chapterId,
  String label = 'Pick your favourite character!',
}) async {
  if (characters.isEmpty) return;

  final selectedCharacter = await showDialog<Character>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: characters.length,
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.divider,
              height: 1,
            ),
            itemBuilder: (_, index) {
              final character = characters[index];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.backgroundRaised,
                  backgroundImage: character.imageUrl != null &&
                          character.imageUrl!.isNotEmpty
                      ? NetworkImage(character.imageUrl!)
                      : null,
                  child: character.imageUrl == null ||
                          character.imageUrl!.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.textFaint,
                        )
                      : null,
                ),
                title: Text(
                  character.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: character.isMainCharacter
                    ? const Text(
                        'Main character',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.of(dialogContext).pop(character);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Skip'),
          ),
        ],
      );
    },
  );

  if (selectedCharacter == null || !context.mounted) return;

  try {
    await context.read<VoteProvider>().vote(
          characterId: selectedCharacter.id,
          episodeId: episodeId,
          chapterId: chapterId,
        );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vote saved for ${selectedCharacter.name}.'),
        backgroundColor: AppColors.success,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not save vote.'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}