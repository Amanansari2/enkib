import 'package:flutter/material.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/notification/skeleton/notification_skeleton.dart';
import 'package:provider/provider.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../styles/app_styles.dart';
import '../auth/login_screen.dart';
import '../bookings/bookings.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import 'component/notification_card.dart';

class NotificationListing extends StatefulWidget {
  const NotificationListing({super.key});

  @override
  State<NotificationListing> createState() => _NotificationListingState();
}

class _NotificationListingState extends State<NotificationListing> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  String? markingNotificationId;
  bool isMarkingAllRead = false;
  int currentPage = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  int unreadCount = 0;
  int total = 0;
  int totalNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool isLoadMore = false}) async {
    if (isLoadMore && (isLoadingMore || currentPage > totalPages)) {
      return;
    }

    try {
      if (isLoadMore) {
        setState(() {
          isLoadingMore = true;
        });
      } else {
        setState(() {
          isLoading = true;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      Map<String, dynamic> response =
          await getAllNotifications(token, page: currentPage);

      if (response['status'] == 200) {
        if (response.containsKey('data') &&
            response['data'].containsKey('list')) {
          setState(() {
            List<Map<String, dynamic>> newNotifications = response['data']
                    ['list']
                .map<Map<String, dynamic>>((notification) {
              return {
                'id': notification['id'],
                'title': notification['data']['subject'],
                'subtitle': notification['data']['content'],
                'time': notification['created_at'],
                'hasLink': notification['data']['has_link'] ?? false,
                'linkText': notification['data']['link_text'] ?? "",
                'notificationLogo': notification['icon'] ?? "",
                'isRead': notification['is_read'] ?? true,
              };
            }).toList();

            notifications.addAll(newNotifications);
            totalPages = response['data']['pagination']['totalPages'];
            currentPage++;
            unreadCount = notifications.where((n) => !(n['isRead'] ?? true)).length;
            totalNotificationsCount = response['data']['pagination']['total'];

          });
        }
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate('invalidToken'),
              content: Localization.translate('loginAgain'),
              buttonText: Localization.translate('goToLogin'),
              buttonAction: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              showCancelButton: false,
            );
          },
        );
        isLoading = false;
        isLoadingMore = false;
      }
    } catch (e) {
    } finally {
      setState(() {
        isLoadingMore = false;
        isLoading = false;
      });
    }
  }


  void onNotificationTap(
      BuildContext context, Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'] ?? true;
    final bool hasLink = notification['hasLink'] ?? false;
    final String linkText = notification['linkText'] ?? '';

    if (!isRead) {
      markNotificationAsRead(notification['id']);
    }
    if (hasLink && linkText == "View Booking") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(),
        ),
      );
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (markingNotificationId != null) return;

    setState(() {
      markingNotificationId = notificationId;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      Map<String, dynamic> response = await markReadNotification(
        token: token,
        notificationId: notificationId,
      );

      if (response['status'] == 200) {
        setState(() {
          for (var notification in notifications) {
            if (notification['id'] == notificationId) {
              notification['isRead'] = true;
              unreadCount--;

              break;
            }
          }
        });
        showCustomToast(context, response['message'], true);
      } else if (response['status'] == 403) {
        showCustomToast(context, response['message'], false);
      } else if (response['status'] == 400) {
        showCustomToast(context, response['message'], false);
      } else if (response['status'] == 401) {
        showCustomToast(
            context, '${Localization.translate("unauthorized_access")}', false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate('invalidToken'),
              content: Localization.translate('loginAgain'),
              buttonText: Localization.translate('goToLogin'),
              buttonAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              showCancelButton: false,
            );
          },
        );
      } else {
        showCustomToast(context, response['message'], false);
      }
    } catch (e) {
    } finally {
      setState(() {
        markingNotificationId = null;
      });
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    setState(() {
      isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      Map<String, dynamic> response = await readAllNotifications(token: token);

      if (response['status'] == 200) {
        setState(() {
          for (var notification in notifications) {
            notification['isRead'] = true;
          }
          unreadCount = 0;

        });
        showCustomToast(context, response['message'], true);
      } else if (response['status'] == 403) {
        showCustomToast(context, response['message'], false);
      } else if (response['status'] == 401) {
        showCustomToast(
            context, '${Localization.translate("unauthorized_access")}', false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate('invalidToken'),
              content: Localization.translate('loginAgain'),
              buttonText: Localization.translate('goToLogin'),
              buttonAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              showCancelButton: false,
            );
          },
        );
      } else {
        showCustomToast(context, response['message'], false);
      }
    } catch (e) {
    } finally {
      fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
        builder: (context, connectivityProvider, _) {
      if (!connectivityProvider.isConnected) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor(context),
          body: Center(
            child: InternetAlertDialog(
              onRetry: () async {
                await connectivityProvider.checkInitialConnection();
              },
            ),
          ),
        );
      }
      return WillPopScope(
        onWillPop: () async {
          if (isLoading) {
            return false;
          } else {
            return true;
          }
        },
        child: Directionality(
          textDirection: Localization.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor(context),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(70.0),
              child: Container(
                color: AppColors.whiteColor,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: AppBar(
                    backgroundColor: AppColors.whiteColor,
                    forceMaterialTransparency: true,
                    elevation: 0,
                    titleSpacing: 0,
                    title: notifications.isNotEmpty && notifications.where((n) => !(n['isRead'] ?? true)).isNotEmpty
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(Localization.translate('notification') ?? '').trim() != 'notification' &&
                              (Localization.translate('notification') ?? '').trim().isNotEmpty
                              ? Localization.translate('notification')
                              : 'Notification'}',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: FontSize.scale(context, 20),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                          ),
                        ),

                        if (notifications.where((n) => !(n['isRead'] ?? true)).isNotEmpty)...[
                          const SizedBox(height: 3),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${(Localization.translate('unread_notification') ?? '').trim() != 'unread_notification' &&
                                      (Localization.translate('unread_notification') ?? '').trim().isNotEmpty
                                      ? Localization.translate('unread_notification')
                                      : 'Unread Notification:'}',
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 12),
                                    fontFamily: AppFontFamily.mediumFont,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ',
                                ),
                                TextSpan(
                                  text: '${unreadCount}/${totalNotificationsCount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: FontSize.scale(context, 12),
                                    fontFamily: AppFontFamily.regularFont,
                                    color: AppColors.greyColor(context).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    )
                        : Text(
                      '${(Localization.translate('notification') ?? '').trim() != 'notification' &&
                          (Localization.translate('notification') ?? '').trim().isNotEmpty
                          ? Localization.translate('notification')
                          : 'Notification'}',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSize.scale(context, 20),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                      ),
                    ),

                    leading: Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.arrow_back_ios,
                            size: 20, color: AppColors.blackColor),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: TextButton(
                          onPressed: isLoading ||
                                  notifications.every((n) => n['isRead'] ?? true)
                              ? null
                              : markAllNotificationsAsRead,
                          child: Text(
                            '${
                                (Localization.translate('mark_all_read') ?? '').trim() != 'mark_all_read' &&
                                    (Localization.translate('mark_all_read') ?? '').trim().isNotEmpty
                                    ? Localization.translate('mark_all_read')
                                    : 'Mark all as read'
                            }',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isLoading ||
                                      notifications
                                          .every((n) => n['isRead'] ?? true)
                                  ? AppColors.greyColor(context).withOpacity(0.5)
                                  : AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: AppFontFamily.regularFont,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                    centerTitle: false,
                  ),
                ),
              ),
            ),
            body: isLoading
                ? NotificationListingSkeleton()
                : notifications.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 55.0, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${
                                    (Localization.translate('caught_up') ?? '').trim() != 'caught_up' &&
                                        (Localization.translate('caught_up') ?? '').trim().isNotEmpty
                                        ? Localization.translate('caught_up')
                                        : 'You’re all caught up! 🎉'
                                }',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.blackColor.withOpacity(0.8),
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${
                                    (Localization.translate('stay_tuned') ?? '').trim() != 'stay_tuned' &&
                                        (Localization.translate('stay_tuned') ?? '').trim().isNotEmpty
                                        ? Localization.translate('stay_tuned')
                                        : 'Stay tuned for updates. Have a great day!'
                                }',
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
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              !isLoadingMore) {
                            fetchNotifications(isLoadMore: true);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                              top: 10, left: 10, right: 10, bottom: 30),
                          itemCount: isLoadingMore
                              ? notifications.length + 1
                              : notifications.length,
                          itemBuilder: (context, index) {
                            if (index == notifications.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 10.0,left: 10,top: 10,bottom: 30),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryGreen(context),
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              );
                            }

                            final notification = notifications[index];
                            final bool hasLink = notification['hasLink'] ?? false;
                            final String linkText = notification['linkText'] ?? "";

                            return NotificationCard(
                              notification: notification,
                              isLoading:
                                  markingNotificationId == notification['id'],
                              onMarkAsRead: markNotificationAsRead,
                              onNotificationTap: (notif) {
                                if (hasLink && linkText == "View Booking") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingScreen(),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ),
      );
      }
    );
  }
}
