import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../auth/login_screen.dart';
import '../bookSession/component/order_summary_bottom_sheet.dart';
import '../bookings/bookings.dart';
import '../components/login_required_alert.dart';
import '../components/session__view_detail.dart';

class SessionScreen extends StatefulWidget {
  final int slotsLeft;
  final int totalSlots;
  final String description;
  final String sessionDate;
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> tutorProfileData;

  const SessionScreen({
    Key? key,
    required this.slotsLeft,
    required this.totalSlots,
    required this.description,
    required this.sessionDate,
    required this.sessionData,
    required this.tutorProfileData,
  }) : super(key: key);

  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late double screenHeight;
  bool isBooking = false;
  bool isFreeBooking = false;
  late String studentName = "";
  String paymentEnabled = "no";

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

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

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
          _showToast(
            context,
            response['message'] ??
                '${Localization.translate("session_booked")}',
            true,
          );
          await _fetchBookingCart(context);
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);
        } else if (response['status'] == 401) {
          showCustomToast(
            context,
            '${Localization.translate("unauthorized_access")}',
            false,
          );
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
            '${Localization.translate("failed_book_session")} ',
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
        '${Localization.translate("unauthorized_access")} ',
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
                profileDta: widget.tutorProfileData,
                cartData: cartItems,
                total: cartData['total'],
                subtotal: cartData['subtotal'],
              ),
        );
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

  void _showToast(BuildContext context, String message, bool isSuccess) {
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

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;

    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final userId = authProvider.userId;
    final String? role =
        userData != null && userData['user'] != null
            ? userData['user']['role']
            : null;

    final settingsProvider = Provider.of<SettingsProvider>(context);
    studentName =
        settingsProvider.getSetting(
          'data',
        )?['_lernen']?['student_display_name'];
    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'];

    return Directionality(
      textDirection: Localization.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor(context),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(90.0),
          child: Container(
            color: AppColors.whiteColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: AppBar(
                backgroundColor: AppColors.whiteColor,
                forceMaterialTransparency: true,
                centerTitle: false,
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sessionData['subject']['name'] ?? '',
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSize.scale(context, 20),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    Text(
                      widget.sessionData['group']['name'] ?? '',
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 13),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.blackColor),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: AppColors.blackColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _headerSection(),
                    buildSessionDetailsSection(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SessionOverviewSection(
                        description:
                            widget.sessionData['description'] ??
                            widget.description,
                      ),
                    ),
                    if (role == 'student' &&
                        userData != null &&
                        widget.tutorProfileData['id'] != userId)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                                  return AppColors.primaryGreen(context);
                                }),
                            padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              (paymentEnabled == "yes")
                                  ? Text(
                                    '${Localization.translate("book_sessions")}',
                                    style: TextStyle(
                                      color:
                                          widget.slotsLeft > 0
                                              ? AppColors.whiteColor
                                              : AppColors.greyColor(
                                                context,
                                              ).withOpacity(0.5),
                                      fontSize: FontSize.scale(context, 16),
                                      fontFamily: AppFontFamily.mediumFont,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  )
                                  : Text(
                                    "${(Localization.translate('get_session') ?? '').trim() != 'get_session' && (Localization.translate('get_session') ?? '').trim().isNotEmpty ? Localization.translate('get_session') : "Get Session"}",
                                    style: TextStyle(
                                      color:
                                          widget.slotsLeft > 0
                                              ? AppColors.whiteColor
                                              : AppColors.greyColor(
                                                context,
                                              ).withOpacity(0.5),
                                      fontSize: FontSize.scale(context, 16),
                                      fontFamily: AppFontFamily.mediumFont,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                              SizedBox(width: 8.0),
                              (isBooking || isFreeBooking)
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryGreen(context),
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : SvgPicture.asset(
                                    AppImages.addSessionIcon,
                                    height: 20,
                                    color:
                                        widget.slotsLeft <= 0
                                            ? AppColors.greyColor(
                                              context,
                                            ).withOpacity(0.5)
                                            : AppColors.whiteColor,
                                  ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerSection() {
    if (widget.sessionData['image'].isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.sessionData['image'] ?? '',
        fit: BoxFit.fill,
        placeholder: (context, url) => _buildSkeletonLoader(),
        errorWidget: (context, url, error) => Container(),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget buildSessionDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      padding: EdgeInsets.all(12.0),
      child: Column(
        children: [
          SessionDetailRow(
            icon: AppImages.calenderSession,
            label: '${Localization.translate("date") ?? ''}',
            value: widget.sessionDate,
          ),
          SessionDetailRow(
            icon: AppImages.timerSession,
            label: '${Localization.translate("time") ?? ''}',
            value: widget.sessionData['formatted_time_range'] ?? '',
          ),
          SessionDetailRow(
            icon: AppImages.typeSession,
            label: '${Localization.translate("type") ?? ''}',
            value: '${widget.sessionData['spaces_type']} session',
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.yellowBorderColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      AppImages.userIcon,
                      width: 16,
                      height: 16,
                      color: AppColors.userIconColor,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    Localization.translate("enrollment") ?? '',
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
              Text(
                '${widget.sessionData['booked_slots']} ${(studentName.isEmpty && Localization.translate("students").isEmpty) ? "Student" : (widget.sessionData['booked_slots'] == 1 || widget.sessionData['booked_slots'] == 0 ? studentName : "${Localization.translate("students")}")}',
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 14),
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
            ],
          ),
          if (paymentEnabled == "yes") ...[
            SizedBox(height: 8),
            SessionDetailRow(
              icon: AppImages.dollarSession,
              label: '${Localization.translate('session_fee')}',
              value:
                  '${widget.sessionData['session_fee']} / ${Localization.translate('person')}',
            ),
          ],

          if ((widget.tutorProfileData['full_name'] != null &&
                  widget.tutorProfileData['full_name'].toString().isNotEmpty) ||
              (widget.tutorProfileData['image'] != null &&
                  widget.tutorProfileData['image'].toString().isNotEmpty)) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        widget.tutorProfileData['image'] ?? "",
                        width: 35,
                        height: 35,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 35,
                            height: 35,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            AppImages.placeHolderImage,
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "${Localization.translate('session_tutor')}",
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
                Text(
                  widget.tutorProfileData['full_name'] ?? "",
                  style: TextStyle(
                    color: AppColors.greyColor(context),
                    fontSize: FontSize.scale(context, 14),
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFontFamily.mediumFont,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SessionOverviewSection extends StatelessWidget {
  final String description;

  SessionOverviewSection({required this.description});

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: HtmlWidget(
        description,
        textStyle: TextStyle(
          fontSize: FontSize.scale(context, 14),
          fontFamily: AppFontFamily.mediumFont,
          fontWeight: FontWeight.w400,
          color: AppColors.greyColor(context),
        ),
      ),
    );
  }
}
