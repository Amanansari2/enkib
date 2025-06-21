import 'package:flutter/material.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback buttonAction;
  final bool showCancelButton;

  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.buttonText,
    required this.buttonAction,
    this.showCancelButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 30.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.lightPinkColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.pinkColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppImages.loginRequired,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w400,
                fontFamily: AppFontFamily.font,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.greyColor(context).withOpacity(0.7),
                  fontSize: FontSize.scale(context, 14),
                  fontWeight: FontWeight.w400,
                  fontFamily: AppFontFamily.font,
                ),
              ),
            ),
            SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                double buttonWidth = constraints.maxWidth * (showCancelButton ? 0.45 : 1.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showCancelButton)
                      Container(
                        width: buttonWidth,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: AppColors.whiteColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: AppColors.dividerColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            '${Localization.translate("cancel")}',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 16),
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFontFamily.font,
                            ),
                          ),
                        ),
                      ),
                    if (showCancelButton)
                      SizedBox(width: 12),
                    Container(
                      width: buttonWidth,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppColors.primaryGreen(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          buttonAction();
                        },
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: FontSize.scale(context, Localization.textDirection == TextDirection.rtl? 13.0:16.0),
                            fontWeight: FontWeight.w800,
                            fontFamily: AppFontFamily.font,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
