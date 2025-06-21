import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/localization/localization.dart';

class DisputeCard extends StatelessWidget {
  final String disputeId;
  final String name;
  final String dateCreated;
  final String reason;
  final String status;
  final Color statusColor;
  final Color statusColorBackground;
  final String profileImageUrl;

  const DisputeCard({
    Key? key,
    required this.disputeId,
    required this.name,
    required this.dateCreated,
    required this.reason,
    required this.status,
    required this.statusColor,
    required this.statusColorBackground,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text:"${Localization.translate("dispute_id")}",
                        style: TextStyle(
                          color: AppColors.blackColor.withOpacity(0.8),
                          fontSize: FontSize.scale(context, 18),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      TextSpan(
                        text: " ",
                      ),
                      TextSpan(
                        text: disputeId,
                        style: TextStyle(
                          color: AppColors.blackColor.withOpacity(0.8),
                          fontSize: FontSize.scale(context, 18),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColorBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor,
                      radius: 4,
                    ),
                     SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: FontSize.scale(context, 12),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  profileImageUrl,
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                        color: AppColors.blackColor.withOpacity(0.7),
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal
                    ),
                  ),
                ],
              ),
            ],
          ),
           SizedBox(height: 12),
          Row(
            children: [
              SvgPicture.asset(
                AppImages.bookingCalender,
                width: 15,
                height: 15,
                color: AppColors.greyColor(context),
              ),
               SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:"${Localization.translate("date_created")}",
                      style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal
                      ),
                    ),
                    TextSpan(
                      text: "  ",
                    ),

                    TextSpan(
                      text: dateCreated,
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

           SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(
                AppImages.reasonIcon,
                width: 15,
                height: 15,
                color: AppColors.greyColor(context),
              ),
              SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text:"${Localization.translate("reason")}",
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      TextSpan(
                        text: " "
                      ),
                      TextSpan(
                        text: reason,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
