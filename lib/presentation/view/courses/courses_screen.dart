import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/courses/component/course_card.dart';
import 'package:flutter_projects/presentation/view/courses/detail/course_details.dart';
import 'package:flutter_projects/presentation/view/courses/skeleton/course_card_skeleton.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../base_components/textfield.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/connectivity_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../auth/login_screen.dart';
import '../community/component/bouncer.dart';
import '../components/internet_alert.dart';
import '../components/login_required_alert.dart';
import 'component/courses_bottom_sheet.dart';

class CoursesScreen extends StatefulWidget {
  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();
    fetchCourses();
    fetchCategories();
    fetchLanguages();
    fetchLevels();
    fetchSubjectGroups();
    fetchRatings();
    selectedLevel = null;
  }

  String paymentEnabled = "no";
  bool isLoading = false;
  int currentPage = 1;
  int page = 1;
  int totalPages = 1;
  int totalCourses = 0;
  List<Map<String, dynamic>> courses = [];

  bool isLoadingMore = false;

  List<String> selectedLanguages = [];
  List<String> selectedSubjects = [];
  List<String> subjectGroups = [];
  String? selectedSubjectGroup;

  List<String> categories = [];

  List<String> languages = [];

  late List<String> levels;
  String? selectedLevel;
  String? selectedPriceType;

  double? maxPrice;
  int? selectedGroupId;
  List<int>? selectedSubjectIds;
  List<int>? selectedLanguageIds;
  Map<String, dynamic> ratings = {};
  bool isRefreshing = false;

  TextEditingController _searchController = TextEditingController();
  final _bounce = Bouncer(milliseconds: 500);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> fetchRatings() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getRatings(token);

      if (response.containsKey('data')) {
        setState(() {
          ratings = response['data'];
        });
      }
    } catch (error) {}
  }

  Future<void> fetchSubjectGroups() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getDurationCounts(token);

      if (response.containsKey('data') &&
          response['data'] is Map<String, dynamic>) {
        setState(() {
          subjectGroups =
              (response['data'] as Map<String, dynamic>).keys
                  .map((key) => "$key Hour")
                  .toList();
        });
      }
    } catch (error) {}
  }

  Future<void> fetchLevels() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getLevel(token);

      if (response.containsKey('data')) {
        setState(() {
          levels =
              response['data'].values.map<String>((level) {
                String name = level['name'].toString();
                return name[0].toUpperCase() + name.substring(1).toLowerCase();
              }).toList();
        });
      }
    } catch (error) {}
  }

  Future<void> fetchCategories() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getCategories(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          categories =
              (response['data'] as List<dynamic>)
                  .map((category) => category['name'].toString())
                  .toList();
        });
      }
    } catch (error) {}
  }

  Future<void> fetchLanguages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getLanguages(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          languages =
              (response['data'] as List<dynamic>)
                  .map((language) => language['name'].toString())
                  .toList();
        });
      }
    } catch (error) {}
  }

  Future<void> fetchCourses({
    bool isLoadMore = false,
    bool isPrevious = false,
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? pricingType,
    List<String>? duration,
    List<int>? categoryIds,
    List<int>? languageIds,
    List<int>? avgRatings,
    List<String>? level,
    int? selectedPriceIndex,
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

      String? finalPricingType;
      if (selectedPriceIndex == 0) {
        finalPricingType = "paid";
      } else if (selectedPriceIndex == 1) {
        finalPricingType = "all";
      }

      List<int>? filteredRatings =
          (avgRatings != null && avgRatings.isNotEmpty) ? avgRatings : null;

      List<String>? filteredDuration =
          (duration != null && duration.isNotEmpty) ? duration : null;

      final response = await getAllCourses(
        token,
        page: currentPage,
        keyword: keyword,
        sort: "asc",
        categoryIds: categoryIds,
        languageIds: languageIds,
        minPrice: minPrice?.toString(),
        maxPrice: maxPrice?.toString(),
        pricingType: finalPricingType,
        duration: filteredDuration,
        avgRatings: filteredRatings,
        level: level,
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

  Future<void> toggleFavouriteCourse(int courseId, bool isFavorite) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await addDeleteFavouriteCourse(
        token!,
        courseId,
        authProvider,
      );
      if (response['status'] == 200) {
        if (isFavorite) {
        } else {}
      } else if (response['status'] == 403) {
        showCustomToast(context, response['message'], false);
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

  void openFilterBottomSheet() async {
    if (categories.isEmpty) await fetchCategories();
    if (languages.isEmpty) await fetchLanguages();
    if (levels.isEmpty) await fetchLevels();
    if (ratings.isEmpty) await fetchRatings();

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      builder:
          (context) => CoursesBottomSheet(
            categories: categories,
            languages: languages,
            subjectGroups: subjectGroups,
            levels: levels,
            ratings: ratings,
            selectedSubjectGroup: selectedSubjectGroup,
            maxPrice: maxPrice,
            subjectIds: selectedSubjectIds,
            languageIds: selectedLanguageIds,
            onSubjectGroupSelected: (String? selectedGroup) {
              setState(() {
                selectedSubjectGroup = selectedGroup;
              });
            },
            onApplyFilters: ({
              String? keyword,
              double? maxPrice,
              int? country,
              int? groupId,
              String? levelType,
              List<int>? subjectIds,
              List<int>? languageIds,
              String? rating,
              String? priceType,
              int? selectedPriceIndex,
            }) {
              List<int>? avgRatings;
              if (rating != null) {
                try {
                  avgRatings = [double.parse(rating).toInt()];
                } catch (e) {}
              }

              fetchCourses(
                keyword: keyword,
                maxPrice: maxPrice,
                pricingType: priceType,
                duration:
                    groupId != null
                        ? [subjectGroups[groupId - 1].replaceAll(" Hour", "")]
                        : null,
                categoryIds: subjectIds,
                languageIds: languageIds,
                avgRatings: avgRatings,
                level: levelType != null ? [levelType.toLowerCase()] : [],
                selectedPriceIndex: selectedPriceIndex,
              );
            },
          ),
    );
  }

  Future<void> refreshCourses() async {
    try {
      setState(() {
        isRefreshing = true;
        currentPage = 1;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getAllCourses(token, page: 1, sort: "asc");

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            courses = List<Map<String, dynamic>>.from(response['data']['list']);
            totalPages = response['data']['pagination']['totalPages'];
            totalCourses = response['data']['pagination']['total'];
            currentPage++;
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
    } catch (e) {
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  Future<void> fetchSearchCourses({String title = ''}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getAllCourses(token, sort: 'asc', keyword: title);

      if (response['status'] == 200) {
        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            courses = List<Map<String, dynamic>>.from(response['data']['list']);
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

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'];

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
                            '${(Localization.translate('all_courses') ?? '').trim() != 'all_courses' && (Localization.translate('all_courses') ?? '').trim().isNotEmpty ? Localization.translate('all_courses') : 'All Courses'}',
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
                                  text: "${totalCourses}",
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
                                      '${(Localization.translate("courses_available")).trim().isNotEmpty ? (totalCourses <= 1 ? Localization.translate("courses_available")?.replaceAll("Courses", "Course") : Localization.translate("courses_available")) : (totalCourses <= 1 ? "Course available" : "Courses available")}',
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
                                  width:
                                      MediaQuery.of(context).size.width - 100,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 50,
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
                                  child: CourseCardSkeleton(),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                      : Column(
                        children: [
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width - 100,
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
                                      fetchSearchCourses(title: searchQuery);
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 15),
                              GestureDetector(
                                onTap: () {
                                  openFilterBottomSheet();
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: SvgPicture.asset(
                                      AppImages.filterIcon,
                                      width: 18,
                                      height: 18,
                                      color: AppColors.whiteColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: _gradeSelector(),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: refreshCourses,
                              color: AppColors.primaryGreen(context),
                              child: Stack(
                                children: [
                                  if (courses.isNotEmpty || isLoading)
                                    NotificationListener<ScrollNotification>(
                                      onNotification: (
                                        ScrollNotification scrollInfo,
                                      ) {
                                        if (scrollInfo.metrics.pixels ==
                                                scrollInfo
                                                    .metrics
                                                    .maxScrollExtent &&
                                            !isLoadingMore &&
                                            courses.isNotEmpty) {
                                          fetchCourses(isLoadMore: true);
                                        }
                                        return false;
                                      },
                                      child: ListView.builder(
                                        itemCount:
                                            isLoadingMore
                                                ? courses.length + 1
                                                : courses.length,
                                        itemBuilder: (context, index) {
                                          if (index == courses.length) {
                                            return Center(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  right: 10.0,
                                                  left: 10,
                                                  top: 10,
                                                  bottom: 30,
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

                                          final course = courses[index];

                                          String capitalizedLevel =
                                              (course.isNotEmpty &&
                                                      course.containsKey(
                                                        'level',
                                                      ) &&
                                                      course['level'] != null)
                                                  ? course['level'][0]
                                                          .toUpperCase() +
                                                      course['level']
                                                          .substring(1)
                                                          .toLowerCase()
                                                  : '';

                                          String slug = course['slug'] ?? '';
                                          int id = course['id'];
                                          String formatDuration(
                                            String duration,
                                          ) {
                                            return duration
                                                .replaceAll(' mins', 'm')
                                                .replaceAll(' minutes', 'm')
                                                .replaceAll(' minute', 'm')
                                                .replaceAll(' min', 'm')
                                                .replaceAll(' sec', 's')
                                                .replaceAll(' seconds', 's')
                                                .replaceAll(' hours', 'h')
                                                .replaceAll(' hour', 'h');
                                          }

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          CourseDetailScreen(
                                                            slug: slug,
                                                            id: id,
                                                          ),
                                                ),
                                              );
                                            },
                                            child: CourseCard(
                                              courseId: course['id'] ?? '',
                                              title: course['title'] ?? '',
                                              instructor:
                                                  course['instructor']['name'] ??
                                                  '',
                                              instructorImage:
                                                  course['instructor']['image'] ??
                                                  '',
                                              category: List<String>.from(
                                                course['tags'] ?? [],
                                              ),
                                              price:
                                                  (paymentEnabled == "yes" &&
                                                          course['pricing'] !=
                                                              null)
                                                      ? course['pricing']['final_price']
                                                              ?.toString() ??
                                                          ''
                                                      : '',
                                              filledStar:
                                                  (course['ratings_avg_rating'] !=
                                                          null &&
                                                      (course['ratings_avg_rating']
                                                              is String
                                                          ? double.tryParse(
                                                                course['ratings_avg_rating'],
                                                              ) ==
                                                              5.0
                                                          : course['ratings_avg_rating']
                                                                  .toDouble() ==
                                                              5.0)),
                                              rating:
                                                  course['ratings_avg_rating'] !=
                                                          null
                                                      ? double.tryParse(
                                                            course['ratings_avg_rating']
                                                                .toString(),
                                                          ) ??
                                                          0.0
                                                      : 0.0,
                                              reviews:
                                                  course['views_count']
                                                      .toString() ??
                                                  '',
                                              lessons:
                                                  course['curriculums_count'] ??
                                                  '',
                                              discount:
                                                  (paymentEnabled == "yes" &&
                                                          course['pricing'] !=
                                                              null)
                                                      ? course['pricing']['discount']
                                                              ?.toString() ??
                                                          '0'
                                                      : '',
                                              duration: formatDuration(
                                                course['content_length'] ?? '',
                                              ),
                                              imageUrl:
                                                  course['thumbnail']?['url'] ??
                                                  '',
                                              videoUrl:
                                                  course['promotional_video']?['url'] ??
                                                  '',
                                              level: capitalizedLevel ?? '',
                                              language:
                                                  course['language'] != null
                                                      ? course['language']['name']
                                                      : '',
                                              isFavorite:
                                                  course['is_favorite'] ??
                                                  false,
                                              onFavouriteToggle: (
                                                isFavorite,
                                              ) async {
                                                await toggleFavouriteCourse(
                                                  course['id'],
                                                  !isFavorite,
                                                );
                                                setState(() {
                                                  course['is_favorite'] =
                                                      !isFavorite;
                                                });
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  if (courses.isEmpty && !isLoading)
                                    Positioned.fill(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            '${(Localization.translate('unavailable_course') ?? '').trim() != 'unavailable_course' && (Localization.translate('unavailable_course') ?? '').trim().isNotEmpty ? Localization.translate('unavailable_course') : 'No courses available at the moment.'}',
                                            style: TextStyle(
                                              color: AppColors.greyColor(
                                                context,
                                              ).withOpacity(0.7),
                                              fontSize: FontSize.scale(
                                                context,
                                                14,
                                              ),
                                              fontFamily:
                                                  AppFontFamily.mediumFont,
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
      },
    );
  }

  bool get wantKeepAlive => true;

  Widget _gradeSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment:
          Localization.textDirection == TextDirection.ltr
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
      children: [
        Padding(
          padding:
              Localization.textDirection == TextDirection.ltr
                  ? const EdgeInsets.only(left: 20.0, right: 10)
                  : const EdgeInsets.only(right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: Localization.textDirection,
            children: [
              Text(
                '${courses.length} ${(Localization.translate('courses') ?? '').trim() != 'courses' && (Localization.translate('courses') ?? '').trim().isNotEmpty ? Localization.translate('courses') : 'Courses'}',
                style: TextStyle(
                  fontFamily: AppFontFamily.mediumFont,
                  fontWeight: FontWeight.w500,
                  fontSize: FontSize.scale(context, 14),
                  fontStyle: FontStyle.normal,
                  color: AppColors.greyColor(context),
                ),
                textAlign:
                    Localization.textDirection == TextDirection.ltr
                        ? TextAlign.start
                        : TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
