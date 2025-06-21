import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_toast.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/components/skeleton/tutor_card_skeleton.dart';
import 'package:flutter_projects/view/components/tutor_card.dart';
import 'package:flutter_projects/view/detailPage/detail_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';

class FavoritesTutorsScreen extends StatefulWidget {
  @override
  State<FavoritesTutorsScreen> createState() => _FavoritesTutorsScreenState();
}

class _FavoritesTutorsScreenState extends State<FavoritesTutorsScreen> {
  late double screenWidth;
  late double screenHeight;

  List<Map<String, dynamic>> tutors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedTutors();
  }

  Future<void> _fetchSavedTutors() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await savedTutors(token!);

      print("Response ----->>> $response");

      if (response['status'] == 200) {
        setState(() {
          print("Tutors ------>>>> $tutors");
          tutors = List<Map<String, dynamic>>.from(response['data']);
          isLoading = false;
        });
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

  Future<void> _removeTutor(int tutorId, int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final response =
        await addDeleteFavouriteTutors(token!, tutorId, authProvider);

    if (response['status'] == 200) {
      setState(() {
        tutors.removeAt(index);
      });
      authProvider.removeFavoriteTutor(tutorId);
      showCustomToast(context, response['message'], true);
    }
    else if (response['status'] == 403) {
      showCustomToast(
        context,
        response['message'],
        false,
      );
    } else if (response['status'] == 401) {
     showCustomToast(context,
              '${Localization.translate("unauthorized_access")}', false);
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
    else {
      showCustomToast(context, response['message'], false);
    }
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 1.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 500), () {
      overlayEntry.remove();
    });
  }

  Future<void> toggleFavouriteTutor(int tutorId, bool isFavorite) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = (await addDeleteFavouriteTutors(
        authProvider.token!, tutorId, authProvider)) as bool;
    if (success) {
      if (isFavorite) {
        authProvider.addFavoriteTutor(tutorId);
      } else {
        authProvider.removeFavoriteTutor(tutorId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: Localization.textDirection,
      child: Scaffold(
          backgroundColor: AppColors.backgroundColor(context),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.0),
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: AppBar(
                centerTitle: false,
                backgroundColor: AppColors.whiteColor,
                elevation: 0,
                titleSpacing: 0,
                title: Text(
                  Localization.translate("favorite_tutors"),
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 20,
                    fontFamily: AppFontFamily.font,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon:
                        Icon(Icons.arrow_back_ios, size: 20, color: AppColors.blackColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),
          body: isLoading
              ? ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TutorCardSkeleton(isFullWidth: true, isDelete: true),
                    );
                  },
                )
              : tutors.isEmpty
                  ? Center(
                      child: Text(
                        Localization.translate("favorite_tutors_empty"),
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: AppFontFamily.font,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greyColor(context),
                      ),
                    ))
                  : ListView.builder(
                      padding: EdgeInsets.only(top: 10.0),
                      itemCount: tutors.length,
                      itemBuilder: (context, index) {
                        final tutor = tutors[index];
                        final profile = tutor['profile'];
                        final subjects =
                            tutor['subjects'] as List<dynamic>? ?? [];

                        final description = subjects.isNotEmpty
                            ? subjects[0]['description'] ?? 'No description'
                            : 'No description';

                        final address = tutor['address'] ?? {};
                        final country = address['country'];
                        final countryShortCode = country != null
                            ? country['short_code']?.toLowerCase() ?? 'default'
                            : 'default';
                        final countryFlagUrl =
                            '${AppUrls.flagUrl}${countryShortCode}.png';
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
                        final formattedName = formatTutorName(profile['full_name'] ?? 'Unknown Tutor');


                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GestureDetector(
                            onTap: () {
                              if (profile != null &&
                                  profile is Map<String, dynamic>) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TutorDetailScreen(profile: profile),
                                  ),
                                );
                              }
                            },
                            child: TutorCard(
                              tutorId: tutor['id'] ?? '',
                              name: formattedName,
                              price: tutor['min_price']?.toString() ?? '0',
                              description: description,
                              rating: tutor['avg_rating']?.toDouble() ?? 0.0,
                              reviews: tutor['total_reviews']?.toString() ?? '0',
                              activeStudents:
                                  tutor['active_students']?.toString() ?? '0',
                              sessions: tutor['sessions']?.toString() ?? '0',
                              languages: tutor['languages']
                                  .map((lang) => lang['name'])
                                  .join(', '),
                              image: profile['image'] ?? '',
                              countryFlag: countryFlagUrl,
                              verificationIcon: profile['verified_at'] != null
                                  ? 'assets/images/active.png'
                                  : '',
                              onlineIndicator: tutor['is_online'] == true
                                  ? 'assets/images/online_indicator.png'
                                  : '',
                              isFavorite: tutor['is_favorite'] ?? false,
                              deleteIcon: true,
                              onFavouriteToggle: (isFavorite) async {
                                await toggleFavouriteTutor(
                                    tutor['id'], isFavorite);
                                setState(() {
                                  tutors.removeAt(index);
                                });
                              },
                              isFullWidth: true,
                              onDelete: () {
                                _showRemoveDialog(context, tutor['id'], index);
                              },
                            ),
                          ),
                        );
                      },
                    )),
    );
  }

  void _showRemoveDialog(BuildContext context, int tutorId, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 400,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AppImages.deleteIcon,
                    height: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    Localization.translate("remove_alert_message"),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.font,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    Localization.translate("tutor_remove_title"),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.font,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.greyColor(context),
                              width: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 35),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Localization.translate("cancel"),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.greyColor(context),
                                fontFamily: AppFontFamily.font,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        child: OutlinedButton(
                          onPressed: () {
                            _removeTutor(tutorId, index);
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.redBackgroundColor,
                            side: BorderSide(
                                color: AppColors.redBorderColor, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 35),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Localization.translate("remove"),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.blueColor,
                                fontFamily: AppFontFamily.font,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
