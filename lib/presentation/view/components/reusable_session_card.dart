import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../auth/login_screen.dart';
import '../bookSession/component/order_summary_bottom_sheet.dart';
import '../bookings/bookings.dart';
import '../detailPage/session_detail.dart';
import 'login_required_alert.dart';

class SessionCard extends StatefulWidget {
  final int slotsLeft;
  final int totalSlots;
  final int bookedSlots;
  final Color borderColor;
  final String description;
  final String sessionDate;
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> tutorDetail;
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
    required this.tutorDetail,
    required this.onSessionUpdated,
  }) : super(key: key);

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool isBooking = false;
  bool isFreeBooking = false;
  String paymentEnabled = "no";

  Future<Map<String, dynamic>> _bookFreeSession(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final String sessionId = widget.sessionData['id'].toString();

    if (token != null) {
      try {
        setState(() {
          isFreeBooking = true;
        });

        final Map<String, dynamic> data = {'slot_id': sessionId};

        final response = await bookFreeSession(token, data, sessionId);

        if (response['status'] == 200) {
          showCustomToast(
            context,
            response['message'] ??
                '${Localization.translate("cart_items_fetched")}',
            true,
          );
          await Future.delayed(Duration(milliseconds: 200));
          await _fetchBookingCart(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookingScreen()),
          );
        } else if (response['status'] == 403 || response['status'] == 400) {
          showCustomToast(context, response['message'], false);
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
        } else {
          showCustomToast(
            context,
            response['message'] ??
                '${Localization.translate("failed_book_session")}',
            false,
          );
        }

        return response;
      } catch (e) {
        final errorMessage =
            '${Localization.translate("failed_book_session")} $e';
        final Map<String, dynamic> errorResponse = {
          'status': 500,
          'message': errorMessage,
        };
        showCustomToast(context, errorMessage, false);
        return errorResponse;
      } finally {
        setState(() {
          isFreeBooking = false;
        });
      }
    } else {
      final errorResponse = {
        'status': 401,
        'message': '${Localization.translate("unauthorized_access")}',
      };
      return errorResponse;
    }
  }

  Future<void> _bookSession(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final String sessionId = widget.sessionData['id'].toString();

    if (token != null) {
      try {
        setState(() {
          isBooking = true;
        });

        final Map<String, dynamic> data = {'slot_id': sessionId};

        final response = await bookSessionCart(token, data, sessionId);

        if (response['status'] == 200) {
          showCustomToast(
            context,
            response['message'] ??
                '${Localization.translate("cart_items_fetched")}',
            true,
          );
          await Future.delayed(Duration(milliseconds: 500));
          await _fetchBookingCart(context);
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);
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
        } else {
          showCustomToast(
            context,
            response['message'] ??
                '${Localization.translate("failed_book_session")}',
            false,
          );
        }
      } catch (e) {
        showCustomToast(
          context,
          '${Localization.translate("failed_book_session")} $e',
          false,
        );
      } finally {
        setState(() {
          isBooking = false;
        });
      }
    } else {
      showCustomToast(
        context,
        '${Localization.translate("unauthorized_access")}',
        false,
      );
    }
  }

  Future<void> _fetchBookingCart(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      try {
        final response = await getBookingCart(token);

        final Map<String, dynamic> cartData = Map<String, dynamic>.from(
          response['data'],
        );

        final List<Map<String, dynamic>> cartItems =
            (cartData['cartItems'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

        if (paymentEnabled == "yes") {
          await showModalBottomSheet(
            backgroundColor: AppColors.sheetBackgroundColor,
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder:
                (context) => OrderSummaryBottomSheet(
                  sessionData: widget.sessionData,
                  profileDta: widget.tutorDetail,
                  cartData: cartItems,
                  total: cartData['total'],
                  subtotal: cartData['subtotal'],
                ),
          );
        }
        widget.onSessionUpdated();
      } catch (e) {
        showCustomToast(
          context,
          '${Localization.translate("failed_book_session")} $e',
          false,
        );
      }
    } else {
      showCustomToast(
        context,
        '${Localization.translate("unauthorized_access")} ',
        false,
      );
    }
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 1.0,
            left: 16.0,
            right: 16.0,
            child: CustomToast(message: message, isSuccess: isSuccess),
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
    String formattedDate = DateFormat(
      'dd MMM, yyyy',
    ).format(DateFormat('dd MMM yyyy').parse(widget.sessionDate));

    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final userData = authProvider.userData;
    final userId = authProvider.userId;
    final String? role =
        userData != null && userData['user'] != null
            ? userData['user']['role']
            : null;

    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'];

    return Container(
      color: AppColors.greyColor(context),
      child: Card(
        elevation: 0,
        color: AppColors.whiteColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                  fontFamily: AppFontFamily.mediumFont,
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
                  fontFamily: AppFontFamily.mediumFont,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  SvgPicture.asset(
                    AppImages.clockInsightIcon,
                    width: 16,
                    height: 16,
                    color: AppColors.greyColor(context),
                  ),
                  SizedBox(width: 4),
                  Text(
                    widget.sessionData['formatted_time_range'] ?? '',
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.mediumFont,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  if (paymentEnabled == "yes") ...[
                    SizedBox(width: 50),
                    SvgPicture.asset(
                      AppImages.cartIcon,
                      width: 16,
                      height: 16,
                      color: AppColors.greyColor(context).withOpacity(0.7),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '${widget.sessionData['session_fee'] ?? ''}/${Localization.translate("session")}',
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ] else if (paymentEnabled == "no") ...[
                    SizedBox(width: 55),
                    SvgPicture.asset(
                      AppImages.userIcon,
                      width: 16,
                      height: 16,
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
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ],
              ),

              if (paymentEnabled == "yes") ...[
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
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 8),
              Row(
                children: [
                  if (role == 'student' &&
                      userData != null &&
                      widget.tutorDetail['id'] != userId)
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (paymentEnabled == "yes")
                                ? (isBooking || widget.slotsLeft <= 0)
                                    ? null
                                    : () => _bookSession(context)
                                : (isFreeBooking || widget.slotsLeft <= 0)
                                ? null
                                : () async {
                                  await _bookFreeSession(context);
                                },

                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>((
                                Set<MaterialState> states,
                              ) {
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
                        child:
                            (paymentEnabled == "yes")
                                ? (isBooking
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryGreen(context),
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      '${Localization.translate("book_sessions")}',
                                      style: TextStyle(
                                        color:
                                            widget.slotsLeft > 0
                                                ? AppColors.primaryGreen(
                                                  context,
                                                )
                                                : AppColors.greyColor(
                                                  context,
                                                ).withOpacity(0.5),
                                        fontSize: FontSize.scale(context, 14),
                                        fontFamily: AppFontFamily.mediumFont,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ))
                                : (isFreeBooking
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryGreen(context),
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      "${(Localization.translate('get_session') ?? '').trim() != 'get_session' && (Localization.translate('get_session') ?? '').trim().isNotEmpty ? Localization.translate('get_session') : "Get Session"}",
                                      style: TextStyle(
                                        color:
                                            widget.slotsLeft > 0
                                                ? AppColors.primaryGreen(
                                                  context,
                                                )
                                                : AppColors.greyColor(
                                                  context,
                                                ).withOpacity(0.5),
                                        fontSize: FontSize.scale(context, 14),
                                        fontFamily: AppFontFamily.mediumFont,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    )),
                      ),
                    ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => SessionScreen(
                                  slotsLeft: widget.slotsLeft,
                                  totalSlots: widget.totalSlots,
                                  description: widget.description,
                                  sessionDate: formattedDate,
                                  sessionData: widget.sessionData,
                                  tutorProfileData: widget.tutorDetail,
                                ),
                          ),
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
                          fontFamily: AppFontFamily.mediumFont,
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
