import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:progressio_mobile/utils/app_colors.dart';

class ContentCard extends StatelessWidget {
  final int contentId;
  final String title;
  final String? coverImageUrl;
  final String? contentTypeName;
  final double avgRating;
  final VoidCallback? onTap;

  const ContentCard({
    super.key,
    required this.contentId,
    required this.title,
    this.coverImageUrl,
    this.contentTypeName,
    this.avgRating = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPoster(),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            if (contentTypeName != null) ...[
              const SizedBox(height: 3),
              Text(
                contentTypeName!,
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.premium, size: 11),
                    const SizedBox(width: 2),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.premium,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverImageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.movie_rounded, color: AppColors.textFaint, size: 32),
      ),
    );
  }
}