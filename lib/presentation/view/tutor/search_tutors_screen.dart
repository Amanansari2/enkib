import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_dropdown.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/presentation/view/tutor/component/filter_turtor_bottom_sheet.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import '../auth/login_screen.dart';
import '../bookings/bookings.dart';
import '../community/community_screen.dart';
import '../components/login_required_alert.dart';
import '../components/skeleton/tutor_card_skeleton.dart';
import '../components/tutor_card.dart';
import '../detailPage/detail_screen.dart';
import '../profile/guest_profile_screen.dart';
import '../profile/profile_screen.dart';

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
  String paymentEnabled = "no";

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

  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

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
          subjects =
              (response['data'] as List<dynamic>)
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
        countries =
            countriesData.map<Map<String, dynamic>>((country) {
              return {'id': country['id'], 'name': country['name']};
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
          languages =
              (response['data'] as List<dynamic>)
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
          subjectGroups =
              (response['data'] as List<dynamic>)
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

      if (response.containsKey('data') && response['data']['list'] is List) {
        setState(() {
          tutors =
              (response['data']['list'] as List)
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
          currentPage = response['data']['pagination']['currentPage'];
          totalPages = response['data']['pagination']['totalPages'];
          totalTutors = response['data']['pagination']['total'];
        });
      }
    } catch (e) {
    } finally {
      setState(() {
        isInitialLoading = false;
        isRefreshing = false;
      });
    }
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 5.0,
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

  Future<void> toggleFavouriteTutor(int tutorId, bool isFavorite) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await addDeleteFavouriteTutors(
        token!,
        tutorId,
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
            tutors.addAll(
              (response['data']['list'] as List)
                  .map((item) => item as Map<String, dynamic>)
                  .toList(),
            );
            currentPage = response['data']['pagination']['currentPage'];
            totalPages = response['data']['pagination']['totalPages'];
            totalTutors = response['data']['pagination']['total'];
          });
        }

        if (response['status'] == 401) {
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

  Future<void> sendEmail() async {
    final String email = Constants.email;
    final String subject = Uri.encodeComponent('');
    final String body = Uri.encodeComponent('');

    final Uri emailUri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      if (!kIsWeb && Platform.isIOS) {
      } else {}
    }
  }

  Future<void> openWhatsApp() async {
    String contact = Constants.phoneNUmber;
    String text = Uri.encodeComponent("");

    final String iosUrl = "https://wa.me/$contact?text=$text";
    final String androidUrl = "whatsapp://send?phone=$contact&text=$text";

    try {
      final Uri url =
          Platform.isIOS ? Uri.parse(iosUrl) : Uri.parse(androidUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw "";
      }
    } catch (e) {
      final fallbackUrl = Uri.parse(
        "https://api.whatsapp.com/send?phone=$contact&text=$text",
      );
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
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
      builder:
          (context) => FilterBottomSheet(
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

    final communityAddon =
        settingsProvider.getSetting('data')?['installed_addons'];

    final isCommunityEnabled =
        (communityAddon != null && communityAddon['ForumWise'] == true)
            ? true
            : false;

    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'] ??
        '';

    void _onItemTapped(int index) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userData = authProvider.userData;

      final isProfileTab = index == (isCommunityEnabled ? 3 : 2);

      if (!isProfileTab && (token == null || userData == null) && index != 0) {
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

    Widget buildProfileIcon() {
      final isSelected = selectedIndex == (isCommunityEnabled ? 3 : 2);
      return Container(
        padding: EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? AppColors.greyColor(context) : Colors.transparent,
            width: isSelected ? 2.0 : 0.0,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child:
            token == null || profileImageUrl.isEmpty
                ? SvgPicture.asset(
                  AppImages.userIcon,
                  width: 25,
                  height: 25,
                  color: AppColors.greyColor(context),
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.network(
                    profileImageUrl,
                    width: 25,
                    height: 25,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return SvgPicture.asset(
                        AppImages.userIcon,
                        width: 25,
                        height: 25,
                        color: AppColors.greyColor(context),
                      );
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
          floatingActionButton:
              selectedIndex == 0
                  ? Stack(
                    children: [
                      Positioned(
                        bottom: 25,
                        right: 10,
                        child: FloatingActionButton(
                          onPressed: _toggleExpand,
                          backgroundColor:
                              _isExpanded
                                  ? AppColors.whiteColor
                                  : AppColors.primaryGreen(context),
                          child: Icon(
                            _isExpanded ? Icons.close : Icons.add,
                            color:
                                _isExpanded
                                    ? AppColors.primaryGreen(context)
                                    : AppColors.whiteColor,
                            size: 25,
                          ),
                        ),
                      ),

                      if (_isExpanded)
                        Positioned(
                          bottom: 90,
                          right: 10,
                          child: GestureDetector(
                            onTap: openWhatsApp,
                            child: FloatingActionButton(
                              onPressed: openWhatsApp,
                              backgroundColor: AppColors.primaryGreen(context),
                              child: FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: AppColors.whiteColor,
                                size: 25,
                              ),
                            ),
                          ),
                        ),

                      if (_isExpanded)
                        Positioned(
                          bottom: 160,
                          right: 10,
                          child: GestureDetector(
                            onTap: sendEmail,
                            child: FloatingActionButton(
                              onPressed: sendEmail,
                              backgroundColor: AppColors.primaryGreen(context),
                              child: SvgPicture.asset(
                                AppImages.emailIcon,
                                width: 25,
                                height: 25,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                  : Container(),
          body: Column(
            children: [
              if (selectedIndex == 0)
                Column(
                  children: [
                    Container(
                      color: AppColors.whiteColor,
                      padding: EdgeInsets.only(
                        left:
                            Localization.textDirection == TextDirection.rtl
                                ? 10
                                : 20,
                        right:
                            Localization.textDirection == TextDirection.rtl
                                ? 20
                                : 10,
                      ),
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
                            fontFamily: AppFontFamily.mediumFont,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: _gradeSelector(),
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
                              ),
                            ),
                          )
                          : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
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
                                padding: EdgeInsets.symmetric(vertical: 2.0),
                                itemCount: tutors.length + (isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == tutors.length) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryGreen(
                                            context,
                                          ),
                                          strokeWidth: 2.0,
                                        ),
                                      ),
                                    );
                                  }

                                  final tutor = tutors[index];
                                  final profile = tutor['profile'] ?? {};
                                  final country = tutor['country'] ?? {};
                                  final languages = tutor['languages'] ?? [];
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
                                    profile['full_name'] ?? '',
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (profile != null &&
                                            profile is Map<String, dynamic>) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      TutorDetailScreen(
                                                        profile: profile,
                                                      ),
                                            ),
                                          );
                                        }
                                      },
                                      child: TutorCard(
                                        tutorId: tutor['id'] ?? '',
                                        name: formattedName ?? '',
                                        price:
                                            (paymentEnabled == "yes" &&
                                                    tutor['min_price'] != null)
                                                ? '${tutor['min_price']}'
                                                : '',
                                        filledStar:
                                            (tutor['avg_rating'] != null &&
                                                (tutor['avg_rating'] is String
                                                    ? double.tryParse(
                                                          tutor['avg_rating'],
                                                        ) ==
                                                        5.0
                                                    : tutor['avg_rating']
                                                            .toDouble() ==
                                                        5.0)),
                                        description:
                                            subjects.isNotEmpty
                                                ? subjects
                                                    .where(
                                                      (subject) =>
                                                          subject != null &&
                                                          subject.containsKey(
                                                            'name',
                                                          ),
                                                    )
                                                    .map(
                                                      (subject) =>
                                                          subject['name']
                                                              .toString()
                                                              .replaceAll(
                                                                '&amp;',
                                                                '&',
                                                              ),
                                                    )
                                                    .join(' , ')
                                                : '${Localization.translate("subjects_empty")}',
                                        rating:
                                            tutor['avg_rating'] != null
                                                ? (tutor['avg_rating'] is String
                                                    ? double.tryParse(
                                                          tutor['avg_rating'],
                                                        ) ??
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
                                        languages:
                                            languages.isNotEmpty
                                                ? languages
                                                    .map((lang) => lang['name'])
                                                    .join(', ')
                                                : 'No languages available',
                                        image:
                                            profile['image'] ??
                                            AppImages.placeHolderImage,
                                        countryFlag:
                                            country['short_code'] != null
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
                                        isFavorite:
                                            tutor['is_favorite'] ?? false,
                                        deleteIcon: false,
                                        onDelete: () {},
                                        onFavouriteToggle: (isFavorite) async {
                                          await toggleFavouriteTutor(
                                            tutor['id'],
                                            !isFavorite,
                                          );
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
                      if (isCommunityEnabled) ...[
                        CommunityPage(
                          onBackPressed: () {
                            _pageController.jumpToPage(0);
                          },
                        ),
                      ],
                      BookingScreen(
                        onBackPressed: () {
                          _pageController.jumpToPage(0);
                        },
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return (authProvider.token == null ||
                                  authProvider.userData == null)
                              ? GuestProfileScreen()
                              : ProfileScreen();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.dividerColor, width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dividerColor.withOpacity(0.5),
                  offset: Offset(0, 1),
                  blurRadius: 1,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: _onItemTapped,
              unselectedItemColor: AppColors.greyColor(context),
              selectedItemColor: AppColors.greyColor(context),
              selectedLabelStyle: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 12),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
              ),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.whiteColor,
              items: [
                BottomNavigationBarItem(
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      selectedIndex == 0
                          ? SvgPicture.asset(
                            AppImages.searchBottomFilled,
                            width: 25,
                            height: 25,
                          )
                          : SvgPicture.asset(
                            AppImages.search,
                            width: 25,
                            height: 25,
                          ),
                      if (Localization.textDirection == TextDirection.rtl)
                        SizedBox(height: 4),
                    ],
                  ),
                  label: Localization.translate('search'),
                ),
                if (isCommunityEnabled) ...[
                  BottomNavigationBarItem(
                    icon: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        selectedIndex == 1
                            ? SvgPicture.asset(
                              AppImages.communityFilled,
                              width: 25,
                              height: 25,
                            )
                            : SvgPicture.asset(
                              AppImages.communityIcon,
                              width: 25,
                              height: 25,
                            ),
                        if (Localization.textDirection == TextDirection.rtl)
                          SizedBox(height: 10),
                      ],
                    ),
                    label: Localization.translate('community'),
                  ),
                ],
                BottomNavigationBarItem(
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      (isCommunityEnabled
                              ? selectedIndex == 2
                              : selectedIndex == 1)
                          ? SvgPicture.asset(
                            AppImages.calenderIcon,
                            width: 25,
                            height: 25,
                          )
                          : SvgPicture.asset(
                            AppImages.bookingIcon,
                            color: AppColors.greyColor(context),
                            width: 25,
                            height: 25,
                          ),
                      if (Localization.textDirection == TextDirection.rtl)
                        SizedBox(height: 10),
                    ],
                  ),
                  label: Localization.translate('booking'),
                ),
                BottomNavigationBarItem(
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildProfileIcon(),
                      if (Localization.textDirection == TextDirection.rtl)
                        SizedBox(height: 10),
                    ],
                  ),
                  label: Localization.translate('profile'),
                ),
              ],
            ),
          ),
        ),
      ),
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
                '${tutors.length} / ${totalTutors} ${Localization.translate('tutors')}',
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
              CustomDropdown(
                hint: Localization.translate('choose_sorting'),
                selectedValue: _selectedSorting,
                items: sortingOptions,
                onSelected: _onSortSelected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
