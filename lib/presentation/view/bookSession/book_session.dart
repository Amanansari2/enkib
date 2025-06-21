import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/bookSession/skeleton/book_session_screen_skeleton.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import '../components/reusable_session_card.dart';

class BookSessionScreen extends StatefulWidget {
  final Map<String, dynamic> tutorDetail;

  BookSessionScreen({required this.tutorDetail});

  @override
  _BookSessionScreenState createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  bool isLoading = false;
  int selectedIndex = 0;
  List<DateTime> dateList = [];
  List<String> dayList = [];

  Map<String, dynamic> sessionData = {};
  ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  final random = Random();

  List<Color> borderColors = [
    AppColors.redColor,
    AppColors.lightBlueColor,
    AppColors.lightGreenColor,
    AppColors.orangeColor,
    AppColors.purpleColor,
    AppColors.pinkColor,
    Colors.teal,
    Colors.indigo,
    AppColors.yellowColor,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _fetchTutorAvailableSlots(widget.tutorDetail['id']);
    _scrollController = ScrollController();
  }

  Future<void> _fetchTutorAvailableSlots(int tutorId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      setState(() {
        isLoading = true;
      });

      final response = await getTutorAvailableSlots(token!, tutorId.toString());

      if (response['status'] == 401) {
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
      }

      final String startDateStr = response['data']['start_date'];
      final String endDateStr = response['data']['end_date'];

      DateTime startDate = DateTime.parse(startDateStr);
      DateTime endDate = DateTime.parse(endDateStr);

      _generateDateAndDayList(startDate, endDate);

      setState(() {
        sessionData = response['data'];
      });

      int firstAvailableIndex = -1;
      DateTime? firstAvailableDate;

      for (int i = 0; i < dateList.length; i++) {
        String dateKey = DateFormat('dd MMM yyyy').format(dateList[i]);
        if (response['data'].containsKey(dateKey)) {
          firstAvailableIndex = i;
          firstAvailableDate = dateList[i];
          break;
        }
      }

      if (firstAvailableIndex != -1 && firstAvailableDate != null) {
        setState(() {
          selectedIndex = firstAvailableIndex;
        });
        await _fetchSessionsForSelectedDate(firstAvailableDate);
      }
    } catch (e) {
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSessionsForSelectedDate(DateTime date) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      setState(() {
        isLoading = true;
      });

      final response = await getTutorAvailableSlots(
        token!,
        widget.tutorDetail['id'].toString(),
      );

      if (response['status'] == 401) {
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
      }

      setState(() {
        sessionData = response['data'];
      });
    } catch (e) {
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _generateDateAndDayList(DateTime startDate, DateTime endDate) {
    List<DateTime> dates = [];
    List<String> days = [];

    for (
      var date = startDate;
      date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
      date = date.add(Duration(days: 1))
    ) {
      dates.add(date);
      days.add(DateFormat('EEE').format(date));
    }

    setState(() {
      dateList = dates;
      dayList = days;
    });
  }

  Color getRandomBorderColor() {
    return borderColors[random.nextInt(borderColors.length)];
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
            return !isLoading;
          },
          child: Directionality(
            textDirection: Localization.textDirection,
            child: Scaffold(
              backgroundColor: AppColors.backgroundColor(context),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(150.0),
                child: Container(
                  color: AppColors.whiteColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: AppBar(
                      backgroundColor: AppColors.whiteColor,
                      forceMaterialTransparency: true,
                      centerTitle: false,
                      elevation: 0,
                      titleSpacing: 0,
                      title: Text(
                        '${Localization.translate("book_session")}',
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
                      flexibleSpace: Align(
                        alignment: Alignment.bottomCenter,
                        child:
                            isLoading
                                ? DateSelectorSkeleton()
                                : _buildDateSelector(),
                      ),
                    ),
                  ),
                ),
              ),
              body: isLoading ? BookSessionSkeleton() : _buildSessionList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    if (isLoading) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen(context),
            strokeWidth: 2.0,
          ),
        ),
      );
    }

    if (dateList.isEmpty || dayList.isEmpty) {
      return Container(
        height: 80,
        child: Center(child: Text('${Localization.translate("dates_empty")}')),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final offset = selectedIndex * 100.0;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        if (offset <= maxScrollExtent) {
          _scrollController.jumpTo(offset);
        } else {
          _scrollController.jumpTo(maxScrollExtent);
        }
      }
    });

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor(context),
        border: Border(
          bottom: BorderSide(width: 2, color: AppColors.bookBorderPinkColor),
        ),
      ),
      child: ListView.builder(
        key: PageStorageKey('dateListKey'),
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dateList.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
              _fetchSessionsForSelectedDate(dateList[index]);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.whiteColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd MMM').format(dateList[index]),
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      dayList[index],
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 12),
                        fontFamily: AppFontFamily.regularFont,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionList() {
    if (dateList.isEmpty) {
      return Center(
        child: Text(
          '${Localization.translate("session_empty")}',
          style: TextStyle(
            color: AppColors.greyColor(context),
            fontSize: FontSize.scale(context, 14),
            fontFamily: AppFontFamily.mediumFont,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
      );
    }

    String selectedDate = DateFormat(
      'dd MMM yyyy',
    ).format(dateList[selectedIndex]);

    if (sessionData.containsKey(selectedDate)) {
      List<dynamic> sessions = sessionData[selectedDate];

      if (sessions.isEmpty) {
        return Center(
          child: Text(
            '${Localization.translate("unavailable_session_selected")}',
            style: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 14),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final totalSlots = session['total_slots'];
          final slotsLeft = session['available_slots'];
          final bookedSlots = session['booked_slots'];

          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: getRandomBorderColor(), width: 1.5),
              ),
            ),
            child: SessionCard(
              slotsLeft: slotsLeft,
              totalSlots: totalSlots,
              bookedSlots: bookedSlots,
              borderColor: getRandomBorderColor(),
              description: session['description'],
              sessionDate: selectedDate,
              sessionData: session,
              tutorDetail: widget.tutorDetail,
              onSessionUpdated: () {
                _fetchTutorAvailableSlots(widget.tutorDetail['id']);
              },
            ),
          );
        },
      );
    } else {
      return Center(
        child: Text(
          '${Localization.translate("unavailable_session_selected")}',
          style: TextStyle(
            color: AppColors.greyColor(context),
            fontSize: FontSize.scale(context, 14),
            fontFamily: AppFontFamily.mediumFont,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
      );
    }
  }
}
