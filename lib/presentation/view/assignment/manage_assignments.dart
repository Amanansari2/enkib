import 'package:flutter/material.dart';
import 'package:flutter_projects/data/provider/auth_provider.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/assignment/startAssignment/start_assignment.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../base_components/textfield.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../styles/app_styles.dart';
import '../community/component/bouncer.dart';
import '../components/internet_alert.dart';
import 'component/assignment_card.dart';
import 'component/skeleton/assignment_card_skeleton.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart';

class ManageAssignments extends StatefulWidget {
  const ManageAssignments({super.key});

  @override
  State<ManageAssignments> createState() => _ManageAssignmentsState();
}

class _ManageAssignmentsState extends State<ManageAssignments>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> upcomingAssignments = [];
  List<Map<String, dynamic>> attemptedAssignments = [];
  List<Map<String, dynamic>> overdueAssignments = [];
  List<Map<String, dynamic>> allAssignments = [];
  int currentTabIndex = 0;

  bool isLoading = false;

  TextEditingController _searchController = TextEditingController();
  final _bounce = Bouncer(milliseconds: 500);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  int totalAssignments = 0;
  bool isRefreshing = false;
  int currentPage = 1;
  int page = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  int totalUpcomingAssignments = 0;
  int totalAttemptedAssignments = 0;
  int totalOverdueAssignments = 0;
  int totalAllAssignments = 0;

  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchAssignmentsListing(studentStatus: '');
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _onTabTapped(_tabController.index);
    });
  }

  Future<void> fetchAssignmentsListing({
    bool isLoadMore = false,
    String? keyword,
    String studentStatus = '',
  }) async {
    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        if (studentStatus == '3') {
          upcomingAssignments.clear();
        } else if (studentStatus == '2') {
          attemptedAssignments.clear();
        } else if (studentStatus == 'overdue') {
          overdueAssignments.clear();
        } else {
          allAssignments.clear();
        }
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
      List<Map<String, dynamic>> allNewAssignments = [];

      while (hasMore) {
        final response = await getAssignmentsListing(
          token!,
          keyword: keyword,
          page: page,
          studentStatus: studentStatus,
        );

        if (response['status'] == 200 && response['data']['list'] is List) {
          final List<Map<String, dynamic>> newAssignments =
              List<Map<String, dynamic>>.from(response['data']['list']);

          for (var assignment in newAssignments) {
            if (!allNewAssignments.any((a) => a['id'] == assignment['id'])) {
              allNewAssignments.add(assignment);
            }
          }

          final pagination = response['data']['pagination'];
          if (pagination['currentPage'] < pagination['totalPages']) {
            page++;
          } else {
            hasMore = false;
            setState(() {
              isLoading = false;
              if (studentStatus == '3') {
                if (isLoadMore) {
                  upcomingAssignments.addAll(allNewAssignments);
                } else {
                  upcomingAssignments = allNewAssignments;
                }
                totalUpcomingAssignments = pagination['total'];
              } else if (studentStatus == '2') {
                if (isLoadMore) {
                  attemptedAssignments.addAll(allNewAssignments);
                } else {
                  attemptedAssignments = allNewAssignments;
                }
                totalAttemptedAssignments = pagination['total'];
              } else if (studentStatus == 'overdue') {
                if (isLoadMore) {
                  overdueAssignments.addAll(allNewAssignments);
                } else {
                  overdueAssignments = allNewAssignments;
                }
                totalOverdueAssignments = pagination['total'];
              } else {
                if (isLoadMore) {
                  allAssignments.addAll(allNewAssignments);
                } else {
                  allAssignments = allNewAssignments;
                }
                totalAllAssignments = pagination['total'];
              }
              totalPages = pagination['totalPages'];
              currentPage = pagination['currentPage'];
            });
          }
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
          break;
        } else {
          showCustomToast(context, response['message'] ?? "Error", false);
          break;
        }
      }
    } catch (e, stack) {
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> fetchSearchAssignments({String title = ''}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      String studentStatus;
      if (currentTabIndex == 0) {
        studentStatus = '';
      } else if (currentTabIndex == 1) {
        studentStatus = '3';
      } else if (currentTabIndex == 2) {
        studentStatus = '2';
      } else {
        studentStatus = 'overdue';
      }

      final response = await getAssignmentsListing(
        token!,
        keyword: title,
        studentStatus: studentStatus,
      );

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            List<Map<String, dynamic>> newAssignments =
                List<Map<String, dynamic>>.from(response['data']['list']);
            if (studentStatus == '') {
              allAssignments = newAssignments;
            } else if (studentStatus == '3') {
              upcomingAssignments = newAssignments;
            } else if (studentStatus == '2') {
              attemptedAssignments = newAssignments;
            } else if (studentStatus == 'overdue') {
              overdueAssignments = newAssignments;
            }
            isSearching = true;
          });
        }
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
        return;
      }
    } catch (e) {}
  }

  Future<void> refreshAssignments() async {
    setState(() {
      isRefreshing = true;
      currentPage = 1;
    });

    String studentStatus;
    if (currentTabIndex == 0) {
      studentStatus = '';
    } else if (currentTabIndex == 1) {
      studentStatus = '3';
    } else if (currentTabIndex == 2) {
      studentStatus = '2';
    } else {
      studentStatus = 'overdue';
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      int page = 1;
      bool hasMore = true;
      List<Map<String, dynamic>> allNewAssignments = [];

      while (hasMore) {
        final response = await getAssignmentsListing(
          token!,
          page: page,
          studentStatus: studentStatus,
        );

        if (response['status'] == 200 && response['data']['list'] is List) {
          final List<Map<String, dynamic>> newAssignments =
              List<Map<String, dynamic>>.from(response['data']['list']);

          for (var assignment in newAssignments) {
            if (!allNewAssignments.any((a) => a['id'] == assignment['id'])) {
              allNewAssignments.add(assignment);
            }
          }

          final pagination = response['data']['pagination'];
          if (pagination['currentPage'] < pagination['totalPages']) {
            page++;
          } else {
            hasMore = false;
            setState(() {
              if (studentStatus == '3') {
                upcomingAssignments = allNewAssignments;
                totalUpcomingAssignments = pagination['total'];
              } else if (studentStatus == '2') {
                attemptedAssignments = allNewAssignments;
                totalAttemptedAssignments = pagination['total'];
              } else if (studentStatus == 'overdue') {
                overdueAssignments = allNewAssignments;
                totalOverdueAssignments = pagination['total'];
              } else {
                allAssignments = allNewAssignments;
                totalAllAssignments = pagination['total'];
              }
              totalPages = pagination['totalPages'];
              currentPage = pagination['currentPage'];
            });
          }
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
          break;
        } else {
          showCustomToast(context, response['message'] ?? "Error", false);
          break;
        }
      }
    } catch (e, stack) {
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      currentTabIndex = index;
    });
    String studentStatus;
    List<Map<String, dynamic>> targetList;
    if (index == 0) {
      studentStatus = '';
      targetList = allAssignments;
    } else if (index == 1) {
      studentStatus = '3';
      targetList = upcomingAssignments;
    } else if (index == 2) {
      studentStatus = '2';
      targetList = attemptedAssignments;
    } else {
      studentStatus = 'overdue';
      targetList = overdueAssignments;
    }
    if (targetList.isEmpty) {
      fetchAssignmentsListing(studentStatus: studentStatus);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int currentItemsCount;
    if (currentTabIndex == 0) {
      currentItemsCount = allAssignments.length;
    } else if (currentTabIndex == 1) {
      currentItemsCount = upcomingAssignments.length;
    } else if (currentTabIndex == 2) {
      currentItemsCount = attemptedAssignments.length;
    } else {
      currentItemsCount = overdueAssignments.length;
    }
    int totalAssignmentsToShow = totalAllAssignments;

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
                            '${(Localization.translate('manage_assignments') ?? '').trim() != 'manage_assignments' && (Localization.translate('manage_assignments') ?? '').trim().isNotEmpty ? Localization.translate('manage_assignments') : 'Manage Your Assignments'}',
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
                                      currentTabIndex == 0
                                          ? "${currentItemsCount}/${totalAssignmentsToShow}"
                                          : currentTabIndex == 1
                                          ? "${currentItemsCount}/${totalUpcomingAssignments}"
                                          : currentTabIndex == 2
                                          ? "${currentItemsCount}/${totalAttemptedAssignments}"
                                          : "${currentItemsCount}/${totalOverdueAssignments}",
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
                                      '${(Localization.translate("assignments_available")).trim().isNotEmpty ? (currentItemsCount <= 1 ? Localization.translate("assignments_available")?.replaceAll("Assignments", "Assignment") : Localization.translate("assignments_available")) : (currentItemsCount <= 1 ? "Assignment available" : "Assignments available")}',
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
              body: Column(
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
                              '${(Localization.translate('search_keyword') ?? '').trim() != 'search_keyword' && (Localization.translate('search_keyword') ?? '').trim().isNotEmpty ? Localization.translate('search_keyword') : 'Search by keyword'}',
                          searchIcon: true,
                          controller: _searchController,
                          mandatory: false,
                          onChanged: (value) {
                            _bounce.run(() {
                              String searchQuery =
                                  _searchController.text.trim();
                              fetchSearchAssignments(title: searchQuery);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  isLoading
                      ? TabBarShimmer()
                      : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                                    '${(Localization.translate('upcoming') ?? '').trim() != 'upcoming' && (Localization.translate('upcoming') ?? '').trim().isNotEmpty ? Localization.translate('upcoming') : 'Upcoming'}',
                              ),
                              Tab(
                                text:
                                    '${(Localization.translate('attempted') ?? '').trim() != 'attempted' && (Localization.translate('attempted') ?? '').trim().isNotEmpty ? Localization.translate('attempted') : 'Attempted'}',
                              ),
                              Tab(
                                text:
                                    '${(Localization.translate('overdue') ?? '').trim() != 'overdue' && (Localization.translate('overdue') ?? '').trim().isNotEmpty ? Localization.translate('overdue') : 'Overdue'}',
                              ),
                            ],
                            onTap: _onTabTapped,
                          ),
                        ),
                      ),

                  SizedBox(height: 10),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent(
                          isLoading && currentTabIndex == 0,
                          allAssignments,
                        ),
                        _buildTabContent(
                          isLoading && currentTabIndex == 1,
                          upcomingAssignments,
                        ),
                        _buildTabContent(
                          isLoading && currentTabIndex == 2,
                          attemptedAssignments,
                        ),
                        _buildTabContent(
                          isLoading && currentTabIndex == 3,
                          overdueAssignments,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(
    bool isLoading,
    List<Map<String, dynamic>> assignments,
  ) {
    final listToShow = assignments;
    return Expanded(
      child: RefreshIndicator(
        onRefresh: refreshAssignments,
        color: AppColors.primaryGreen(context),
        child:
            isLoading
                ? ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => AssignmentCardSkeleton(),
                )
                : listToShow.isNotEmpty
                ? NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!isRefreshing &&
                        scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        !isLoadingMore &&
                        currentPage < totalPages) {
                      fetchAssignmentsListing(
                        isLoadMore: true,
                        studentStatus:
                            currentTabIndex == 0
                                ? ''
                                : currentTabIndex == 1
                                ? '3'
                                : currentTabIndex == 2
                                ? '2'
                                : 'overdue',
                      );
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: listToShow.length + (isLoadingMore ? 1 : 0),
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    itemBuilder: (context, index) {
                      if (isLoadingMore && index == listToShow.length) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: 10.0,
                              left: 10,
                              top: 10,
                              bottom: 50,
                            ),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryGreen(context),
                              strokeWidth: 2.0,
                            ),
                          ),
                        );
                      }
                      var assignment = listToShow[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => StartAssignment(
                                    assignmentId: assignment['id'].toString(),
                                  ),
                            ),
                          );
                        },
                        child: AssignmentCard(
                          title: assignment['title'] ?? '',
                          deadline: formatDeadline(assignment['ended_at']),
                          totalMarks: assignment['total_marks'] ?? 0,
                          passingGrade: assignment['passing_percentage'] ?? 0,
                          category:
                              assignment['related_type'] == 'Course'
                                  ? 'Course'
                                  : 'Subject',
                          imageUrl: assignment['image'] ?? '',
                        ),
                      );
                    },
                  ),
                )
                : _buildEmptyView(),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(AppImages.emptyAssignment, width: 80, height: 80),
          Text(
            '${(Localization.translate('no_assignment_found') ?? '').trim() != 'no_assignment_found' && (Localization.translate('no_assignment_found') ?? '').trim().isNotEmpty ? Localization.translate('no_assignment_found') : 'No Assignment Found'}',
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 16),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
            ),
          ),
          Text(
            '${(Localization.translate('no_assignments_available') ?? '').trim() != 'no_assignments_available' && (Localization.translate('no_assignments_available') ?? '').trim().isNotEmpty ? Localization.translate('no_assignments_available') : 'No assignments available at the moment.'}',
            style: TextStyle(
              color: AppColors.greyColor(context).withOpacity(0.7),
              fontSize: FontSize.scale(context, 16),
              fontFamily: AppFontFamily.regularFont,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
