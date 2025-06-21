import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/bookSession/component/order_summary_bottom_sheet.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../detailPage/session_detail.dart';

class SessionCard extends StatefulWidget {
  final int slotsLeft;
  final int totalSlots;
  final int bookedSlots;
  final Color borderColor;
  final String description;
  final String sessionDate;
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> tutorProfile;
  final Function() onSessionUpdated;

  const SessionCard({
    Key? key,
    required this.slotsLeft,
    required this.totalSlots,
    required this.bookedSlots,
    required this.borderColor,
    required this.description,
    required this.sessionDate,
    required this.sessionData,
    required this.tutorProfile,
    required this.onSessionUpdated,
  }) : super(key: key);

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool isBooking = false;

  Future<void> _bookSession(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final String sessionId = widget.sessionData['id'].toString();


    print("Starting booking session ........");
    print("Token --------->>> $token");
    print("Session Id ------->>>> $sessionId");

    if (token != null) {
      try {
        setState(() {
          isBooking = true;
        });

        final Map<String, dynamic> data = {
          'slot_id': sessionId,
        };
          print("Request Data ---->>>>>> $data");
        final response = await bookSessionCart(token, data, sessionId);

        if (response['status'] == 200) {
          showCustomToast(context,
              response['message'] ?? '${Localization.translate("cart_items_fetched")}', true);
          await Future.delayed(Duration(milliseconds: 500));
          await _fetchBookingCart(context);
        }
        else if (response['status'] == 403) {
          showCustomToast(
            context,
            response['message'],
            false,
          );
        } else if (response['status'] == 401) {
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
        }
        else {
          showCustomToast(
              context, response['message'] ?? '${Localization.translate("failed_book_session")}', false);
        }
      } catch (e) {
        showCustomToast(context, '${Localization.translate("failed_book_session")} $e', false);
      } finally {
        setState(() {
          isBooking = false;
        });
      }
    } else {
      showCustomToast(context, '${Localization.translate("unauthorized_access")}', false);

    }
  }

  Future<void> _fetchBookingCart(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      try {
        final response = await getBookingCart(token);
        final sessions =
            List<Map<String, dynamic>>.from(response['data']['cartItems']);

        print("Session data --->>> $sessions");

        await showModalBottomSheet(
          backgroundColor: AppColors.sheetBackgroundColor,
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          builder: (context) => OrderSummaryBottomSheet(
            sessionData: widget.sessionData,
            profileDta: widget.tutorProfile,
            cartData: sessions,
          ),
        );

        widget.onSessionUpdated();
      } catch (e) {
        showCustomToast(context, '${Localization.translate("failed_book_session")} $e', false);

      }
    } else {
      showCustomToast(context, '${Localization.translate("unauthorized_access")}', false);

    }
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 1.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(overlayEntry);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMM, yyyy')
        .format(DateFormat('dd MMM yyyy').parse(widget.sessionDate));

    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? role = userData != null && userData['user'] != null
        ? userData['user']['role']
        : null;

    return Container(
      color: AppColors.greyColor(context),
      child: Card(
        elevation: 0,
        color: AppColors.whiteColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.sessionData['group']['name'] ?? '',
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 14),
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                ),
              ),
              SizedBox(height: 4),
              Text(
                widget.sessionData['subject']['name'] ?? '',
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  SvgPicture.asset(
                    AppImages.clockInsightIcon,
                    width: 14,
                    height: 14,
                    color: AppColors.greyColor(context),
                  ),
                  SizedBox(width: 4),
                  Text(
                    widget.sessionData['formatted_time_range'] ?? '',
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.font,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  SizedBox(width: 60),
                  SvgPicture.asset(
                    AppImages.sessionCart,
                    width: 14,
                    height: 14,
                    color: AppColors.greyColor(context),
                  ),
                  SizedBox(width: 5),
                  Text(
                    '${widget.sessionData['session_fee'] ?? ''}/${Localization.translate("session")}',
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.font,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  SvgPicture.asset(
                   AppImages.userIcon,
                    width: 14,
                    height: 14,
                    color: AppColors.greyColor(context),
                  ),
                  SizedBox(width: 5),
                  Text(
                    widget.slotsLeft > 0
                        ? '${widget.slotsLeft}/${widget.totalSlots} ${Localization.translate('slots_left')}'
                        : '${widget.bookedSlots}/${widget.totalSlots} ${Localization.translate('slots_booked')}',
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.font,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  if (role == 'student')
                    Expanded(
                    child: ElevatedButton(
                      onPressed: (isBooking || widget.slotsLeft <= 0)
                          ? null
                          : () => _bookSession(context),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return AppColors.fadeColor;
                          }
                          return AppColors.dividerColor;
                        }),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      child: isBooking
                          ? SpinKitCircle(
                                color: AppColors.primaryGreen(context),
                                size: 30,
                            )
                          : Text(
                        '${Localization.translate("book_sessions")}',
                              style: TextStyle(
                                color: widget.slotsLeft > 0
                                    ? AppColors.primaryGreen(context)
                                    : AppColors.greyColor(context).withOpacity(0.5),
                                fontSize: FontSize.scale(context, 14),
                                fontFamily: AppFontFamily.font,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SessionScreen(
                                  slotsLeft: widget.slotsLeft,
                                  totalSlots: widget.totalSlots,
                                  description: widget.description,
                                  sessionDate: formattedDate,
                                  sessionData: widget.sessionData,
                                  tutorProfileData: widget.tutorProfile)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.dividerColor,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 6.0),
                      ),
                      child: Text(
                        '${Localization.translate("view_detail")}',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.font,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
