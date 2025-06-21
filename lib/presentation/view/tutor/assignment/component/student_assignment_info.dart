import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../data/localization/localization.dart';

class StudentSubmitInfo extends StatelessWidget {
  final String name;
  final String email;
  final String obtainedMarks;
  final String statusText;
  final String submitDate;
  final String imageUrl;

  const StudentSubmitInfo({
    Key? key,
    required this.name,
    required this.email,
    required this.obtainedMarks,
    required this.statusText,
    required this.submitDate,
    required this.imageUrl,
  }) : super(key: key);

  Color _getStatusCircleColor() {
    if (statusText.toLowerCase() == 'pass') {
      return AppColors.darkGreen;
    } else if (statusText.toLowerCase() == 'fail') {
      return AppColors.redColor;
    } else if (statusText.toLowerCase() == 'in review') {
      return AppColors.yellowColor;
    }
    return AppColors.whiteColor;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    image: DecorationImage(
                      image:
                          (imageUrl.isNotEmpty)
                              ? NetworkImage(imageUrl)
                              : AssetImage(AppImages.placeHolderImage)
                                  as ImageProvider<Object>,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Localization.textDirection == TextDirection.rtl
                              ? SvgPicture.asset(
                                AppImages.arrowTopLeft,
                                width: 15,
                                height: 15,
                                color: AppColors.greyColor(context),
                              )
                              : SvgPicture.asset(
                                AppImages.arrowTopRight,
                                width: 20,
                                height: 20,
                                color: AppColors.greyColor(context),
                              ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            Row(
              children: [
                SvgPicture.asset(
                  AppImages.obtainMarks,
                  width: 15,
                  height: 15,
                  color: AppColors.greyColor(context),
                ),
                SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${obtainedMarks}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.mediumFont,
                          color: AppColors.greyColor(context),
                        ),
                      ),
                      TextSpan(
                        text:
                            "${(Localization.translate('total_number') ?? '').trim() != 'total_number' && (Localization.translate('total_number') ?? '').trim().isNotEmpty ? Localization.translate('total_number') : '/100'}",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.mediumFont,
                          color: AppColors.greyColor(context),
                        ),
                      ),
                      TextSpan(text: " "),
                      TextSpan(
                        text:
                            "${(Localization.translate('obtained_marks') ?? '').trim() != 'obtained_marks' && (Localization.translate('obtained_marks') ?? '').trim().isNotEmpty ? Localization.translate('obtained_marks') : 'Obtained Marks'}",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          color: AppColors.greyColor(context).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                if (statusText.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: AppColors.dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                          statusText,
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 12),
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                SvgPicture.asset(
                  AppImages.calendarIcon,
                  width: 15,
                  height: 15,
                  color: AppColors.greyColor(context),
                ),
                SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${submitDate}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.mediumFont,
                          color: AppColors.greyColor(context),
                        ),
                      ),
                      TextSpan(text: " "),
                      TextSpan(
                        text:
                            "${(Localization.translate('submit_date') ?? '').trim() != 'submit_date' && (Localization.translate('submit_date') ?? '').trim().isNotEmpty ? Localization.translate('submit_date') : 'Submit Date'}",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          color: AppColors.greyColor(context).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
