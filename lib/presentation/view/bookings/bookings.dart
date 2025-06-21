import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/presentation/view/bookings/skeleton/booking_skeleton.dart';
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/login_screen.dart';
import '../components/internet_alert.dart';
import '../dispute/dispute_detail.dart';

class BookingScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  BookingScreen({this.onBackPressed});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic> bookings = {};
  bool isLoading = true;
  bool _onPressLoading = false;
  int? _selectedBookingId;
  String paymentEnabled = "no";

  late String studentName = "";
  late Map<String, dynamic>? disputeSettings;

  final List<String> times = [
    '12:00 am',
    '01:00 am',
    '02:00 am',
    '03:00 am',
    '04:00 am',
    '05:00 am',
    '06:00 am',
    '07:00 am',
    '08:00 am',
    '09:00 am',
    '10:00 am',
    '11:00 am',
    '12:00 pm',
    '01:00 pm',
    '02:00 pm',
    '03:00 pm',
    '04:00 pm',
    '05:00 pm',
    '06:00 pm',
    '07:00 pm',
    '08:00 pm',
    '09:00 pm',
    '10:00 pm',
    '11:00 pm',
  ];

  final List<Color> availableColors = [
    AppColors.yellowColor,
    AppColors.blueColor,
    AppColors.lightGreenColor,
    AppColors.purpleColor,
    AppColors.orangeColor,
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await getBookings(token!, formattedDate, formattedDate);

      if (response['status'] == 200) {
        setState(() {
          bookings = response['data'] ?? {};
          isLoading = false;
        });
      } else if (response['status'] == 401) {
        showCustomToast(
          context,
          '${Localization.translate("unauthorized_access")}',
          false,
        );
        setState(() {
          isLoading = false;
        });
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
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: AppColors.primaryGreen(context),
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen(context),
              onPrimary: AppColors.whiteColor,
              onSurface: AppColors.blackColor,
            ),
            dialogBackgroundColor: AppColors.whiteColor,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
      _fetchBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    studentName =
        settingsProvider.getSetting(
          'data',
        )?['_lernen']?['student_display_name'] ??
        '';
    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'] ??
        '';

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
                preferredSize: Size.fromHeight(70.0),
                child: Container(
                  color: AppColors.whiteColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: AppBar(
                      backgroundColor: AppColors.whiteColor,
                      forceMaterialTransparency: true,
                      elevation: 0,
                      titleSpacing: 0,
                      title: Text(
                        Localization.translate("bookings"),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 20),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      leading: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: AppColors.blackColor,
                        ),
                        onPressed: () {
                          if (widget.onBackPressed != null) {
                            widget.onBackPressed!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      centerTitle: false,
                    ),
                  ),
                ),
              ),
              body:
                  isLoading
                      ? BookingScreenSkeleton()
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          _buildDateSelector(context),
                          SizedBox(height: 20),
                          Expanded(child: _buildBookingTable()),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    String formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);
    bool isToday =
        DateTime.now().year == selectedDate.year &&
        DateTime.now().month == selectedDate.month &&
        DateTime.now().day == selectedDate.day;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 40,
            decoration: ShapeDecoration(
              color: AppColors.whiteColor,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: AppColors.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.blackColor,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.subtract(Duration(days: 1));
                    });
                    _fetchBookings();
                  },
                ),
                Text(
                  Localization.translate("today"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isToday ? AppColors.blackColor : AppColors.dayFadeColor,
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.blackColor,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.add(Duration(days: 1));
                    });
                    _fetchBookings();
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _selectDate(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              height: 40,
              decoration: ShapeDecoration(
                color: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: AppColors.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.mediumFont,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  SizedBox(width: 10),
                  SvgPicture.asset(
                    AppImages.bookingCalender,
                    height: 20,
                    width: 20,
                    color: AppColors.greyColor(context),
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final subjectName =
            booking['slot']['subjectGroupSubjects']['subject']['name'];
        final sessionFee = booking['slot']['session_fee'];
        final bookingDate = booking['date'];
        final startTime = booking['start_time'];
        final endTime = booking['end_time'];
        final meetingLink = booking['slot']['meta_data']?['meeting_link'] ?? '';
        final subjectImageUrl =
            booking['slot']['subjectGroupSubjects']['image'];

        return Directionality(
          textDirection: Localization.textDirection,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        subjectImageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  subjectName ?? "",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontFamily: AppFontFamily.mediumFont,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blackColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Icon(
                                  Icons.close,
                                  color: AppColors.blackColor,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 5),
                            ],
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              SvgPicture.asset(
                                AppImages.clockIcon,
                                width: 16,
                                height: 16,
                                color: AppColors.greyColor(context),
                              ),
                              SizedBox(width: 5),
                              Text(
                                '$startTime - $endTime' ?? "",
                                style: TextStyle(
                                  fontSize: FontSize.scale(context, 12),
                                  color: AppColors.greyColor(context),
                                  fontFamily: AppFontFamily.mediumFont,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Divider(),
                if (paymentEnabled == "yes") ...[
                  _buildDetailRow(
                    Localization.translate("session_fee"),
                    '$sessionFee',
                  ),
                ],
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Localization.translate("enrollment") ?? '',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFontFamily.mediumFont,
                        ),
                      ),
                    ),
                    (booking['slot']?['students'] != null &&
                            (booking['slot']?['students'] as List).isNotEmpty &&
                            booking['slot']?['students']?[0]?['image'] != null)
                        ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl:
                                  booking['slot']?['students']?[0]?['image']!,
                              placeholder:
                                  (context, url) => CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: AppColors.primaryGreen(context),
                                  ),
                              errorWidget:
                                  (context, url, error) => Icon(Icons.error),
                              fit: BoxFit.cover,
                              width: 24,
                              height: 24,
                            ),
                          ),
                        )
                        : SizedBox.shrink(),
                    SizedBox(width: 8),
                    Text(
                      '${booking['slot']['students'].length} ${(studentName.isEmpty && Localization.translate("students").isEmpty) ? "Student" : (booking['slot']['students'].length == 0 || booking['slot']['students'].length == 1 ? studentName : "${Localization.translate("students")}")}',
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFontFamily.mediumFont,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _buildDetailRow(Localization.translate("date"), bookingDate),
                SizedBox(height: 10),
                _buildDetailRow(
                  Localization.translate("time"),
                  '$startTime - $endTime',
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showFullDetailsBottomSheet(context, booking);
                      },
                      child: Text(
                        Localization.translate("view_details") ?? '',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 16),
                          color: AppColors.blackColor,
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryWhiteColor,
                        minimumSize: Size(50, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (meetingLink.isNotEmpty) {
                          final Uri zoomWebUrl = Uri.parse(meetingLink);
                          try {
                            if (await canLaunchUrl(zoomWebUrl)) {
                              await launchUrl(
                                zoomWebUrl,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (error) {}
                        }
                      },
                      child: Text(
                        Localization.translate("join_session") ?? '',
                        style: TextStyle(
                          fontSize: FontSize.scale(context, 16),
                          color: AppColors.whiteColor,
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen(context),
                        minimumSize: Size(50, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void addReviewBottomSheet(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    bool _isDescriptionValid = false;
    int _selectedRating = 0;

    Future<void> submitReview({
      required BuildContext context,
      required int bookingId,
      required int rating,
      required String comment,
      required StateSetter setModalState,
    }) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        try {
          setModalState(() {
            _onPressLoading = true;
            isLoading = true;
          });

          final response = await addReview(
            token: token,
            bookingId: bookingId,
            rating: rating,
            comment: comment,
          );

          if (response['status'] == 200) {
            showCustomToast(context, response['message'], true);
            await _fetchBookings();
            Navigator.pop(context);
          } else if (response['status'] == 403) {
            showCustomToast(context, response['message'], false);
            Navigator.pop(context);
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
            Navigator.pop(context);
          } else if (response['status'] == 422) {
            final errors = response['errors'] as Map<String, dynamic>;

            String errorMessage = errors.entries
                .map((entry) {
                  if (entry.value is String && entry.value != null) {
                    return "${entry.key}: ${entry.value}";
                  } else if (entry.value is List &&
                      (entry.value as List).isNotEmpty) {
                    return "${entry.key}: ${(entry.value as List).join(', ')}";
                  } else {
                    return "${entry.key}:";
                  }
                })
                .join('\n');

            showCustomToast(context, errorMessage, false);

            setModalState(() {
              _onPressLoading = false;
            });
          } else {
            String message =
                response['message'] is String ? response['message'] : '';
            showCustomToast(context, message, false);
            setModalState(() {
              _onPressLoading = false;
            });
          }
        } catch (error) {
          setModalState(() {
            _onPressLoading = false;
          });
        } finally {
          setModalState(() {
            _onPressLoading = false;
            isLoading = false;
          });
        }
      } else {
        setModalState(() {
          _onPressLoading = false;
        });
      }
    }

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.43,
                    decoration: BoxDecoration(
                      color: AppColors.sheetBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.topBottomSheetDismissColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 5.0,
                            ),
                            child: Text(
                              Localization.translate("add_review").isNotEmpty ==
                                      true
                                  ? Localization.translate("add_review")
                                  : 'Add Review',
                              style: TextStyle(
                                fontSize: FontSize.scale(context, 18),
                                color: AppColors.blackColor,
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        _selectedRating = index + 1;
                                      });
                                    },
                                    child: SvgPicture.asset(
                                      index < _selectedRating
                                          ? AppImages.filledStar
                                          : AppImages.star,
                                      width: 30,
                                      height: 30,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          SizedBox(height: 5),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    hint:
                                        '${Localization.translate("type_here")}',
                                    mandatory: false,
                                    controller: descriptionController,
                                    multiLine: true,
                                    hasError: _isDescriptionValid,
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.greyColor(
                                                  context,
                                                ).withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.whiteColor,
                                              side: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 15,
                                              ),
                                            ),
                                            child: Text(
                                              "${Localization.translate("cancel")}",
                                              style: TextStyle(
                                                fontSize: FontSize.scale(
                                                  context,
                                                  16,
                                                ),
                                                color: AppColors.greyColor(
                                                  context,
                                                ),
                                                fontFamily:
                                                    AppFontFamily.mediumFont,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              _onPressLoading
                                                  ? null
                                                  : () async {
                                                    if (_selectedRating > 0) {
                                                      final comment =
                                                          descriptionController
                                                              .text;

                                                      if (comment.isEmpty) {
                                                        setModalState(() {
                                                          _isDescriptionValid =
                                                              true;
                                                        });
                                                        showCustomToast(
                                                          context,
                                                          "${Localization.translate("enter_comment").isNotEmpty == true ? Localization.translate("enter_comment") : 'Please enter comment'}",
                                                          false,
                                                        );
                                                        return;
                                                      }

                                                      final selectedBooking = bookings
                                                          .values
                                                          .expand(
                                                            (bookingList) =>
                                                                bookingList
                                                                        is List
                                                                    ? bookingList
                                                                    : [],
                                                          )
                                                          .firstWhere(
                                                            (booking) =>
                                                                booking['status'] ==
                                                                    "completed" &&
                                                                booking['review_submitted'] ==
                                                                    false,
                                                            orElse: () => null,
                                                          );

                                                      if (selectedBooking !=
                                                          null) {
                                                        final bookingId =
                                                            selectedBooking['id'];
                                                        await submitReview(
                                                          context: context,
                                                          bookingId: bookingId,
                                                          rating:
                                                              _selectedRating,
                                                          comment: comment,
                                                          setModalState:
                                                              setModalState,
                                                        );
                                                      } else {
                                                        showCustomToast(
                                                          context,
                                                          "${Localization.translate("bookings_empty").isNotEmpty == true ? Localization.translate("bookings_empty") : 'No eligible booking found.'}",
                                                          false,
                                                        );
                                                      }
                                                    } else {
                                                      setModalState(() {
                                                        _isDescriptionValid =
                                                            true;
                                                      });
                                                    }
                                                  },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGreen(context),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 15,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "${Localization.translate("submit_review").isNotEmpty == true ? Localization.translate("submit_review") : 'Submit Review'}",
                                                style: TextStyle(
                                                  fontSize: FontSize.scale(
                                                    context,
                                                    16,
                                                  ),
                                                  color: AppColors.whiteColor,
                                                  fontFamily:
                                                      AppFontFamily.mediumFont,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (_onPressLoading) ...[
                                                SizedBox(width: 10),
                                                SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            AppColors
                                                                .whiteColor,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void showReasonSelectionBottomSheet(
    BuildContext context,
    TextEditingController reasonController,
  ) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final settingsProvider = Provider.of<SettingsProvider>(context);
              final disputeReasons =
                  settingsProvider.getSetting(
                        'data',
                      )?['_dispute_setting']?['dispute_reasons']
                      as List<dynamic>?;
              final List<String> reasons =
                  disputeReasons != null
                      ? disputeReasons
                          .map((reason) => reason['dispute_reason'] as String)
                          .toList()
                      : [];

              String? selectedReason = reasonController.text;

              return Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.sheetBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 10, top: 1),
                        decoration: BoxDecoration(
                          color: AppColors.topBottomSheetDismissColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Text(
                      "${Localization.translate("select_dispute").isNotEmpty == true ? Localization.translate("select_dispute") : 'Select Dispute Reason'}",
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 18),
                        color: AppColors.blackColor,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                        fontFamily: AppFontFamily.mediumFont,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Expanded(
                      child:
                          reasons.isEmpty
                              ? Center(
                                child: Text(
                                  "${Localization.translate("item_empty")}",
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 16),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: AppColors.whiteColor,
                                ),
                                child: ListView.separated(
                                  itemCount: reasons.length,
                                  itemBuilder: (context, index) {
                                    final reason = reasons[index];
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16.0,
                                                ),
                                            title: Text(
                                              reason,
                                              style: TextStyle(
                                                color: AppColors.greyColor(
                                                  context,
                                                ),
                                                fontSize: FontSize.scale(
                                                  context,
                                                  16,
                                                ),
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontFamily:
                                                    AppFontFamily.mediumFont,
                                              ),
                                            ),
                                            onTap: () {
                                              setModalState(() {
                                                selectedReason = reason;
                                              });
                                              reasonController.text = reason;
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                        Radio<String>(
                                          value: reason,
                                          groupValue: selectedReason,
                                          onChanged: (value) {
                                            setModalState(() {
                                              selectedReason = value!;
                                            });
                                            reasonController.text = value!;
                                            Navigator.pop(context);
                                          },
                                          activeColor: AppColors.primaryGreen(
                                            context,
                                          ),
                                          fillColor:
                                              MaterialStateProperty.resolveWith<
                                                Color?
                                              >((Set<MaterialState> states) {
                                                if (states.contains(
                                                  MaterialState.selected,
                                                )) {
                                                  return AppColors.primaryGreen(
                                                    context,
                                                  );
                                                }
                                                return AppColors.greyColor(
                                                  context,
                                                );
                                              }),
                                        ),
                                      ],
                                    );
                                  },
                                  separatorBuilder: (context, index) {
                                    return Divider(
                                      color: AppColors.dividerColor,
                                      thickness: 1,
                                      height: 1,
                                      indent: 16.0,
                                      endIndent: 16.0,
                                    );
                                  },
                                ),
                              ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void showRaiseDisputeBottomSheet(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              bool reasonValid = false;
              bool isDescriptionValid = false;

              Future<void> raiseDispute({
                required BuildContext context,
                required int bookingId,
                required String reason,
                required String comment,
                required StateSetter setModalState,
              }) async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final token = authProvider.token;

                if (token != null) {
                  try {
                    setModalState(() {
                      _onPressLoading = true;
                      isLoading = true;
                    });

                    final response = await disputeBooking(
                      token: token,
                      bookingId: bookingId,
                      reason: reason,
                      description: comment,
                    );

                    if (response['status'] == 200) {
                      showCustomToast(context, response['message'], true);
                      await _fetchBookings();
                      Navigator.pop(context);
                    } else if (response['status'] == 403) {
                      showCustomToast(context, response['message'], false);
                      Navigator.pop(context);
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
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            showCancelButton: false,
                          );
                        },
                      );
                      Navigator.pop(context);
                    } else {
                      showCustomToast(context, response['message'], false);
                      Navigator.pop(context);
                    }
                  } catch (error) {
                  } finally {
                    setModalState(() {
                      _onPressLoading = false;
                      isLoading = false;
                    });
                  }
                }
              }

              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.55,
                    decoration: BoxDecoration(
                      color: AppColors.sheetBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.topBottomSheetDismissColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          Text(
                            "${Localization.translate("raise_dispute").isNotEmpty == true ? Localization.translate("raise_dispute") : 'Raise a dispute'}",
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 18),
                              color: AppColors.blackColor,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            "${Localization.translate("select_reason").isNotEmpty == true ? Localization.translate("select_reason") : 'Select Reason'}",
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.blackColor,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          CustomTextField(
                            hint:
                                '${Localization.translate("select_dispute_reason").isNotEmpty == true ? Localization.translate("select_dispute_reason") : 'Select a dispute reason'}',
                            mandatory: true,
                            controller: reasonController,
                            absorbInput: true,
                            hasError: reasonValid,
                            onTap: () {
                              showReasonSelectionBottomSheet(
                                context,
                                reasonController,
                              );
                            },
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            "${Localization.translate("description").isNotEmpty == true ? Localization.translate("description") : 'Description'}",
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.blackColor,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontFamily: AppFontFamily.mediumFont,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          CustomTextField(
                            hint:
                                "${Localization.translate("add_description").isNotEmpty == true ? Localization.translate("add_description") : 'Add Description'}",
                            mandatory: false,
                            controller: descriptionController,
                            multiLine: true,
                            hasError: isDescriptionValid,
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed:
                                _onPressLoading
                                    ? null
                                    : () async {
                                      setModalState(() {
                                        reasonValid =
                                            reasonController.text.isEmpty;
                                        isDescriptionValid =
                                            descriptionController.text.isEmpty;
                                      });

                                      if (reasonValid || isDescriptionValid) {
                                        if (reasonValid) {
                                          showCustomToast(
                                            context,
                                            '${Localization.translate("select_reason")}',
                                            false,
                                          );
                                        }
                                        if (isDescriptionValid) {
                                          showCustomToast(
                                            context,
                                            '${Localization.translate("description_required")}',
                                            false,
                                          );
                                        }
                                        return;
                                      }

                                      final selectedBooking = bookings.values
                                          .expand(
                                            (bookingList) =>
                                                bookingList is List
                                                    ? bookingList
                                                    : [],
                                          )
                                          .firstWhere(
                                            (booking) =>
                                                booking['status'] == "active" &&
                                                booking['awaiting_complete'] ==
                                                    true,
                                            orElse: () => null,
                                          );

                                      if (selectedBooking != null) {
                                        final bookingId = selectedBooking['id'];

                                        await raiseDispute(
                                          context: context,
                                          bookingId: bookingId,
                                          reason: reasonController.text,
                                          comment: descriptionController.text,
                                          setModalState: setModalState,
                                        );
                                      } else {
                                        showCustomToast(
                                          context,
                                          '${Localization.translate("bookings_empty")}',
                                          false,
                                        );
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 55),
                              backgroundColor: AppColors.primaryGreen(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 15,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${Localization.translate("submit")}",
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.mediumFont,
                                    fontSize: FontSize.scale(context, 16),
                                  ),
                                ),
                                if (_onPressLoading) ...[
                                  SizedBox(width: 10),
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryGreen(context),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      reasonController.clear();
      descriptionController.clear();
    });
  }

  void showCompletionBottomSheet(BuildContext context) {
    Future<void> markCompleted({
      required BuildContext context,
      required int bookingId,
      required StateSetter setModalState,
    }) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        try {
          setModalState(() {
            _onPressLoading = true;
            isLoading = true;
          });

          final response = await completeBooking(
            token: token,
            bookingId: bookingId,
          );

          if (response['status'] == 200) {
            showCustomToast(context, response['message'], true);
            await _fetchBookings();
            Navigator.pop(context);
          } else if (response['status'] == 403) {
            showCustomToast(context, response['message'], false);
            Navigator.pop(context);
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
            Navigator.pop(context);
          } else if (response['status'] == 400) {
            showCustomToast(context, response['message'], false);
            setModalState(() {
              _onPressLoading = false;
            });
          } else if (response['status'] == 422) {
            final errors = response['errors'] as Map<String, dynamic>;

            String errorMessage = errors.entries
                .map((entry) {
                  if (entry.value is String && entry.value != null) {
                    return "${entry.key}: ${entry.value}";
                  } else if (entry.value is List &&
                      (entry.value as List).isNotEmpty) {
                    return "${entry.key}: ${(entry.value as List).join(', ')}";
                  } else {
                    return "${entry.key}";
                  }
                })
                .join('\n');

            showCustomToast(context, errorMessage, false);

            setModalState(() {
              _onPressLoading = false;
            });
          } else {
            String message =
                response['message'] is String ? response['message'] : '';
            showCustomToast(context, message, false);
            setModalState(() {
              _onPressLoading = false;
            });
          }
        } catch (error) {
          setModalState(() {
            _onPressLoading = false;
          });
        } finally {
          setModalState(() {
            _onPressLoading = false;
            isLoading = false;
          });
        }
      } else {
        setModalState(() {
          _onPressLoading = false;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackgroundColor,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    decoration: BoxDecoration(
                      color: AppColors.sheetBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 10, top: 1),
                              decoration: BoxDecoration(
                                color: AppColors.topBottomSheetDismissColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: AppColors.lightGreenColor,
                              size: 50,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "${Localization.translate("confirm_session").isNotEmpty == true ? Localization.translate("confirm_session") : 'Confirm Session Completion'}",
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.greyColor(context),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "${Localization.translate("alert_session_text").isNotEmpty == true ? Localization.translate("alert_session_text") : 'Are you sure you want to mark this session as completed? Otherwise it will be completed after 3 days'}",
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 14),
                              color: AppColors.greyColor(context),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.greyColor(
                                          context,
                                        ).withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      showRaiseDisputeBottomSheet(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColors.whiteColor,
                                      side: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 15,
                                      ),
                                    ),
                                    child: Text(
                                      "${Localization.translate("raise_dispute").isNotEmpty == true ? Localization.translate("raise_dispute") : "Raise a dispute"}",
                                      style: TextStyle(
                                        fontSize: FontSize.scale(context, 16),
                                        color: AppColors.greyColor(context),
                                        fontFamily: AppFontFamily.mediumFont,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen(
                                      context,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 15,
                                    ),
                                  ),
                                  onPressed:
                                      _onPressLoading
                                          ? null
                                          : () async {
                                            final selectedBooking = bookings
                                                .values
                                                .expand(
                                                  (bookingList) =>
                                                      bookingList is List
                                                          ? bookingList
                                                          : [],
                                                )
                                                .firstWhere(
                                                  (booking) =>
                                                      booking['status'] ==
                                                          "active" &&
                                                      booking['awaiting_complete'] ==
                                                          true,
                                                  orElse: () => null,
                                                );

                                            if (selectedBooking != null) {
                                              final bookingId =
                                                  selectedBooking['id'];

                                              await markCompleted(
                                                context: context,
                                                bookingId: bookingId,
                                                setModalState: setModalState,
                                              );
                                            } else {
                                              showCustomToast(
                                                context,
                                                '${Localization.translate("bookings_empty")}',
                                                false,
                                              );
                                            }
                                          },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${Localization.translate("mark_completed")}",
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.whiteColor,
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (_onPressLoading) ...[
                                        SizedBox(width: 10),
                                        SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryGreen(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label ?? "",
            style: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 14),
              fontWeight: FontWeight.w400,
              fontFamily: AppFontFamily.mediumFont,
            ),
          ),
          Text(
            value ?? "",
            style: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 14),
              fontWeight: FontWeight.w500,
              fontFamily: AppFontFamily.mediumFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTable() {
    String formattedDate = DateFormat('MMMM dd, yyyy').format(selectedDate);

    final random = Random();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border(
          top: BorderSide(color: AppColors.dividerColor, width: 1),
          bottom: BorderSide(color: AppColors.dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  Localization.translate("time") ?? "",
                  style: TextStyle(
                    color: AppColors.greyColor(context),
                    fontSize: 14,
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: Platform.isIOS ? 8 : 9,
                ),
                width: 1,
                height: 50,
                color: AppColors.dividerColor,
              ),
              Expanded(
                child: Text(
                  formattedDate ?? "",
                  style: TextStyle(
                    color: AppColors.greyColor(context),
                    fontSize: 14,
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                  textAlign:
                      Localization.textDirection == TextDirection.LTR
                          ? TextAlign.left
                          : TextAlign.start,
                ),
              ),
            ],
          ),
          Divider(height: 1, thickness: 1, color: AppColors.dividerColor),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: times.length,
              itemBuilder: (context, index) {
                final time = times[index];
                final bookingsAtThisTime =
                    bookings[time] as List<dynamic>? ?? [];

                final lineHeight =
                    bookingsAtThisTime.isNotEmpty
                        ? bookingsAtThisTime.length * 65.0
                        : 60.0;

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: lineHeight,
                          decoration: BoxDecoration(
                            color:
                                bookingsAtThisTime.isNotEmpty
                                    ? AppColors.backgroundColor(context)
                                    : AppColors.whiteColor,
                          ),
                          child: Center(
                            child: Text(
                              time ?? "",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: 12,
                                fontFamily: AppFontFamily.mediumFont,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: lineHeight,
                          color: AppColors.dividerColor,
                        ),
                        Expanded(
                          child: Container(
                            height: lineHeight,
                            color:
                                bookingsAtThisTime.isNotEmpty
                                    ? AppColors.backgroundColor(context)
                                    : AppColors.whiteColor,
                            padding: const EdgeInsets.only(left: 10),
                            child:
                                bookingsAtThisTime.isNotEmpty
                                    ? SingleChildScrollView(
                                      physics: NeverScrollableScrollPhysics(),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height:
                                                bookingsAtThisTime.length == 1
                                                    ? 6
                                                    : 10,
                                          ),
                                          ...bookingsAtThisTime.map<Widget>((
                                            booking,
                                          ) {
                                            return GestureDetector(
                                              onTap: () {
                                                if (booking['status'] ==
                                                        "active" &&
                                                    booking['awaiting_complete'] ==
                                                        false &&
                                                    booking['review_submitted'] ==
                                                        false) {
                                                  _showBookingDetails(
                                                    context,
                                                    booking,
                                                  );
                                                }
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                  right: 15.0,
                                                  top: 2,
                                                ),
                                                child: BookingItem(
                                                  time: time,
                                                  subject:
                                                      booking['slot']['subjectGroupSubjects']['subject']['name'],
                                                  status: booking['status'],
                                                  image:
                                                      booking['slot']['subjectGroupSubjects']['image'],
                                                  startTime:
                                                      booking['start_time'],
                                                  endTime: booking['end_time'],
                                                  color:
                                                      availableColors[random
                                                          .nextInt(
                                                            availableColors
                                                                .length,
                                                          )],
                                                  isReviewSubmitted:
                                                      booking['status'] ==
                                                          "completed" &&
                                                      booking['review_submitted'] ==
                                                          true,
                                                  showAddReview:
                                                      booking['status'] ==
                                                          "completed" &&
                                                      booking['review_submitted'] ==
                                                          false,
                                                  markCompleted:
                                                      booking['status'] ==
                                                          "active" &&
                                                      booking['awaiting_complete'] ==
                                                          true,
                                                  disputeSession:
                                                      booking['status'] ==
                                                      "disputed",
                                                  onAddReviewPress: () {
                                                    if (booking['status'] ==
                                                            "completed" &&
                                                        booking['review_submitted'] ==
                                                            false) {
                                                      setState(() {
                                                        _selectedBookingId =
                                                            booking['id'];
                                                      });
                                                      addReviewBottomSheet(
                                                        context,
                                                      );
                                                    }
                                                  },
                                                  onMarkCompletedPress: () {
                                                    if (booking['status'] ==
                                                            "active" &&
                                                        booking['awaiting_complete'] ==
                                                            true) {
                                                      setState(() {
                                                        _selectedBookingId =
                                                            booking['id'];
                                                      });
                                                      showCompletionBottomSheet(
                                                        context,
                                                      );
                                                    }
                                                  },
                                                  onDisputePress: () {
                                                    if (booking['status'] ==
                                                        "disputed") {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => DisputeDetails(
                                                                id:
                                                                    booking['dispute_id'],
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          SizedBox(height: lineHeight),
                                        ],
                                      ),
                                    )
                                    : SizedBox(height: lineHeight),
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.dividerColor,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFullDetailsBottomSheet(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final subjectName =
            booking['slot']['subjectGroupSubjects']['subject']['name'];
        final subjectGroup =
            booking['slot']['subjectGroupSubjects']['subject_group']['name'];
        final sessionFee = booking['slot']['session_fee'];
        final type = booking['slot']['space_type'];
        final bookingDate = booking['date'];
        final startTime = booking['start_time'];
        final endTime = booking['end_time'];
        final tutorName = booking['tutor']['full_name'];
        final overview =
            booking['slot']['description'] ?? 'No description available';
        final subjectImageUrl =
            booking['slot']['subjectGroupSubjects']['image'];
        final meetingLink = booking['slot']['meta_data']?['meeting_link'] ?? '';
        final leftTime = booking['left_time'];

        return Directionality(
          textDirection: Localization.textDirection,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school, size: 16),
                              SizedBox(width: 8),
                              Text(
                                subjectGroup ?? "",
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 13),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFontFamily.mediumFont,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: AppColors.blackColor,
                              size: 24,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        subjectName ?? "",
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 20),
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFontFamily.mediumFont,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgPicture.asset(
                                  AppImages.dateCalender,
                                  width: 16,
                                  height: 16,
                                  color: AppColors.blue,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                Localization.translate("date") ?? "",
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            bookingDate ?? "",
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.purpleBorderColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgPicture.asset(
                                  AppImages.clockIcon,
                                  width: 16,
                                  height: 16,
                                  color: AppColors.clockColor,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                Localization.translate("time"),
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$startTime - $endTime',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
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
                                Localization.translate("enrollment"),
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${booking['slot']['students'].length} ${booking['slot']['students'].length == 0 || booking['slot']['students'].length == 1 ? "Student" : "Students"}',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.typeBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgPicture.asset(
                                  AppImages.type,
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                Localization.translate('type'),
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$type ${Localization.translate("session")}',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      if (paymentEnabled == "yes") ...[
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGreen,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SvgPicture.asset(
                                    AppImages.dollarIcon,
                                    color: AppColors.darkGreen,
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  Localization.translate("session_fee"),
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 14),
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppFontFamily.mediumFont,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$sessionFee / ${Localization.translate("person")} ',
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFontFamily.mediumFont,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 5),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.transparent,
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: booking['tutor']['image'],
                                    placeholder:
                                        (context, url) =>
                                            CircularProgressIndicator(
                                              color: AppColors.primaryGreen(
                                                context,
                                              ),
                                              strokeWidth: 2.0,
                                            ),
                                    errorWidget:
                                        (context, url, error) =>
                                            SvgPicture.asset(
                                              AppImages.placeHolder,
                                              fit: BoxFit.cover,
                                              width: 60,
                                              height: 60,
                                              color: AppColors.greyColor(
                                                context,
                                              ),
                                            ),
                                    fit: BoxFit.cover,
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                Localization.translate("session_tutor"),
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$tutorName',
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFontFamily.mediumFont,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          subjectImageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 20),
                      HtmlWidget(
                        overview,
                        textStyle: TextStyle(
                          fontSize: FontSize.scale(context, 14),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.speakerBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgPicture.asset(
                                  AppImages.speaker,
                                  color: AppColors.primaryGreen(context),
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                Localization.translate("session_start"),
                                style: TextStyle(
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFontFamily.mediumFont,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$leftTime',
                            style: TextStyle(
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppFontFamily.mediumFont,
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.primaryGreen(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (meetingLink.isNotEmpty) {
                            final Uri zoomWebUrl = Uri.parse(meetingLink);
                            try {
                              if (await canLaunchUrl(zoomWebUrl)) {
                                await launchUrl(
                                  zoomWebUrl,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } catch (error) {}
                          }
                        },
                        child: Text(
                          Localization.translate("join_session"),
                          style: TextStyle(
                            fontSize: FontSize.scale(context, 16),
                            color: AppColors.whiteColor,
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen(context),
                          minimumSize: Size(double.infinity, 50),
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class BookingItem extends StatelessWidget {
  final String time;
  final String? subject;
  final String? status;
  final String? image;
  final Color color;
  final String startTime;
  final String endTime;
  final bool isReviewSubmitted;
  final bool showAddReview;
  final VoidCallback? onAddReviewPress;
  final bool markCompleted;
  final VoidCallback? onMarkCompletedPress;
  final bool disputeSession;
  final VoidCallback? onDisputePress;

  BookingItem({
    required this.time,
    this.subject,
    this.status,
    this.image,
    required this.color,
    required this.startTime,
    required this.endTime,
    this.isReviewSubmitted = false,
    this.showAddReview = false,
    this.onAddReviewPress,
    this.markCompleted = false,
    this.onMarkCompletedPress,
    this.disputeSession = false,
    this.onDisputePress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        subject != null
            ? Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: color, width: 2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: disputeSession ? 5.0 : 0.0,
                    sigmaY: disputeSession ? 5.0 : 0.0,
                  ),
                  child: Opacity(
                    opacity: disputeSession ? 0.2 : 1.0,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            image ?? '',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Flexible(
                                    child: Text(
                                      subject!,
                                      style: TextStyle(
                                        color: AppColors.blackColor,
                                        fontSize: FontSize.scale(context, 12),
                                        fontFamily: AppFontFamily.mediumFont,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!disputeSession)
                                    isReviewSubmitted
                                        ? Row(
                                          children: [
                                            SizedBox(width: 10),
                                            SvgPicture.asset(
                                              AppImages.check,
                                              width: 12,
                                              height: 12,
                                              color: AppColors.greyColor(
                                                context,
                                              ).withOpacity(0.8),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "${Localization.translate("review_submitted").isNotEmpty == true ? Localization.translate("review_submitted") : 'Review Submitted'}",
                                              style: TextStyle(
                                                color: AppColors.greyColor(
                                                  context,
                                                ).withOpacity(0.7),
                                                fontSize: FontSize.scale(
                                                  context,
                                                  12,
                                                ),
                                                fontFamily:
                                                    AppFontFamily.regularFont,
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                          ],
                                        )
                                        : showAddReview
                                        ? GestureDetector(
                                          onTap: onAddReviewPress,
                                          child: Text(
                                            "${Localization.translate("add_review").isNotEmpty == true ? Localization.translate("add_review") : 'Add Review'}",
                                            style: TextStyle(
                                              color: AppColors.blueColor,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.blueColor,
                                              fontSize: FontSize.scale(
                                                context,
                                                12,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.regularFont,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              height: 1.8,
                                            ),
                                          ),
                                        )
                                        : markCompleted
                                        ? GestureDetector(
                                          onTap: onMarkCompletedPress,
                                          child: Text(
                                            "${Localization.translate("completed").isNotEmpty == true ? Localization.translate("completed") : 'Mark as Completed'}",
                                            style: TextStyle(
                                              color: AppColors.blueColor,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.blueColor,
                                              fontSize: FontSize.scale(
                                                context,
                                                12,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.regularFont,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              height: 1.8,
                                            ),
                                          ),
                                        )
                                        : Row(
                                          children: [
                                            SizedBox(width: 10),
                                            SvgPicture.asset(
                                              AppImages.clockIcon,
                                              width: 16,
                                              height: 16,
                                              color: AppColors.greyColor(
                                                context,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '$startTime - $endTime',
                                              style: TextStyle(
                                                color: AppColors.greyColor(
                                                  context,
                                                ),
                                                fontSize: FontSize.scale(
                                                  context,
                                                  12,
                                                ),
                                                fontFamily:
                                                    AppFontFamily.regularFont,
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            : SizedBox.shrink(),

        if (disputeSession)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 2.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.disputeSessionText,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: GestureDetector(
              onTap: onDisputePress,
              child: Text(
                "${Localization.translate("disputed_session").isNotEmpty == true ? Localization.translate("disputed_session") : 'Disputed Session'}",
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: FontSize.scale(context, 12),
                  fontFamily: AppFontFamily.regularFont,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                  height: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
