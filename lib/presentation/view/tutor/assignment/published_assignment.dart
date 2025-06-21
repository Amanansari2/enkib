import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart'
    as CustomDateUtils;
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import 'package:flutter_projects/presentation/view/tutor/assignment/create_assignment.dart';
import 'package:flutter_projects/presentation/view/tutor/assignment/tutor_submit_assignment.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../base_components/textfield.dart';
import '../../../../data/localization/localization.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import '../../../../styles/app_styles.dart';
import '../../assignment/component/assignment_card.dart';
import '../../community/component/bouncer.dart';
import '../../components/internet_alert.dart';
import 'skeleton/published_assignment_skeleton.dart';

class PublishedAssignment extends StatefulWidget {
  const PublishedAssignment({super.key});

  @override
  State<PublishedAssignment> createState() => _PublishedAssignmentState();
}

class _PublishedAssignmentState extends State<PublishedAssignment>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> displayedAssignments = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  int totalPages = 1;
  String? currentStatus;
  String? searchKeyword;
  bool isSearching = false;
  bool isRefreshing = false;

  final PublishedAssignmentSkeleton _skeleton =
      const PublishedAssignmentSkeleton();

  TextEditingController _searchController = TextEditingController();
  final _bounce = Bouncer(milliseconds: 500);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  int totalAssignments = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabTapped(_tabController.index);
    });
    _fetchAssignments();
  }

  Future<void> _fetchAssignments({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        assignments.clear();
        displayedAssignments.clear();
        currentPage = 1;
      });
    } else {
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      int page = isLoadMore ? currentPage + 1 : 1;
      bool hasMore = true;
      List<Map<String, dynamic>> allAssignments = [];

      while (hasMore) {
        final response = await getTutorAssignmentsListing(
          token!,
          page: page,
          keyword: searchKeyword,
          status: currentStatus,
        );

        if (response['status'] == 200 && response['data']['list'] is List) {
          final List<Map<String, dynamic>> newAssignments =
              List<Map<String, dynamic>>.from(response['data']['list']);

          for (var assignment in newAssignments) {
            if (!allAssignments.any((a) => a['id'] == assignment['id'])) {
              allAssignments.add(assignment);
            }
          }

          final pagination = response['data']['pagination'];
          if (pagination['currentPage'] < pagination['totalPages']) {
            page++;
          } else {
            hasMore = false;
            setState(() {
              if (isLoadMore) {
                assignments.addAll(allAssignments);
                displayedAssignments.addAll(allAssignments);
              } else {
                assignments = allAssignments;
                displayedAssignments = List.from(assignments);
              }
              totalAssignments = pagination['total'];
              totalPages = pagination['totalPages'];
              currentPage = pagination['currentPage'];
            });
          }
        } else if (response['status'] == 401) {
          showCustomToast(context, response['message'] ?? "Error", false);
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
          setState(() {
            isLoading = false;
            isLoadingMore = false;
          });
          showCustomToast(context, response['message'] ?? "Error", false);
        }
      }
    } catch (e) {
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      if (index == 0) {
        currentStatus = '';
        _searchController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      } else if (index == 1) {
        currentStatus = 'draft';
        _searchController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      } else if (index == 2) {
        currentStatus = 'published';
        _searchController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      } else if (index == 3) {
        currentStatus = 'archived';
        _searchController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _fetchAssignments();
    });
  }

  Future<void> fetchSearchAssignments({String title = ''}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      int tabIndex = _tabController.index;
      if (tabIndex == 0) {
        currentStatus = '';
      } else if (tabIndex == 1) {
        currentStatus = 'draft';
      } else if (tabIndex == 2) {
        currentStatus = 'published';
      } else if (tabIndex == 3) {
        currentStatus = 'archived';
      }

      int perPage = title.isEmpty ? 100 : 20;

      final response = await getTutorAssignmentsListing(
        token!,
        keyword: title,
        status: currentStatus,
        page: perPage,
      );
      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            List<Map<String, dynamic>> newAssignments =
                List<Map<String, dynamic>>.from(response['data']['list']);
            assignments = newAssignments;
            displayedAssignments = newAssignments;
            isSearching = title.isNotEmpty;
          });
        }
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'] ?? "Error", false);
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
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        showCustomToast(context, response['message'] ?? "Error", false);
      }
    } catch (e) {}
  }

  Future<void> refreshPublishedAssignments() async {
    isLoadingMore = false;
    setState(() {});
    try {
      setState(() {
        isRefreshing = true;
        currentPage = 1;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getTutorAssignmentsListing(
        token!,
        page: 1,
        keyword: searchKeyword,
        status: currentStatus,
      );

      if (response['status'] == 200 && response['data']['list'] is List) {
        setState(() {
          List<Map<String, dynamic>> newAssignments =
              List<Map<String, dynamic>>.from(response['data']['list']);
          assignments = newAssignments;
          displayedAssignments = List.from(assignments);
          final pagination = response['data']['pagination'];
          totalAssignments = pagination['total'];
          totalPages = pagination['totalPages'];
          currentPage = pagination['currentPage'];
        });
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'] ?? "Error", false);
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
        showCustomToast(context, response['message'] ?? "Error", false);
      }
    } catch (e) {
    } finally {
      setState(() {
        isRefreshing = false;
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
              floatingActionButton:
                  isLoading
                      ? _skeleton.buildFloatingActionButtonSkeleton(context)
                      : (displayedAssignments.isNotEmpty
                          ? FloatingActionButton.extended(
                            elevation: 0.0,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CreateAssignmentScreen(),
                                ),
                              );
                            },
                            label: Row(
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
                            backgroundColor: AppColors.primaryGreen(context),
                          )
                          : null),
              key: _scaffoldKey,
              backgroundColor: AppColors.backgroundColor(context),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(75.0),
                child: Container(
                  color: AppColors.whiteColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: AppBar(
                      forceMaterialTransparency: true,
                      centerTitle: false,
                      backgroundColor: AppColors.whiteColor,
                      elevation: 0,
                      titleSpacing: 0,
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(Localization.translate('publish_assignment') ?? '').trim() != 'publish_assignment' && (Localization.translate('publish_assignment') ?? '').trim().isNotEmpty ? Localization.translate('publish_assignment') : 'Published Assignment'}',
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 20),
                              fontFamily: AppFontFamily.mediumFont,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${displayedAssignments.length}/${totalAssignments.toString()}',
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 12),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.mediumFont,
                                  ),
                                ),
                                TextSpan(text: " "),
                                TextSpan(
                                  text:
                                      '${(Localization.translate("assignments_available")).trim().isNotEmpty ? (displayedAssignments.length <= 1 || totalAssignments <= 1 ? Localization.translate("assignments_available")?.replaceAll("Assignments", "Assignment") : Localization.translate("assignments_available")) : (displayedAssignments.length <= 1 || totalAssignments <= 1 ? "Assignment available" : "Assignments available")}',
                                  style: TextStyle(
                                    color: AppColors.greyColor(
                                      context,
                                    ).withOpacity(0.7),
                                    fontSize: FontSize.scale(context, 12),
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.regularFont,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                    ),
                  ),
                ),
              ),
              body:
                  isLoading
                      ? const PublishedAssignmentSkeleton()
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width - 50,
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
                                      fetchSearchAssignments(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.91,
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(20.0),
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
                                unselectedLabelColor: AppColors.greyColor(
                                  context,
                                ),
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
                                        '${(Localization.translate('draft') ?? '').trim() != 'draft' && (Localization.translate('draft') ?? '').trim().isNotEmpty ? Localization.translate('draft') : 'Draft'}',
                                  ),
                                  Tab(
                                    text:
                                        '${(Localization.translate('published') ?? '').trim() != 'published' && (Localization.translate('published') ?? '').trim().isNotEmpty ? Localization.translate('published') : 'Published'}',
                                  ),
                                  Tab(
                                    text:
                                        '${(Localization.translate('archived') ?? '').trim() != 'archived' && (Localization.translate('archived') ?? '').trim().isNotEmpty ? Localization.translate('archived') : 'Archived'}',
                                  ),
                                ],
                                onTap: _onTabTapped,
                              ),
                            ),
                          ),

                          SizedBox(height: 10),

                          Expanded(
                            child:
                                displayedAssignments.isNotEmpty
                                    ? NotificationListener<ScrollNotification>(
                                      onNotification: (
                                        ScrollNotification scrollInfo,
                                      ) {
                                        if (!isLoading &&
                                            scrollInfo.metrics.pixels ==
                                                scrollInfo
                                                    .metrics
                                                    .maxScrollExtent &&
                                            !isLoadingMore &&
                                            displayedAssignments.isNotEmpty &&
                                            currentPage < totalPages) {
                                          _fetchAssignments(isLoadMore: true);
                                        }
                                        return false;
                                      },
                                      child: ListView.builder(
                                        itemCount:
                                            displayedAssignments.length +
                                            (isLoadingMore ? 1 : 0),
                                        itemBuilder: (context, idx) {
                                          if (isLoadingMore &&
                                              idx ==
                                                  displayedAssignments.length) {
                                            return Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10.0,
                                                    ),
                                                child: CircularProgressIndicator(
                                                  color: AppColors.primaryGreen(
                                                    context,
                                                  ),
                                                  strokeWidth: 2.0,
                                                ),
                                              ),
                                            );
                                          }
                                          var assignment =
                                              displayedAssignments[idx];

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          TutorSubmitAssignment(
                                                            id:
                                                                assignment['id']
                                                                    .toString(),
                                                          ),
                                                ),
                                              );
                                            },
                                            child: AssignmentCard(
                                              title: assignment['title'] ?? '',
                                              deadline:
                                                  CustomDateUtils.formatIsoDeadline(
                                                    assignment['ended_at'],
                                                  ),
                                              totalMarks:
                                                  assignment['total_marks'] ??
                                                  0,
                                              passingGrade:
                                                  assignment['passing_percentage'] ??
                                                  0,
                                              category:
                                                  assignment['related_type'] ==
                                                          'Course'
                                                      ? 'Course'
                                                      : 'Subject',
                                              imageUrl:
                                                  assignment['image'] ?? '',
                                              statusText:
                                                  (assignment['submissions_assignments_count'] ??
                                                              0) >=
                                                          1
                                                      ? '${assignment['submissions_assignments_count']} Attempted'
                                                      : ((assignment['status'] ??
                                                                  '')
                                                              .isNotEmpty
                                                          ? '${assignment['status'][0].toUpperCase()}${assignment['status'].substring(1)}'
                                                          : ''),
                                              showMoreIcon: true,
                                              onMorePressed: () {
                                                showModalBottomSheet(
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      AppColors
                                                          .sheetBackgroundColor,
                                                  context: context,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            16,
                                                          ),
                                                        ),
                                                  ),
                                                  builder: (context) {
                                                    bool isPublishing = false;
                                                    bool isDeleting = false;
                                                    bool isArchiving = false;
                                                    return StatefulBuilder(
                                                      builder: (
                                                        context,
                                                        setModalState,
                                                      ) {
                                                        final status =
                                                            (assignment['status'] ??
                                                                    '')
                                                                .toString()
                                                                .toLowerCase();
                                                        return SafeArea(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      16.0,
                                                                  vertical: 10,
                                                                ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Center(
                                                                  child: Container(
                                                                    width: 40,
                                                                    height: 5,
                                                                    margin:
                                                                        EdgeInsets.only(
                                                                          bottom:
                                                                              16,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          Colors
                                                                              .grey[300],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  "${Localization.translate('select_option')}",
                                                                  style: TextStyle(
                                                                    color:
                                                                        AppColors
                                                                            .blackColor,
                                                                    fontSize:
                                                                        FontSize.scale(
                                                                          context,
                                                                          18,
                                                                        ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .normal,
                                                                    fontFamily:
                                                                        AppFontFamily
                                                                            .mediumFont,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 18,
                                                                ),
                                                                Container(
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          20,
                                                                        ),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(
                                                                              0.04,
                                                                            ),
                                                                        blurRadius:
                                                                            8,
                                                                        offset:
                                                                            Offset(
                                                                              0,
                                                                              2,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child: Column(
                                                                    children: [
                                                                      if (status ==
                                                                          'draft') ...[
                                                                        _buildActionTile(
                                                                          context,
                                                                          icon:
                                                                              Icons.publish,
                                                                          text:
                                                                              'Publish Assignment',
                                                                          loading:
                                                                              isPublishing,
                                                                          onTap:
                                                                              isPublishing
                                                                                  ? null
                                                                                  : () async {
                                                                                    setModalState(
                                                                                      () =>
                                                                                          isPublishing =
                                                                                              true,
                                                                                    );
                                                                                    final authProvider = Provider.of<
                                                                                      AuthProvider
                                                                                    >(
                                                                                      context,
                                                                                      listen:
                                                                                          false,
                                                                                    );
                                                                                    final token =
                                                                                        authProvider.token;
                                                                                    try {
                                                                                      final response = await publishAssignment(
                                                                                        token!,
                                                                                        id:
                                                                                            assignment['id'].toString(),
                                                                                      );

                                                                                      if (response['status'] ==
                                                                                          200) {
                                                                                        await _fetchAssignments();
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Assignment Published Successfully",
                                                                                          true,
                                                                                        );
                                                                                        Navigator.pop(
                                                                                          context,
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          401) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Error",
                                                                                          false,
                                                                                        );
                                                                                        showDialog(
                                                                                          context:
                                                                                              context,
                                                                                          barrierDismissible:
                                                                                              false,
                                                                                          builder: (
                                                                                            BuildContext context,
                                                                                          ) {
                                                                                            return CustomAlertDialog(
                                                                                              title: Localization.translate(
                                                                                                "invalidToken",
                                                                                              ),
                                                                                              content: Localization.translate(
                                                                                                "loginAgain",
                                                                                              ),
                                                                                              buttonText: Localization.translate(
                                                                                                "goToLogin",
                                                                                              ),
                                                                                              buttonAction: () {
                                                                                                Navigator.push(
                                                                                                  context,
                                                                                                  MaterialPageRoute(
                                                                                                    builder:
                                                                                                        (
                                                                                                          context,
                                                                                                        ) =>
                                                                                                            LoginScreen(),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                              showCancelButton:
                                                                                                  false,
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          403) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'],
                                                                                          false,
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          400) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'],
                                                                                          false,
                                                                                        );
                                                                                      } else {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Error",
                                                                                          false,
                                                                                        );
                                                                                      }
                                                                                    } catch (
                                                                                      e
                                                                                    ) {
                                                                                    } finally {
                                                                                      setModalState(
                                                                                        () =>
                                                                                            isPublishing =
                                                                                                false,
                                                                                      );
                                                                                    }
                                                                                  },
                                                                          color: AppColors.primaryGreen(
                                                                            context,
                                                                          ),
                                                                        ),
                                                                        Divider(
                                                                          height:
                                                                              1,
                                                                          thickness:
                                                                              1,
                                                                          color:
                                                                              Colors.grey[200],
                                                                        ),
                                                                        _buildActionTile(
                                                                          context,
                                                                          icon:
                                                                              Icons.delete,
                                                                          text:
                                                                              'Delete Assignment',
                                                                          loading:
                                                                              isDeleting,
                                                                          onTap:
                                                                              isDeleting
                                                                                  ? null
                                                                                  : () async {
                                                                                    setModalState(
                                                                                      () =>
                                                                                          isDeleting =
                                                                                              true,
                                                                                    );
                                                                                    final authProvider = Provider.of<
                                                                                      AuthProvider
                                                                                    >(
                                                                                      context,
                                                                                      listen:
                                                                                          false,
                                                                                    );
                                                                                    final token =
                                                                                        authProvider.token;
                                                                                    try {
                                                                                      final response = await deleteAssignment(
                                                                                        token!,
                                                                                        id:
                                                                                            assignment['id'].toString(),
                                                                                      );
                                                                                      if (response['status'] ==
                                                                                          200) {
                                                                                        await _fetchAssignments();
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Assignment Deleted Successfully",
                                                                                          true,
                                                                                        );
                                                                                        Navigator.pop(
                                                                                          context,
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          401) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Error",
                                                                                          false,
                                                                                        );
                                                                                        showDialog(
                                                                                          context:
                                                                                              context,
                                                                                          barrierDismissible:
                                                                                              false,
                                                                                          builder: (
                                                                                            BuildContext context,
                                                                                          ) {
                                                                                            return CustomAlertDialog(
                                                                                              title: Localization.translate(
                                                                                                "invalidToken",
                                                                                              ),
                                                                                              content: Localization.translate(
                                                                                                "loginAgain",
                                                                                              ),
                                                                                              buttonText: Localization.translate(
                                                                                                "goToLogin",
                                                                                              ),
                                                                                              buttonAction: () {
                                                                                                Navigator.push(
                                                                                                  context,
                                                                                                  MaterialPageRoute(
                                                                                                    builder:
                                                                                                        (
                                                                                                          context,
                                                                                                        ) =>
                                                                                                            LoginScreen(),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                              showCancelButton:
                                                                                                  false,
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          403) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'],
                                                                                          false,
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          400) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'],
                                                                                          false,
                                                                                        );
                                                                                      } else {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Error",
                                                                                          false,
                                                                                        );
                                                                                      }
                                                                                    } catch (
                                                                                      e
                                                                                    ) {
                                                                                    } finally {
                                                                                      setModalState(
                                                                                        () =>
                                                                                            isDeleting =
                                                                                                false,
                                                                                      );
                                                                                    }
                                                                                  },
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                      ],
                                                                      if (status ==
                                                                          'published') ...[
                                                                        _buildActionTile(
                                                                          context,
                                                                          icon:
                                                                              Icons.archive,
                                                                          text:
                                                                              'Archive Assignment',
                                                                          loading:
                                                                              isArchiving,
                                                                          onTap:
                                                                              isArchiving
                                                                                  ? null
                                                                                  : () async {
                                                                                    setModalState(
                                                                                      () =>
                                                                                          isArchiving =
                                                                                              true,
                                                                                    );
                                                                                    final authProvider = Provider.of<
                                                                                      AuthProvider
                                                                                    >(
                                                                                      context,
                                                                                      listen:
                                                                                          false,
                                                                                    );
                                                                                    final token =
                                                                                        authProvider.token;
                                                                                    try {
                                                                                      final response = await archiveAssignment(
                                                                                        token!,
                                                                                        id:
                                                                                            assignment['id'].toString(),
                                                                                      );
                                                                                      if (response['status'] ==
                                                                                          200) {
                                                                                        await _fetchAssignments();
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Assignment Archived Successfully",
                                                                                          true,
                                                                                        );
                                                                                        Navigator.pop(
                                                                                          context,
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          401) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Error",
                                                                                          false,
                                                                                        );
                                                                                        showDialog(
                                                                                          context:
                                                                                              context,
                                                                                          barrierDismissible:
                                                                                              false,
                                                                                          builder: (
                                                                                            BuildContext context,
                                                                                          ) {
                                                                                            return CustomAlertDialog(
                                                                                              title: Localization.translate(
                                                                                                "invalidToken",
                                                                                              ),
                                                                                              content: Localization.translate(
                                                                                                "loginAgain",
                                                                                              ),
                                                                                              buttonText: Localization.translate(
                                                                                                "goToLogin",
                                                                                              ),
                                                                                              buttonAction: () {
                                                                                                Navigator.push(
                                                                                                  context,
                                                                                                  MaterialPageRoute(
                                                                                                    builder:
                                                                                                        (
                                                                                                          context,
                                                                                                        ) =>
                                                                                                            LoginScreen(),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                              showCancelButton:
                                                                                                  false,
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          403) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'],
                                                                                          false,
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          400) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'],
                                                                                          false,
                                                                                        );
                                                                                      } else {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Error",
                                                                                          false,
                                                                                        );
                                                                                      }
                                                                                    } catch (
                                                                                      e
                                                                                    ) {
                                                                                    } finally {
                                                                                      setModalState(
                                                                                        () =>
                                                                                            isArchiving =
                                                                                                false,
                                                                                      );
                                                                                    }
                                                                                  },
                                                                          color: AppColors.primaryGreen(
                                                                            context,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                      if (status ==
                                                                          'archived') ...[
                                                                        _buildActionTile(
                                                                          context,
                                                                          icon:
                                                                              Icons.publish,
                                                                          text:
                                                                              'Publish Assignment',
                                                                          loading:
                                                                              isPublishing,
                                                                          onTap:
                                                                              isPublishing
                                                                                  ? null
                                                                                  : () async {
                                                                                    setModalState(
                                                                                      () =>
                                                                                          isPublishing =
                                                                                              true,
                                                                                    );
                                                                                    final authProvider = Provider.of<
                                                                                      AuthProvider
                                                                                    >(
                                                                                      context,
                                                                                      listen:
                                                                                          false,
                                                                                    );
                                                                                    final token =
                                                                                        authProvider.token;
                                                                                    try {
                                                                                      final response = await publishAssignment(
                                                                                        token!,
                                                                                        id:
                                                                                            assignment['id'].toString(),
                                                                                      );
                                                                                      if (response['status'] ==
                                                                                          200) {
                                                                                        await _fetchAssignments();
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Assignment Published Successfully",
                                                                                          true,
                                                                                        );
                                                                                        Navigator.pop(
                                                                                          context,
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          401) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Error",
                                                                                          false,
                                                                                        );
                                                                                        showDialog(
                                                                                          context:
                                                                                              context,
                                                                                          barrierDismissible:
                                                                                              false,
                                                                                          builder: (
                                                                                            BuildContext context,
                                                                                          ) {
                                                                                            return CustomAlertDialog(
                                                                                              title: Localization.translate(
                                                                                                "invalidToken",
                                                                                              ),
                                                                                              content: Localization.translate(
                                                                                                "loginAgain",
                                                                                              ),
                                                                                              buttonText: Localization.translate(
                                                                                                "goToLogin",
                                                                                              ),
                                                                                              buttonAction: () {
                                                                                                Navigator.push(
                                                                                                  context,
                                                                                                  MaterialPageRoute(
                                                                                                    builder:
                                                                                                        (
                                                                                                          context,
                                                                                                        ) =>
                                                                                                            LoginScreen(),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                              showCancelButton:
                                                                                                  false,
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          403) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'],
                                                                                          false,
                                                                                        );
                                                                                      } else if (response['status'] ==
                                                                                          400) {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'],
                                                                                          false,
                                                                                        );
                                                                                      } else {
                                                                                        showCustomToast(
                                                                                          context,
                                                                                          response['message'] ??
                                                                                              "Error",
                                                                                          false,
                                                                                        );
                                                                                      }
                                                                                    } catch (
                                                                                      e
                                                                                    ) {
                                                                                    } finally {
                                                                                      setModalState(
                                                                                        () =>
                                                                                            isPublishing =
                                                                                                false,
                                                                                      );
                                                                                    }
                                                                                  },
                                                                          color: AppColors.primaryGreen(
                                                                            context,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 18,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                    : _buildEmptyView(),
                          ),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool loading,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 16),
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
              fontFamily: AppFontFamily.mediumFont,
            ),
          ),
          if (loading) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen(context),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      horizontalTitleGap: 8,
    );
  }
}
