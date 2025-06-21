import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import 'package:flutter_projects/presentation/view/tutor/assignment/create_assignment.dart';
import 'package:flutter_projects/presentation/view/tutor/assignment/reviewAssignment/review_assignment.dart';
import 'package:flutter_projects/presentation/view/tutor/assignment/skeleton/tutor_submit_assignment_skeleton.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../../base_components/textfield.dart';
import '../../../../data/localization/localization.dart';
import '../../../../styles/app_styles.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../community/component/bouncer.dart';
import 'component/student_assignment_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart'
    as CustomDateUtils;

class TutorSubmitAssignment extends StatefulWidget {
  final String? id;
  const TutorSubmitAssignment({super.key, this.id});

  @override
  State<TutorSubmitAssignment> createState() => _TutorSubmitAssignmentState();
}

class _TutorSubmitAssignmentState extends State<TutorSubmitAssignment>
    with SingleTickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  final _bounce = Bouncer(milliseconds: 500);
  bool _isExpanded = false;
  bool _isLoading = false;
  Map<String, dynamic>? _assignmentData;
  String currentStatus = '';
  bool isSearching = false;
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> displayedAssignments = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;

  Future<void> _fetchSubmittedAssignments({String? status}) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null || widget.id == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await getSubmittedAssignmentsDetail(
        token,
        status: status,
        id: widget.id.toString(),
      );

      if (response != null && response['status'] == 200) {
        setState(() {
          displayedAssignments = List<Map<String, dynamic>>.from(
            response['data']['list'] ?? [],
          );
        });
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate("invalidToken"),
              content: Localization.translate("loginAgain"),
              buttonText: Localization.translate("goToLogin"),
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
        showCustomToast(context, response['message'] ?? "Error", false);
        setState(() {
          _isLoading = false;
        });
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    String? status;
    if (index == 1) {
      status = '1';
      _searchController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (index == 2) {
      status = '0';
      _searchController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (index == 3) {
      status = '2';
      _searchController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      status = '';
      _searchController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _fetchSubmittedAssignments(status: status);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabTapped(_tabController.index);
    });

    _fetchAssignmentDetails();
    _fetchSubmittedAssignments();
  }

  Future<void> _fetchAssignmentDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getTutorAssignmentDetail(token, widget.id);

      if (response != null && response['status'] == 200) {
        setState(() {
          _assignmentData = response['data'];
        });
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate("invalidToken"),
              content: Localization.translate("loginAgain"),
              buttonText: Localization.translate("goToLogin"),
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
        showCustomToast(context, response['message'] ?? "Error", false);
        setState(() {
          _isLoading = false;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchSearchSubmittedAssignments({String title = ''}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null || widget.id == null) {
        return;
      }

      int tabIndex = _tabController.index;
      if (tabIndex == 0) {
        currentStatus = '';
      } else if (tabIndex == 1) {
        currentStatus = '1';
      } else if (tabIndex == 2) {
        currentStatus = '0';
      } else if (tabIndex == 3) {
        currentStatus = '2';
      }

      final response = await getSubmittedAssignmentsDetail(
        token,
        status: currentStatus,
        id: widget.id.toString(),
        keyword: title,
      );

      if (response != null && response['status'] == 200) {
        setState(() {
          displayedAssignments = List<Map<String, dynamic>>.from(
            response['data']['list'] ?? [],
          );
          isSearching = title.isNotEmpty;
        });
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate("invalidToken"),
              content: Localization.translate("loginAgain"),
              buttonText: Localization.translate("goToLogin"),
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
        showCustomToast(context, response['message'] ?? "Error", false);
        setState(() {
          _isLoading = false;
        });
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.backgroundColor(context),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            Localization.textDirection == TextDirection.rtl ? 70.0 : 50.0,
          ),

          child: Container(
            color: AppColors.whiteColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: AppBar(
                backgroundColor: AppColors.whiteColor,
                elevation: 0,
                titleSpacing: 0,
                forceMaterialTransparency: true,
                title: Text(
                  "${(Localization.translate('submit_assignment') ?? '').trim() != 'submit_assignment' && (Localization.translate('submit_assignment') ?? '').trim().isNotEmpty ? Localization.translate('submit_assignment') : 'Submit Assignment'}",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 20),
                    fontFamily: AppFontFamily.mediumFont,
                    fontWeight: FontWeight.w600,
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
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
                centerTitle: false,
              ),
            ),
          ),
        ),
        body:
            _isLoading
                ? TutorSubmitAssignmentSkeleton()
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        left: 15,
                        right: 15.0,
                        bottom: 20.0,
                        top: 30.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20.0),
                          bottomLeft: Radius.circular(20.0),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                          left: 20.0,
                          top: 16,
                          right: 20,
                          bottom:
                              Localization.textDirection == TextDirection.rtl
                                  ? 55.0
                                  : 20.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          image: DecorationImage(
                            image: AssetImage(AppImages.forumBg),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.translate(
                                  offset: Offset(-5.0, 10.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),

                                    child: CachedNetworkImage(
                                      imageUrl:
                                          _assignmentData?['attachments'] ?? "",
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        AppColors.primaryGreen(
                                                          context,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Image.asset(
                                            AppImages.placeHolderImage,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 5),
                                      Text(
                                        _assignmentData?['title'] ?? "",
                                        style: TextStyle(
                                          color: AppColors.blackColor,
                                          fontSize: FontSize.scale(context, 16),
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w500,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 2,
                                      ),
                                      SizedBox(height: 8),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  _assignmentData?['description'] !=
                                                          null
                                                      ? (_isExpanded
                                                          ? _assignmentData!['description']
                                                          : _assignmentData!['description']
                                                                  .split(' ')
                                                                  .take(20)
                                                                  .join(' ') +
                                                              (_assignmentData!['description']
                                                                          .split(
                                                                            ' ',
                                                                          )
                                                                          .length >
                                                                      20
                                                                  ? '...'
                                                                  : ' '))
                                                      : " ",
                                              style: TextStyle(
                                                color: AppColors.greyColor(
                                                  context,
                                                ),
                                                fontSize: FontSize.scale(
                                                  context,
                                                  14,
                                                ),
                                                fontFamily:
                                                    AppFontFamily.regularFont,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            TextSpan(text: " "),
                                            if (_assignmentData?['description'] !=
                                                    null &&
                                                _assignmentData!['description']
                                                        .split(' ')
                                                        .length >
                                                    20)
                                              TextSpan(
                                                text:
                                                    _isExpanded
                                                        ? "${(Localization.translate('read_less') ?? '').trim() != 'read_less' && (Localization.translate('read_less') ?? '').trim().isNotEmpty ? Localization.translate('read_less') : 'Read less'}"
                                                        : "${(Localization.translate('read_more') ?? '').trim() != 'read_more' && (Localization.translate('read_more') ?? '').trim().isNotEmpty ? Localization.translate('read_more') : 'Read more'}",
                                                style: TextStyle(
                                                  color: AppColors.blueColor,
                                                  fontSize: FontSize.scale(
                                                    context,
                                                    14,
                                                  ),
                                                  fontFamily:
                                                      AppFontFamily.regularFont,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () {
                                                        setState(() {
                                                          _isExpanded =
                                                              !_isExpanded;
                                                        });
                                                      },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      AppImages.type,
                                      width: 18,
                                      height: 18,
                                      color: AppColors.greyColor(context),
                                    ),
                                    SizedBox(width: 4),
                                    Text.rich(
                                      TextSpan(
                                        children: <TextSpan>[
                                          TextSpan(
                                            text:
                                                _assignmentData?['related_type'] ??
                                                '',
                                            style: TextStyle(
                                              color: AppColors.greyColor(
                                                context,
                                              ),
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontWeight: FontWeight.w500,
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                            ),
                                          ),
                                          TextSpan(text: ' '),
                                          TextSpan(
                                            text:
                                                "${(Localization.translate('assignment_for') ?? '').trim() != 'assignment_for' && (Localization.translate('assignment_for') ?? '').trim().isNotEmpty ? Localization.translate('assignment_for') : 'Assignment for'}",
                                            style: TextStyle(
                                              color: AppColors.greyColor(
                                                context,
                                              ).withOpacity(0.7),
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontWeight: FontWeight.w400,
                                              fontFamily:
                                                  AppFontFamily.regularFont,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      AppImages.identityVerification,
                                      width: 15,
                                      height: 15,
                                      color: AppColors.greyColor(context),
                                    ),
                                    SizedBox(width: 4),

                                    Text.rich(
                                      TextSpan(
                                        children: <TextSpan>[
                                          TextSpan(
                                            text:
                                                _assignmentData?['submissions_assignments_count']
                                                    ?.toString() ??
                                                '',
                                            style: TextStyle(
                                              color: AppColors.greyColor(
                                                context,
                                              ),
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontWeight: FontWeight.w500,
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                            ),
                                          ),
                                          TextSpan(text: ' '),
                                          TextSpan(
                                            text:
                                                "${(Localization.translate('attempted') ?? '').trim() != 'attempted' && (Localization.translate('attempted') ?? '').trim().isNotEmpty ? Localization.translate('attempted') : 'Attempted'}",
                                            style: TextStyle(
                                              color: AppColors.greyColor(
                                                context,
                                              ).withOpacity(0.7),
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontWeight: FontWeight.w400,
                                              fontFamily:
                                                  AppFontFamily.regularFont,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 30,
                          child: CustomTextField(
                            hint:
                                '${(Localization.translate('search_keyword') ?? '').trim() != 'search_keyword' && (Localization.translate('search_keyword') ?? '').trim().isNotEmpty ? Localization.translate('search_keyword') : 'Search with keyword'}',
                            searchIcon: true,
                            controller: _searchController,
                            mandatory: false,
                            onChanged: (value) {
                              _bounce.run(() {
                                String searchQuery =
                                    _searchController.text.trim();
                                fetchSearchSubmittedAssignments(
                                  title: searchQuery,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.91,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          tabAlignment: TabAlignment.center,
                          indicatorPadding: EdgeInsets.zero,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.greyFadeColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorWeight: 2.0,
                          labelColor: AppColors.blackColor,
                          unselectedLabelColor: AppColors.greyColor(context),
                          labelStyle: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w500,
                          ),
                          unselectedLabelStyle: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 14),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: [
                            Tab(
                              text:
                                  '${(Localization.translate('all') ?? '').trim() != 'all' && (Localization.translate('all') ?? '').trim().isNotEmpty ? Localization.translate('all') : 'All'}',
                            ),
                            Tab(
                              text:
                                  '${(Localization.translate('pass') ?? '').trim() != 'pass' && (Localization.translate('pass') ?? '').trim().isNotEmpty ? Localization.translate('pass') : 'Pass'}',
                            ),
                            Tab(
                              text:
                                  '${(Localization.translate('fail') ?? '').trim() != 'fail' && (Localization.translate('fail') ?? '').trim().isNotEmpty ? Localization.translate('fail') : 'Fail'}',
                            ),
                            Tab(
                              text:
                                  '${(Localization.translate('in_review') ?? '').trim() != 'in_review' && (Localization.translate('in_review') ?? '').trim().isNotEmpty ? Localization.translate('in_review') : 'In review'}',
                            ),
                          ],
                          onTap: _onTabTapped,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          displayedAssignments.isNotEmpty
                              ? ListView.builder(
                                itemCount: displayedAssignments.length,
                                itemBuilder: (context, index) {
                                  var assignment = displayedAssignments[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ReviewAssignment(
                                                assignmentId:
                                                    assignment['id'].toString(),
                                              ),
                                        ),
                                      );
                                    },
                                    child: StudentSubmitInfo(
                                      name:
                                          assignment['student']['name']
                                              .toString(),
                                      email:
                                          assignment['student']['email']
                                              .toString(),
                                      obtainedMarks:
                                          assignment['marks_awarded']
                                              ?.toString() ??
                                          '0',
                                      statusText:
                                          assignment['result'].toString() ==
                                                  'pass'
                                              ? 'Pass'
                                              : assignment['result']
                                                      .toString() ==
                                                  'in_review'
                                              ? 'In review'
                                              : 'Fail',
                                      submitDate: CustomDateUtils.formatDate(
                                        assignment['submitted_at'],
                                      ),
                                      imageUrl:
                                          assignment['student']['image']
                                              .toString(),
                                    ),
                                  );
                                },
                              )
                              : _buildEmptyView(),

                          displayedAssignments.isNotEmpty
                              ? ListView.builder(
                                itemCount: displayedAssignments.length,
                                itemBuilder: (context, index) {
                                  var assignment = displayedAssignments[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ReviewAssignment(
                                                assignmentId:
                                                    assignment['id'].toString(),
                                              ),
                                        ),
                                      );
                                    },
                                    child: StudentSubmitInfo(
                                      name:
                                          assignment['student']['name']
                                              .toString(),
                                      email:
                                          assignment['student']['email']
                                              .toString(),
                                      obtainedMarks:
                                          assignment['marks_awarded']
                                              ?.toString() ??
                                          '0',
                                      statusText:
                                          assignment['result'].toString() ==
                                                  'pass'
                                              ? 'Pass'
                                              : assignment['result']
                                                      .toString() ==
                                                  'in_review'
                                              ? 'In review'
                                              : 'Fail',
                                      submitDate: CustomDateUtils.formatDate(
                                        assignment['submitted_at'],
                                      ),
                                      imageUrl:
                                          assignment['student']['image']
                                              .toString(),
                                    ),
                                  );
                                },
                              )
                              : _buildEmptyView(),

                          displayedAssignments.isNotEmpty
                              ? ListView.builder(
                                itemCount: displayedAssignments.length,
                                itemBuilder: (context, index) {
                                  var assignment = displayedAssignments[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ReviewAssignment(
                                                assignmentId:
                                                    assignment['id'].toString(),
                                              ),
                                        ),
                                      );
                                    },
                                    child: StudentSubmitInfo(
                                      name:
                                          assignment['student']['name']
                                              .toString(),
                                      email:
                                          assignment['student']['email']
                                              .toString(),
                                      obtainedMarks:
                                          assignment['marks_awarded']
                                              ?.toString() ??
                                          '0',
                                      statusText:
                                          assignment['result'].toString() ==
                                                  'pass'
                                              ? 'Pass'
                                              : assignment['result']
                                                      .toString() ==
                                                  'in_review'
                                              ? 'In review'
                                              : 'Fail',
                                      submitDate: CustomDateUtils.formatDate(
                                        assignment['submitted_at'],
                                      ),
                                      imageUrl:
                                          assignment['student']['image']
                                              .toString(),
                                    ),
                                  );
                                },
                              )
                              : _buildEmptyView(),
                          displayedAssignments.isNotEmpty
                              ? ListView.builder(
                                itemCount: displayedAssignments.length,
                                itemBuilder: (context, index) {
                                  var assignment = displayedAssignments[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ReviewAssignment(
                                                assignmentId:
                                                    assignment['id'].toString(),
                                              ),
                                        ),
                                      );
                                    },
                                    child: StudentSubmitInfo(
                                      name:
                                          assignment['student']['name']
                                              .toString(),
                                      email:
                                          assignment['student']['email']
                                              .toString(),
                                      obtainedMarks:
                                          assignment['marks_awarded']
                                              ?.toString() ??
                                          '0',
                                      statusText:
                                          assignment['result'].toString() ==
                                                  'pass'
                                              ? 'Pass'
                                              : assignment['result']
                                                      .toString() ==
                                                  'in_review'
                                              ? 'In review'
                                              : 'Fail',
                                      submitDate: CustomDateUtils.formatDate(
                                        assignment['submitted_at'],
                                      ),
                                      imageUrl:
                                          assignment['student']['image']
                                              .toString(),
                                    ),
                                  );
                                },
                              )
                              : _buildEmptyView(),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppImages.emptyAssignment, width: 80, height: 80),
            SizedBox(height: 10),
            Text(
              '${(Localization.translate('record_empty') ?? '').trim() != 'record_empty' && (Localization.translate('record_empty') ?? '').trim().isNotEmpty ? Localization.translate('record_empty') : 'No record added yet!'}',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '${(Localization.translate('create_assignments_subtitle') ?? '').trim() != 'create_assignments_subtitle' && (Localization.translate('create_assignments_subtitle') ?? '').trim().isNotEmpty ? Localization.translate('create_assignments_subtitle') : 'Create Assignments that inspire learning Please hit the button below to add a new one.'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.greyColor(context).withOpacity(0.7),
                fontSize: FontSize.scale(context, 16),
                fontFamily: AppFontFamily.regularFont,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAssignmentScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen(context),
                minimumSize: Size(20, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(Localization.translate('create_assignments') ?? '').trim() != 'create_assignments' && (Localization.translate('create_assignments') ?? '').trim().isNotEmpty ? Localization.translate('create_assignments') : 'Create Assignments'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.mediumFont,
                      color: AppColors.whiteColor,
                    ),
                  ),
                  SizedBox(width: 10),
                  SvgPicture.asset(
                    AppImages.addIcon,
                    width: 20,
                    height: 20,
                    color: AppColors.whiteColor,
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
