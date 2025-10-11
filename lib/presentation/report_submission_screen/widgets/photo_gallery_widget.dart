import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class PhotoGalleryWidget extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback? onAddPhoto;
  final Function(int)? onRemovePhoto;
  final int maxPhotos;

  const PhotoGalleryWidget({
    super.key,
    required this.imageUrls,
    this.onAddPhoto,
    this.onRemovePhoto,
    this.maxPhotos = 5,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'photo_library',
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                l10n.report_additionalPhotos,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${imageUrls.length}/$maxPhotos',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          Text(
            l10n.report_addPhotoHint,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Photo grid
          if (imageUrls.isEmpty)
            _buildEmptyState(l10n)
          else
            SizedBox(
              height: 25.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length +
                    (imageUrls.length < maxPhotos ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == imageUrls.length) {
                    return _buildAddPhotoCard(l10n);
                  }
                  return _buildPhotoThumbnail(imageUrls[index], index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(String imageUrl, int index) {
    return Container(
      width: 30.w,
      height: 25.h,
      margin: EdgeInsets.only(right: 2.w),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomImageWidget(
              imageUrl: imageUrl,
              width: 30.w,
              height: 25.h,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 1.w,
            right: 1.w,
            child: GestureDetector(
              onTap: () => onRemovePhoto?.call(index),
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 1.w,
            left: 1.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoCard(AppLocalizations l10n) {
    return GestureDetector(
      onTap: onAddPhoto,
      child: Container(
        width: 30.w,
        height: 25.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'add_a_photo',
              color: AppTheme.lightTheme.primaryColor,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              l10n.report_addPhoto,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              '${maxPhotos - imageUrls.length} ${l10n.report_photosLeft}',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 20.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'photo_library',
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.4,
            ),
            size: 32,
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.report_noAdditionalPhotos,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          GestureDetector(
            onTap: onAddPhoto,
            child: Text(
              l10n.report_tapToAddPhotos,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
