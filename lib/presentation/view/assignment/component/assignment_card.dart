import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../data/localization/localization.dart';
import '../../../../styles/app_styles.dart';

class AssignmentCard extends StatelessWidget {
  final String title;
  final String deadline;
  final int totalMarks;
  final int passingGrade;
  final String category;
  final String imageUrl;
  final String? statusText;
  final bool showMoreIcon;
  final VoidCallback? onMorePressed;

  AssignmentCard({
    required this.title,
    required this.deadline,
    required this.totalMarks,
    required this.passingGrade,
    required this.category,
    required this.imageUrl,
    this.statusText,
    this.showMoreIcon = false,
    this.onMorePressed,
  });

  Color _getStatusCircleColor() {
    if (statusText != null) {
      if (statusText!.toLowerCase() == 'published') {
        return AppColors.darkGreen;
      } else if (statusText!.toLowerCase() == 'archived') {
        return AppColors.redColor;
      }
    }
    return AppColors.whiteColor;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        padding: EdgeInsets.all(5),
        margin: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
          top: 2.0,
          bottom: 10.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyColor(context).withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                AppImages.placeHolderImage,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                          : Image.asset(
                            AppImages.imagePlaceholder,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                ),
                if (statusText != null && statusText!.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusCircleColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            statusText!,
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: FontSize.scale(context, 12),
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                          ),
                          if (statusText!.toLowerCase().contains(
                            'attempted',
                          )) ...[
                            SizedBox(width: 6),
                            SvgPicture.asset(
                              AppImages.checkCircle,
                              width: 14,
                              height: 14,
                              color: AppColors.whiteColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 16),
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showMoreIcon)
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: onMorePressed,
                          ),
                      ],
                    ),
                  ],
                  if (category.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      category,
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontFamily: AppFontFamily.regularFont,
                      ),
                    ),
                  ],
                  if (deadline.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Row(
                      children: [
                        SvgPicture.asset(
                          AppImages.calendarIcon,
                          width: 18,
                          height: 18,
                        ),
                        SizedBox(width: 6),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "${deadline}",
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.normal,
                                  fontFamily: AppFontFamily.mediumFont,
                                ),
                              ),
                              TextSpan(
                                text: " ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "${(Localization.translate('deadline') ?? '').trim() != 'deadline' && (Localization.translate('deadline') ?? '').trim().isNotEmpty ? Localization.translate('deadline') : 'Deadline'}",
                                style: TextStyle(
                                  color: AppColors.greyColor(
                                    context,
                                  ).withOpacity(0.7),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  fontFamily: AppFontFamily.regularFont,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (totalMarks.toString().isNotEmpty) ...[
                        Row(
                          children: [
                            SvgPicture.asset(
                              AppImages.marksIcon,
                              width: 18,
                              height: 18,
                            ),
                            SizedBox(width: 6),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${totalMarks}",
                                    style: TextStyle(
                                      color: AppColors.greyColor(context),
                                      fontSize: FontSize.scale(context, 14),
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                      fontFamily: AppFontFamily.mediumFont,
                                    ),
                                  ),
                                  TextSpan(text: " "),
                                  TextSpan(
                                    text:
                                        "${(Localization.translate('total_marks') ?? '').trim() != 'total_marks' && (Localization.translate('total_marks') ?? '').trim().isNotEmpty ? Localization.translate('total_marks') : 'Total Marks'}",
                                    style: TextStyle(
                                      color: AppColors.greyColor(
                                        context,
                                      ).withOpacity(0.7),
                                      fontSize: FontSize.scale(context, 14),
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      fontFamily: AppFontFamily.regularFont,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (passingGrade.toString().isNotEmpty) ...[
                        Row(
                          children: [
                            SvgPicture.asset(
                              AppImages.identityVerification,
                              width: 18,
                              height: 18,
                            ),
                            SizedBox(width: 6),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${passingGrade}",
                                    style: TextStyle(
                                      color: AppColors.greyColor(context),
                                      fontSize: FontSize.scale(context, 14),
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                      fontFamily: AppFontFamily.mediumFont,
                                    ),
                                  ),
                                  TextSpan(text: " "),
                                  TextSpan(
                                    text:
                                        "${(Localization.translate('passing_grade') ?? '').trim() != 'passing_grade' && (Localization.translate('passing_grade') ?? '').trim().isNotEmpty ? Localization.translate('passing_grade') : 'Passing Grade'}",
                                    style: TextStyle(
                                      color: AppColors.greyColor(
                                        context,
                                      ).withOpacity(0.7),
                                      fontSize: FontSize.scale(context, 14),
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      fontFamily: AppFontFamily.regularFont,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
