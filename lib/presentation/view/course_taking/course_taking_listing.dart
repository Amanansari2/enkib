import 'package:flutter/material.dart';
import 'package:flutter_projects/domain/api_structure/api_service.dart';
import 'package:flutter_projects/presentation/view/course_taking/detail/course_taking_detail.dart';
import 'package:flutter_projects/presentation/view/course_taking/skeleton/course_taking_card_skeleton.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../base_components/textfield.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../auth/login_screen.dart';
import '../community/component/bouncer.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import 'component/course_taking_card.dart';

class CourseTakingScreen extends StatefulWidget {
  @override
  State<CourseTakingScreen> createState() => _CourseTakingScreenState();
}

class _CourseTakingScreenState extends State<CourseTakingScreen> {
  TextEditingController _searchController = TextEditingController();
  final _bounce = Bouncer(milliseconds: 500);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> courses = [];

  bool isLoading = false;
  bool isRefreshing = false;
  int currentPage = 1;
  int page = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  int totalCourses = 0;

  @override
  void initState() {
    super.initState();
    fetchEnrolledCourses();
  }

  Future<void> fetchEnrolledCourses({
    bool isLoadMore = false,
    String? keyword,
    bool isPrevious = false,
  }) async {
    if ((isLoadMore && (isLoadingMore || currentPage > totalPages)) ||
        (isPrevious && currentPage <= 1)) {
      return;
    }

    try {
      if (!isLoadMore) {
        setState(() {
          isLoading = true;
          courses.clear();
          currentPage = 1;
        });
      } else {
        setState(() {
          isLoadingMore = true;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (isPrevious) currentPage--;

      final response = await getEnrolledCourse(
        token!,
        keyword: keyword,
        page: currentPage,
      );

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            List<Map<String, dynamic>> newCourses =
                List<Map<String, dynamic>>.from(response['data']['list']);

            if (isPrevious) {
              courses.insertAll(0, newCourses);
            } else {
              courses.addAll(newCourses);
              currentPage++;
            }
            totalPages = response['data']['pagination']['totalPages'];
            totalCourses = response['data']['pagination']['total'];

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
      } else {}
    } catch (e) {
    } finally {
      setState(() {
        isLoadingMore = false;
        isLoading = false;
      });
    }
  }

  Future<void> fetchSearchEnrolledCourses({String title = ''}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getEnrolledCourse(token!, keyword: title);

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            courses = List<Map<String, dynamic>>.from(response['data']['list']);
          });
        }
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
        return;
      }
    } catch (e) {}
  }

  Future<void> refreshEnrolledCourses() async {
    try {
      setState(() {
        isRefreshing = true;
        currentPage = 1;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getEnrolledCourse(token!, page: 1);

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            courses = List<Map<String, dynamic>>.from(response['data']['list']);
            totalPages = response['data']['pagination']['totalPages'];
            currentPage++;
          });
        }
      } else if (response['status'] == 401) {
        showCustomToast(
            context, Localization.translate("unauthorized_access"), false);
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
    } catch (e) {
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  Future<void> toggleFavouriteCourse(int courseId, bool isFavorite) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response =
          await addDeleteFavouriteCourse(token!, courseId, authProvider);
      if (response['status'] == 200) {
        if (isFavorite) {
        } else {}
      } else if (response['status'] == 403) {
        showCustomToast(
          context,
          response['message'],
          false,
        );
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
      } else {}
    } catch (error) {}
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
                          '${(Localization.translate('my_courses') ?? '').trim() != 'my_courses' && (Localization.translate('my_courses') ?? '').trim().isNotEmpty ? Localization.translate('my_courses') : 'My Courses'}',
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: FontSize.scale(context, 20),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "${courses.length} / ${totalCourses}",
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 12),
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.normal,
                                  fontFamily: AppFontFamily.mediumFont,
                                ),
                              ),
                              TextSpan(
                                text: " ",
                              ),
                              TextSpan(
                                text:
                                    '${(Localization.translate("courses_available")).trim().isNotEmpty ? (courses.length <= 1 ? Localization.translate("courses_available")?.replaceAll("Courses", "Course") : Localization.translate("courses_available")) : (courses.length <= 1 ? "Course available" : "Courses available")}',
                                style: TextStyle(
                                  color: AppColors.greyColor(context)
                                      .withOpacity(0.7),
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
                        icon: Icon(Icons.arrow_back_ios,
                            size: 20, color: AppColors.blackColor),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: isLoading
                ? Column(
                    children: [
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 40,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: CourseTakingCardSkeleton(),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(height: 20),
                      Container(
                        width: MediaQuery.of(context).size.width - 40,
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
                              fetchSearchEnrolledCourses(title: searchQuery);
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 5),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: refreshEnrolledCourses,
                          color: AppColors.primaryGreen(context),
                          child: Stack(
                            children: [
                              if (courses.isNotEmpty || isLoading)
                                NotificationListener<ScrollNotification>(
                                  onNotification:
                                      (ScrollNotification scrollInfo) {
                                    if (scrollInfo.metrics.pixels ==
                                            scrollInfo
                                                .metrics.maxScrollExtent &&
                                        !isLoadingMore &&
                                        courses.isNotEmpty) {
                                      fetchEnrolledCourses(isLoadMore: true);
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    itemCount: isLoadingMore
                                        ? courses.length + 1
                                        : courses.length,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.0),
                                    itemBuilder: (context, index) {
                                      if (index == courses.length) {
                                        return Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                right: 10.0,
                                                left: 10,
                                                top: 10,
                                                bottom: 50),
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryGreen(
                                                  context),
                                              strokeWidth: 2.0,
                                            ),
                                          ),
                                        );
                                      }

                                      final course = courses[index];
                                      final courseData = course['course'] ?? {};
                                      final slug =
                                          course['course']['slug'] ?? {};
                                      final instructorData =
                                          courseData['instructor'] ?? {};
                                      final thumbnailData =
                                          courseData['thumbnail'] ?? {};
                                      final videoData =
                                          courseData['promotional_video'] ?? {};

                                      final double progress =
                                          ((course['progress'] as num?)
                                                      ?.toDouble() ??
                                                  0) /
                                              100;

                                      return CourseTakingCard(
                                        courseId: courseData['id'] ?? 0,
                                        title: courseData['title'] ?? '',
                                        instructor:
                                            instructorData['name'] ?? '',
                                        instructorImage:
                                            instructorData['image'] ?? '',
                                        category: courseData['category'] ?? '',
                                        videoUrl: videoData['url'] ?? '',
                                        imageUrl: thumbnailData['url'] ?? '',
                                        isFavorite:
                                            course['is_favorite'] ?? false,
                                        onFavouriteToggle: (isFavorite) async {
                                          await toggleFavouriteCourse(
                                              courseData['id'], !isFavorite);
                                          setState(() {
                                            courseData['is_favorite'] =
                                                !isFavorite;
                                          });
                                        },
                                        progress: progress,
                                        onPressed: () async {
                                          final updatedProgress =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CourseTakingDetailScreen(
                                                      slug: slug),
                                            ),
                                          );

                                          if (updatedProgress != null &&
                                              updatedProgress is double) {
                                            setState(() {
                                              course['progress'] =
                                                  updatedProgress * 100;
                                            });
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              if (courses.isEmpty && !isLoading)
                                Positioned.fill(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        AppImages.coursesEmpty,
                                        width: 100,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        '${(Localization.translate('empty_courses') ?? '').trim() != 'empty_courses' && (Localization.translate('empty_courses') ?? '').trim().isNotEmpty ? Localization.translate('empty_courses') : 'No Courses Found'}',
                                        style: TextStyle(
                                          color: AppColors.blackColor,
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        '${(Localization.translate('unavailable_course') ?? '').trim() != 'unavailable_course' && (Localization.translate('unavailable_course') ?? '').trim().isNotEmpty ? Localization.translate('unavailable_course') : 'No courses available at the moment.'}',
                                        style: TextStyle(
                                          color: AppColors.greyColor(context)
                                              .withOpacity(0.7),
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: AppFontFamily.mediumFont,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (courses.isEmpty && !isLoading)
                                ListView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  children: [SizedBox(height: 1)],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}
