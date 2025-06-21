
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_dropdown.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/provider/settings_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/bookings/bookings.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/components/skeleton/tutor_card_skeleton.dart';
import 'package:flutter_projects/view/components/tutor_card.dart';
import 'package:flutter_projects/view/detailPage/detail_screen.dart';
import 'package:flutter_projects/view/profile/profile_screen.dart';
import 'package:flutter_projects/view/tutor/component/filter_turtor_bottom_sheet.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../provider/auth_provider.dart';

class SearchTutorsScreen extends StatefulWidget {
  @override
  State<SearchTutorsScreen> createState() => _SearchTutorsScreenState();
}

class _SearchTutorsScreenState extends State<SearchTutorsScreen> {
  List<Map<String, dynamic>> tutors = [];
  int currentPage = 1;
  int totalPages = 1;
  int totalTutors = 0;
  bool isLoading = false;
  bool isInitialLoading = false;
  bool isRefreshing = false;

  late double screenWidth;
  late double screenHeight;
  List<String> selectedLanguages = [];
  List<String> selectedSubjects = [];
  List<String> subjectGroups = [];
  String? selectedSubjectGroup;

  List<String> subjects = [];

  List<String> languages = [];

  List<Map<String, dynamic>> countries = [];
  int? selectedCountryId;
  String? selectedCountryName;

  int selectedIndex = 0;
  late PageController _pageController;
  String profileImageUrl = '';

  String? _selectedSorting;
  String? sortingValue;
  String? sortBy;

  String? keyword;
  double? maxPrice;
  int? selectedGroupId;
  String? sessionType = 'group';
  List<int>? selectedSubjectIds;
  List<int>? selectedLanguageIds;

  final List<String> sortingOptions = [
    '${Localization.translate("new_listing")}',
    '${Localization.translate("old_listing")}',
    '${Localization.translate("asc_listing")}',
    '${Localization.translate("desc_listing")}',
  ];

  final Map<String, String> sortingMap = {
    '${Localization.translate("new_listing")}': 'newest',
    '${Localization.translate("old_listing")}': 'oldest',
    '${Localization.translate("asc_listing")}': 'asc',
    '${Localization.translate("desc_listing")}': 'desc',
  };

