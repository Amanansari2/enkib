import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../data/localization/localization.dart';

class CustomAssignmentDialog extends StatelessWidget {
  final VoidCallback buttonAction;

  const CustomAssignmentDialog({Key? key, required this.buttonAction})
    : super(key: key);

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppImages.assignmentAlertIcon,
              width: 65,
              height: 65,
            ),
            SizedBox(height: 15),
            Text(
              "${(Localization.translate('ready_to_start_assignment') ?? '').trim() != 'ready_to_start_assignment' && (Localization.translate('ready_to_start_assignment') ?? '').trim().isNotEmpty ? Localization.translate('ready_to_start_assignment') : 'Ready to Start Assignment?'}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontWeight: FontWeight.w500,
                fontFamily: AppFontFamily.mediumFont,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "${(Localization.translate('start_the_assignment_now') ?? '').trim() != 'start_the_assignment_now' && (Localization.translate('start_the_assignment_now') ?? '').trim().isNotEmpty ? Localization.translate('start_the_assignment_now') : 'Start the Assignment now? The timer will begin, and progress will be tracked.'}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 14),
                  fontWeight: FontWeight.w400,
                  fontFamily: AppFontFamily.regularFont,
                ),
              ),
            ),
            SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                double buttonWidth = MediaQuery.of(context).size.width * 0.35;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                      ),
                    ),
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
                          "${(Localization.translate('start_assignment') ?? '').trim() != 'start_assignment' && (Localization.translate('start_assignment') ?? '').trim().isNotEmpty ? Localization.translate('start_assignment') : 'Start Assignment'}",
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFontFamily.mediumFont,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
