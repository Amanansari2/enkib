import 'package:flutter/material.dart';
import '../../../../../styles/app_styles.dart';

class TopUsersCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> imageUrls;

  TopUsersCard({
    required this.title,
    required this.subtitle,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    double totalWidth = imageUrls.isEmpty ? 0 : 40 + (imageUrls.length - 1) * 18.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyColor(context).withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: totalWidth,
              height: 40,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: List.generate(imageUrls.length, (index) {
                  return Positioned(
                    left: index * 18.0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.whiteColor,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: (imageUrls.isNotEmpty)
                            ? NetworkImage(imageUrls[index])
                            : AssetImage(AppImages.placeHolderImage) as ImageProvider<Object>,
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.mediumFont,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.regularFont,
                      color: AppColors.greyColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
