import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../data/localization/localization.dart';

class CertificateCard extends StatelessWidget {
  final String imagePath;
  final String certificateTitle;
  final String institute;
  final String duration;
  final String issued;
  final String description;
  final bool showDivider;

  CertificateCard({
    required this.imagePath,
    required this.certificateTitle,
    required this.institute,
    required this.duration,
    required this.issued,
    required this.description,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = ValueNotifier<bool>(false);
    final words = description.split(RegExp(r'\s+'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (imagePath.isNotEmpty)
                  ? Image.network(
                      imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          AppImages.placeHolderImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      AppImages.placeHolderImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    certificateTitle,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontSize: FontSize.scale(context, 14),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.mediumFont,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppImages.bookEducationIcon,
                        width: 16,
                        height: 16,
                        color: AppColors.greyColor(context),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          institute,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.darkBlue,
                            fontSize: FontSize.scale(context, 13),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppImages.bookingCalender,
                        width: 16,
                        height: 16,
                        color: AppColors.greyColor(context),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          issued,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.darkBlue,
                            fontSize: FontSize.scale(context, 12),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                      ),
                      SizedBox(width: 2),
                      Text(
                        duration,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: AppColors.darkBlue,
                          fontSize: FontSize.scale(context, 12),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontFamily: AppFontFamily.mediumFont,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: isExpanded,
                    builder: (context, expanded, child) {
                      String displayedText = expanded || words.length <= 10
                          ? description
                          : words.take(10).join(' ') + '...';

                      return RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: AppFontFamily.regularFont,
                          ),
                          children: [
                            WidgetSpan(
                              child: HtmlWidget(
                                displayedText,
                                textStyle: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  fontFamily: AppFontFamily.regularFont,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' ',
                            ),
                            if (words.length > 10)
                              TextSpan(
                                text: expanded
                                    ? '${Localization.translate("show_less")}'
                                    : '${Localization.translate("read_more")}',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  fontFamily: AppFontFamily.regularFont,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    isExpanded.value = !expanded;
                                  },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (showDivider)
          Divider(
            color: AppColors.dividerColor,
          ),
        if (showDivider) SizedBox(height: 8),
      ],
    );
  }
}
