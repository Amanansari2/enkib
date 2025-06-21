import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../data/localization/localization.dart';
import '../../../../styles/app_styles.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final Function(String) onMarkAsRead;
  final bool isLoading;
  final Function(Map<String, dynamic>) onNotificationTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkAsRead,
    required this.isLoading,
    required this.onNotificationTap,

  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.containsKey('isRead') ? notification['isRead'] : true;
    final bool hasLink = notification.containsKey('hasLink') ? notification['hasLink'] : false;
    final String linkText = notification.containsKey('linkText') ? notification['linkText'] : "";
    final String icon = notification.containsKey('notificationLogo') ? notification['notificationLogo'] : "";
    bool isSvg = icon.toLowerCase().endsWith('.svg');

    Widget iconWidget;

    if (icon.isNotEmpty) {
      iconWidget = isSvg
          ? SvgPicture.network(
        icon,
        width: 30,
        height: 30,
        placeholderBuilder: (context) => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen(context),
            strokeWidth: 2.0,
          ),
        ),
      )
          : Image.network(
        icon,
        width: 30,
        height: 30,
      );
    } else {
      iconWidget = SvgPicture.asset(
        AppImages.notificationLogo,
        width: 30,
        height: 30,
      );
    }
    return GestureDetector(
      onTap: () {
        if (!isRead && !isLoading) {
          onMarkAsRead(notification['id']);
        }
        if (hasLink && linkText == "View Booking") {
          onNotificationTap(notification);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                iconWidget,
                if (isRead)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.whiteColor.withOpacity(0.4),
                          blurRadius: 5,
                          spreadRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: TextStyle(
                            color: isRead
                                ? AppColors.blackColor.withOpacity(0.7)
                                : AppColors.blackColor,
                            fontFamily: isRead
                                ? AppFontFamily.regularFont
                                : AppFontFamily.mediumFont,
                            fontWeight:
                                isRead ? FontWeight.w400 : FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontSize: FontSize.scale(context, 14),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            notification['time'],
                            style: TextStyle(
                              color: AppColors.blackColor.withOpacity(0.6),
                              fontSize: FontSize.scale(context, 12),
                              fontFamily: AppFontFamily.regularFont,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          if (!isRead)
                            Padding(
                              padding: EdgeInsets.only(left: Localization.textDirection ==
                                  TextDirection.rtl
                                  ? 0.0: 6.0,right: Localization.textDirection ==
                                  TextDirection.rtl
                                  ?  4.0:0.0),
                              child: Icon(Icons.circle,
                                  size: 10, color: AppColors.notificationColor),
                            ),
                        ],
                      ),
                      isLoading
                          ? Padding(
                        padding:  EdgeInsets.only(left:  Localization.textDirection ==
                            TextDirection.rtl
                            ? 0.0:8.0,right:  Localization.textDirection ==
                            TextDirection.rtl
                            ? 8.0:0.0),
                            child: SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen(context),
                                ),
                              ),
                          )
                          : SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['subtitle'],
                    style: TextStyle(
                      color: AppColors.blackColor.withOpacity(0.6),
                      fontSize: FontSize.scale(context, 12),
                      fontFamily: AppFontFamily.regularFont,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
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