  void _onSortSelected(String value) {
    setState(() {
      _selectedSorting = value;
      sortBy = sortingMap[value];
    });
    fetchInitialTutors(sortBy: sortBy);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fetchInitialTutors();
    fetchSubjects();
    fetchLanguages();
    fetchSubjectGroups();
    fetchCountries();
    _pageController = PageController(initialPage: selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    profileImageUrl = userData?['user']?['profile']?['image'] ?? '';
    precacheImage(NetworkImage(profileImageUrl), context);
  }

  Future<void> fetchSubjects() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getSubjects(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          subjects = (response['data'] as List<dynamic>)
              .map((subject) => subject['name'].toString())
              .toList();
        });
      }
    } catch (error) {}
  }

  Future<void> fetchCountries() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getCountries(token);
      final countriesData = response['data'];

      setState(() {
        countries = countriesData.map<Map<String, dynamic>>((country) {
          return {
            'id': country['id'],
            'name': country['name'],
          };
        }).toList();
      });
    } catch (e) {}
  }

  Future<void> fetchLanguages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getLanguages(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          languages = (response['data'] as List<dynamic>)
              .map((language) => language['name'].toString())
              .toList();
        });
      }
    } catch (error) {}
  }

  Future<void> fetchSubjectGroups() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getSubjectsGroup(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          subjectGroups = (response['data'] as List<dynamic>)
              .map((group) => group['name'].toString())
              .toList();
        });
      }
    } catch (error) {}
  }

  bool get isAuthenticated {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.token != null;
  }

  Future<void> fetchInitialTutors({
    String? sortBy,
    String? keyword,
    double? maxPrice,
    int? country,
    int? groupId,
    String? sessionType,
    List<int>? subjectIds,
    List<int>? languageIds,
    bool isRefresh = false,
  }) async {
    if (!isRefresh) {
      setState(() {
        isInitialLoading = true;
      });
      print('Fetching tutors with filters:');
      print('Sort By: $sortBy');
      print('Keyword: $keyword');
      print('Max Price: $maxPrice');
      print('Country ID: $country');
      print('Group ID: $groupId');
      print('Subject IDs: $subjectIds');
      print('Session Type: $sessionType');
      print('Language IDs: $languageIds');
    } else {
      setState(() {
        isRefreshing = false;
      });
    }

    try {
      final response = await findTutors(
        page: currentPage,
        perPage: 5,
        sortBy: sortBy,
        keyword: keyword,
        maxPrice: maxPrice,
        country: country,
        groupId: groupId,
        sessionType: sessionType,
        subjectIds: subjectIds,
        languageIds: languageIds,
      );
      print('Response: $response');

      if (response.containsKey('data') && response['data']['list'] is List) {
        setState(() {
          tutors = (response['data']['list'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          currentPage = response['data']['pagination']['currentPage'];
          totalPages = response['data']['pagination']['totalPages'];
          totalTutors = response['data']['pagination']['total'];
        });
        print('Tutors List Updated: $tutors');
      }
    } catch (e) {
      print('Error fetching tutors: $e');
    } finally {
      setState(() {
        isInitialLoading = false;
        isRefreshing = false;
      });
    }
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 5.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> toggleFavouriteTutor(int tutorId, bool isFavorite) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;


      final response =
          await addDeleteFavouriteTutors(token!, tutorId, authProvider);
      if (response['status'] == 200) {
        if (isFavorite) {
          showCustomToast(context,"Tutor removed from favourites", true);
        } else {
          showCustomToast(context, "Tutor added to favorites", true);
        }
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

  Future<void> _onRefresh() async {
    setState(() {
      currentPage = 1;
    });

    await fetchInitialTutors(isRefresh: true);
  }

  Future<void> loadMoreTutors() async {
    if (currentPage < totalPages && !isLoading) {
      setState(() {
        isLoading = true;
      });

      try {
        final response = await findTutors(page: currentPage + 1, perPage: 5);

        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            tutors.addAll((response['data']['list'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList());
            currentPage = response['data']['pagination']['currentPage'];
            totalPages = response['data']['pagination']['totalPages'];
            totalTutors = response['data']['pagination']['total'];
          });
        }

        if (response['status'] == 401) {
          showCustomToast(context,
              '${Localization.translate("unauthorized_access")}', false);
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
        }
      } catch (e) {
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userData = authProvider.userData;

    if ((token == null || userData == null) && index != 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: Localization.translate("login_required"),
            content: Localization.translate("login_access"),
            buttonText: Localization.translate("goToLogin"),
            buttonAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          );
        },
      );
      return;
    }

    setState(() {
      selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void openFilterBottomSheet() async {
    if (subjects.isEmpty) await fetchSubjects();
    if (languages.isEmpty) await fetchLanguages();
    if (countries.isEmpty) await fetchCountries();
    if (subjectGroups.isEmpty) await fetchSubjectGroups();

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        subjects: subjects,
        languages: languages,
        location: countries,
        subjectGroups: subjectGroups,
        selectedSubjectGroup: selectedSubjectGroup,
        selectedCountryId: selectedCountryId,
        keyword: keyword,
        maxPrice: maxPrice,
        sessionType: null,
        subjectIds: selectedSubjectIds,
        languageIds: selectedLanguageIds,
        onCountrySelected: (int countryId) {
          setState(() {
            selectedCountryId = countryId;
          });
        },
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
          String? sessionType,
          List<int>? subjectIds,
          List<int>? languageIds,
        }) {

          setState(() {
            this.keyword = keyword;
            this.maxPrice = maxPrice;
            this.selectedCountryId = country;
            this.selectedSubjectGroup =
                groupId != null ? subjectGroups[groupId - 1] : null;
            this.sessionType = sessionType;
            this.selectedSubjectIds = subjectIds;
            this.selectedLanguageIds = languageIds;
            debugPrint('Filters Applied:');
            debugPrint('Keyword: $keyword');
            debugPrint('Max Price: $maxPrice');
            debugPrint('Country ID: $country');
            debugPrint('Group ID: $groupId');
            debugPrint('Session Type: $sessionType');
            debugPrint('Subject IDs: $subjectIds');
            debugPrint('Language IDs: $languageIds');
          });

          fetchInitialTutors(
            keyword: keyword,
            maxPrice: maxPrice,
            country: country,
            groupId: groupId,
            sessionType: sessionType,
            subjectIds: subjectIds,
            languageIds: languageIds,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    final authProvider = Provider.of<AuthProvider>(context);
    final token = authProvider.token;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final tutorName =
        settingsProvider.getSetting('data')?['_lernen']?['tutor_display_name'];

    Widget buildProfileIcon() {
      final isSelected = selectedIndex == 2;
      return Container(
        padding: EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.greyColor(context) : Colors.transparent,
            width: isSelected ? 2.0 : 0.0,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: token == null || profileImageUrl.isEmpty
            ? SvgPicture.asset(
          AppImages.userIcon,
          width: 20,
          height: 20,
          color: AppColors.greyColor(context),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Stack(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 25,
                  height: 25,
                  color: Colors.white,
                ),
              ),
              Image.network(
                profileImageUrl,
                width: 25,
                height: 25,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 25,
                      height: 25,
                      color: AppColors.whiteColor,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SvgPicture.asset(
                    AppImages.userIcon,
                    width: 20,
                    height: 20,
                    color: AppColors.greyColor(context),
                  );
                },
              ),
            ],
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
          body: Column(
            children: [
              if (selectedIndex == 0)
                Column(
                  children: [
                    Container(
                      color: AppColors.whiteColor,
                      padding: EdgeInsets.only(left: Localization.textDirection == TextDirection.rtl ? 10 : 20,
                          right: Localization.textDirection == TextDirection.rtl ? 20 : 10),
                      child: AppBar(
                        backgroundColor: AppColors.whiteColor,
                        automaticallyImplyLeading: false,
                        elevation: 0,
                        titleSpacing: 0,
                        centerTitle: false,
                        title: Text(
                          tutorName ?? '',
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: FontSize.scale(context, 20),
                            fontFamily: AppFontFamily.font,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        actions: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: SvgPicture.asset(
                                AppImages.filterIcon,
                                color: AppColors.greyColor(context),
                                width: 20,
                                height: 20,
                              ),
                              onPressed: () {
                                openFilterBottomSheet();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(vertical: 10.0),
                    //   child: _gradeSelector(),
                    // ),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                          '${tutors.length} ${Localization.translate('tutors')}',
                          style: TextStyle(
                            fontFamily: AppFontFamily.font,
                            fontWeight: FontWeight.w500,
                            fontSize: FontSize.scale(context, 16),
                            fontStyle: FontStyle.normal,
                            color: AppColors.orangeColor,
                          ),
                    )
                    ),
                  ],
                ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragUpdate: (_) {},
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      isInitialLoading
                          ? ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 2.0),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: TutorCardSkeleton(isFullWidth: true),
                                );
                              },
                            )
                          : tutors.isEmpty
                              ? Center(
                                  child: Text(
                                    Localization.translate("no_tutors"),
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 18),
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.greyColor(context),
                                      fontFamily: AppFontFamily.font,
                                    ),
                                  ),
                                )
                              : NotificationListener<ScrollNotification>(
                                  onNotification:
                                      (ScrollNotification scrollInfo) {
                                    if (scrollInfo.metrics.pixels ==
                                        scrollInfo.metrics.maxScrollExtent) {
                                      loadMoreTutors();
                                    }
                                    return true;
                                  },
                                  child: RefreshIndicator(
                                    onRefresh: _onRefresh,
                                    color: AppColors.primaryGreen(context),
                                    child: ListView.builder(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 2.0),
                                      itemCount:
                                          tutors.length + (isLoading ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index == tutors.length) {
                                          return Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(10.0),
                                              child: SpinKitCircle(
                                                color: AppColors.primaryGreen(context),
                                              ),
                                            ),
                                          );
                                        }

                                        final tutor = tutors[index];
                                        final profile = tutor['profile'] ?? {};
                                        final country = tutor['country'] ?? {};
                                        final languages =
                                            tutor['languages'] ?? [];
                                        final subjects = tutor['subjects'] ?? [];
                                        String formatTutorName(String fullName) {
                                          final parts = fullName.split(' ');
                                          if (parts.length < 2) return fullName;

                                          final lastName = parts.last;
                                          if (lastName.length <= 4) {
                                            return fullName;
                                          } else {
                                            return '${parts.first} ${lastName[0]}.';
                                          }
                                        }

                                        final formattedName = formatTutorName(
                                            profile['full_name'] ??
                                                'Unknown Tutor');
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              if (profile != null &&
                                                  profile
                                                      is Map<String, dynamic>) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TutorDetailScreen(
                                                            profile: profile),
                                                  ),
                                                );
                                              }
                                            },
                                            child: TutorCard(
                                              tutorId: tutor['id'] ?? '',
                                              name: formattedName,
                                              price: tutor['min_price'] != null
                                                  ? '${tutor['min_price']}'
                                                  : 'N/A',
                                              filledStar: (tutor['avg_rating'] !=
                                                      null &&
                                                  (tutor['avg_rating'] is String
                                                      ? double.tryParse(tutor[
                                                              'avg_rating']) ==
                                                          5.0
                                                      : tutor['avg_rating']
                                                              .toDouble() ==
                                                          5.0)),
                                              description: subjects.isNotEmpty
                                                  ? subjects
                                                      .map((subject) =>
                                                          subject['name'])
                                                      .join(', ')
                                                  : '${Localization.translate("subjects_empty")}',
                                              rating: tutor['avg_rating'] != null
                                                  ? (tutor['avg_rating'] is String
                                                      ? double.tryParse(tutor[
                                                              'avg_rating']) ??
                                                          0.0
                                                      : tutor['avg_rating']
                                                          .toDouble())
                                                  : 0.0,
                                              reviews:
                                                  '${tutor['total_reviews'] ?? 0}',
                                              activeStudents:
                                                  '${tutor['active_students'] ?? 0}',
                                              sessions:
                                                  '${tutor['sessions'] ?? 'N/A'}',
                                              languages: languages.isNotEmpty
                                                  ? languages
                                                      .map((lang) => lang['name'])
                                                      .join(', ')
                                                  : 'No languages available',
                                              image: profile['image'] ??
                                                  AppImages.placeHolderImage,
                                              countryFlag: country[
                                                          'short_code'] !=
                                                      null
                                                  ? '${AppUrls.flagUrl}${country['short_code'].toLowerCase()}.png'
                                                  : '',
                                              verificationIcon:
                                                  profile['verified_at'] != null
                                                      ? AppImages.active
                                                      : '',
                                              onlineIndicator:
                                                  tutor['is_online'] == true
                                                      ? AppImages.onlineIndicator
                                                      : '',
                                              isFullWidth: true,
                                              languagesText: true,
                                              isFavorite: tutor['is_favorite'] ?? false,
                                              deleteIcon: false,
                                              onDelete: () {},
                                              onFavouriteToggle: (isFavorite) async {
                                                await toggleFavouriteTutor(tutor['id'], isFavorite);
                                                setState(() {
                                                  tutor['is_favorite'] = !isFavorite;
                                                });
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                      BookingScreen(
                        onBackPressed: () {
                          _pageController.jumpToPage(0);
                        },
                      ),
                      ProfileScreen(),
                    ],
                  ),
                ),
              )
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: _onItemTapped,
            unselectedItemColor: AppColors.greyColor(context),
            selectedItemColor: AppColors.greyColor(context),
            selectedLabelStyle: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 12),
                fontFamily: AppFontFamily.font,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: selectedIndex == 0
                    ? SvgPicture.asset(AppImages.searchBottomFilled,
                        width: 20, height: 20)
                    : SvgPicture.asset(AppImages.search, width: 20, height: 20),
                label: Localization.translate('search'),
              ),
              BottomNavigationBarItem(
                icon: selectedIndex == 1
                    ? SvgPicture.asset(AppImages.calenderIcon,
                        width: 20, height: 20)
                    : SvgPicture.asset(AppImages.bookingIcon,
                        color: AppColors.greyColor(context), width: 20, height: 20),
                label: Localization.translate('booking'),
              ),
              BottomNavigationBarItem(
                icon: buildProfileIcon(),
                label: Localization.translate('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get wantKeepAlive => true;

  Widget _gradeSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: Localization.textDirection == TextDirection.ltr
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Padding(
          padding: Localization.textDirection == TextDirection.ltr
              ? const EdgeInsets.only(left: 20.0, right: 10)
              : const EdgeInsets.only(right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: Localization.textDirection,
            children: [
              Text(
                '${tutors.length} ${Localization.translate('tutors')}',
                style: TextStyle(
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w500,
                  fontSize: FontSize.scale(context, 16),
                  fontStyle: FontStyle.normal,
                  color: AppColors.orangeColor,
                ),
                textAlign: Localization.textDirection == TextDirection.ltr
                    ? TextAlign.start
                    : TextAlign.end,
              ),
              // CustomDropdown(
              //   hint: Localization.translate('choose_sorting'),
              //   selectedValue: _selectedSorting,
              //   items: sortingOptions,
              //   onSelected: _onSortSelected,
              // ),
            ],
          ),
        ),
      ],
    );
  }



}
