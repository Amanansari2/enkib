import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../base_components/custom_toast.dart';
import '../../../data/localization/localization.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/provider/settings_provider.dart';
import '../../../domain/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import 'login_required_alert.dart';

class TutorCard extends StatefulWidget {
  final String name;
  final String price;
  final String description;
  final double rating;
  final String reviews;
  final String activeStudents;
  final String sessions;
  final String languages;
  final String image;
  final String countryFlag;
  final String verificationIcon;
  final String onlineIndicator;
  final bool languagesText;
  final bool filledStar;
  final bool hourRate;
  final bool isFullWidth;
  final int tutorId;
  final bool deleteIcon;
  final VoidCallback? onDelete;
  final Future<void> Function(bool isFavorite) onFavouriteToggle;
  final ValueNotifier<bool> isFavoriteNotifier;
  final bool isFavorite;

  TutorCard({
    required this.tutorId,
    required this.name,
    required this.price,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.activeStudents,
    required this.sessions,
    required this.languages,
    required this.image,
    required this.countryFlag,
    required this.verificationIcon,
    required this.onlineIndicator,
    this.languagesText = false,
    this.filledStar = false,
    this.hourRate = true,
    this.isFullWidth = false,
    this.deleteIcon = false,
    required this.onDelete,
    required this.onFavouriteToggle,
    required this.isFavorite,
  }) : isFavoriteNotifier = ValueNotifier(isFavorite);

  @override
  State<TutorCard> createState() => _TutorCardState();
}

class _TutorCardState extends State<TutorCard> {
  bool isLoadingFavorite = false;
  late String studentName = "";
  String paymentEnabled = "no";

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

  Future<void> toggleFavorite(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    setState(() {
      isLoadingFavorite = true;
    });

    try {
      final token = authProvider.token;
      if (token != null) {
        final response = await addDeleteFavouriteTutors(
          token,
          widget.tutorId,
          authProvider,
        );

        if (response['status'] == 200) {
          showCustomToast(context, '${response['message']}', true);
        } else if (response['status'] == 403) {
          showCustomToast(context, response['message'], false);
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
        } else {
          showCustomToast(
            context,
            response['message'] ?? 'Something went wrong',
            false,
          );
        }
      } else if ((token == null || userData == null)) {
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
    } catch (e) {
      showCustomToast(
        context,
        '${Localization.translate("error_message")} $e',
        false,
      );
    } finally {
      setState(() {
        isLoadingFavorite = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final userData = authProvider.userData;

    final String truncatedDescription =
        (widget.description.isEmpty)
            ? "${Localization.translate("description_unavailable")}"
            : (widget.description.length > 52
                ? '${widget.description.substring(0, 52)}...'
                : widget.description);

    String displayLanguages =
        widget.languages.isNotEmpty
            ? widget.languages
            : '${Localization.translate("languages_unavailable")}';

    String profileImageUrl =
        authProvider.userData?['user']?['profile']?['image'] ?? '';

    final String? role =
        userData != null && userData['user'] != null
            ? userData['user']['role']
            : null;

    studentName =
        settingsProvider.getSetting(
          'data',
        )?['_lernen']?['student_display_name'] ??
        '';

    paymentEnabled =
        settingsProvider.getSetting('data')?['_lernen']?['payment_enabled'];

    final isFavorite = authProvider.isTutorFavorite(widget.tutorId);

    Widget displayImage() {
      return widget.image.isNotEmpty
          ? CachedNetworkImage(
            imageUrl: widget.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => SizedBox(width: 60, height: 60),
            errorWidget: (context, url, error) {
              return profileImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: profileImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => SizedBox(
                          width: 60,
                          height: 60,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: AppColors.primaryGreen(context),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => SvgPicture.asset(
                          AppImages.placeHolder,
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                        ),
                  )
                  : SvgPicture.asset(
                    AppImages.personOutline,
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                  );
            },
          )
          : profileImageUrl.isNotEmpty
          ? CachedNetworkImage(
            imageUrl: profileImageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: AppColors.primaryGreen(context),
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => SvgPicture.asset(
                  AppImages.personOutline,
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                ),
          )
          : SvgPicture.asset(
            AppImages.personOutline,
            width: 60,
            height: 60,
            alignment: Alignment.center,
          );
    }

    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        width:
            widget.isFullWidth
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.width * 0.9,
        margin: EdgeInsets.only(right: widget.isFullWidth ? 0 : 16),
        decoration:
            widget.isFullWidth
                ? BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(0),
                  boxShadow: [],
                )
                : BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greyColor(context).withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: displayImage(),
                          ),
                          if (widget.onlineIndicator.isNotEmpty)
                            Positioned(
                              bottom: -10,
                              left: 22,
                              child: Image.asset(
                                widget.onlineIndicator,
                                width: 16,
                                height: 16,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                Localization.textDirection == TextDirection.ltr
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                            children: [
                              Text(
                                widget.name,
                                textAlign:
                                    Localization.textDirection ==
                                            TextDirection.ltr
                                        ? TextAlign.start
                                        : TextAlign.end,
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: AppColors.blackColor,
                                  fontSize: FontSize.scale(context, 18),
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal,
                                  fontFamily: AppFontFamily.mediumFont,
                                ),
                              ),
                              SizedBox(width: 2),
                              if (widget.verificationIcon.isNotEmpty)
                                Image.asset(
                                  widget.verificationIcon,
                                  scale: 1,
                                  width: 35,
                                  height: 16,
                                ),
                              SizedBox(width: 2),
                              widget.countryFlag.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: Image.network(
                                      widget.countryFlag,
                                      width: 18,
                                      height: 14,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Image.asset(
                                          AppImages.flag,
                                          width: 20,
                                          height: 20,
                                        );
                                      },
                                    ),
                                  )
                                  : Image.asset(
                                    AppImages.flag,
                                    width: 20,
                                    height: 20,
                                  ),
                            ],
                          ),

                          if (paymentEnabled == "yes") ...[
                            SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                text: Localization.translate("starting"),
                                style: TextStyle(
                                  color: AppColors.greyColor(context),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  fontFamily: AppFontFamily.regularFont,
                                ),
                                children: <TextSpan>[
                                  TextSpan(text: " "),
                                  TextSpan(
                                    text: widget.price,
                                    style: TextStyle(
                                      color: AppColors.blackColor,
                                      fontSize: FontSize.scale(context, 16),
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                      fontFamily: AppFontFamily.mediumFont,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${Localization.translate("hr")}',
                                    style: TextStyle(
                                      color: AppColors.greyColor(context),
                                      fontSize: FontSize.scale(context, 14),
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      fontFamily: AppFontFamily.regularFont,
                                    ),
                                  ),
                                  TextSpan(text: ' '),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    truncatedDescription,
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: FontSize.scale(context, 14),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.mediumFont,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      SvgPicture.asset(
                        widget.filledStar
                            ? AppImages.filledStar
                            : AppImages.star,
                        width: 16,
                        height: 16,
                      ),
                      SizedBox(width: 5),
                      Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: '${widget.rating}',
                              style: TextStyle(
                                color: AppColors.greyColor(context),
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontFamily: AppFontFamily.mediumFont,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${(Localization.translate('total_rating') ?? '').trim() != 'total_rating' && (Localization.translate('total_rating') ?? '').trim().isNotEmpty ? Localization.translate('total_rating') : '/5.0'} (${widget.reviews} ${Localization.translate("reviews")})',
                              style: TextStyle(
                                color: AppColors.greyColor(
                                  context,
                                ).withOpacity(0.7),
                                fontSize: FontSize.scale(context, 14),
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
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.userIcon,
                            width: 14,
                            height: 14,
                            color: AppColors.greyColor(context),
                          ),
                          SizedBox(width: 5),
                          Text.rich(
                            TextSpan(
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${widget.activeStudents}',
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 14),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.mediumFont,
                                  ),
                                ),
                                TextSpan(text: ' '),
                                TextSpan(
                                  text:
                                      (widget.activeStudents == null ||
                                              widget.activeStudents.isEmpty ||
                                              widget.activeStudents == '0' ||
                                              widget.activeStudents == '1')
                                          ? (widget.activeStudents == null ||
                                                  widget.activeStudents.isEmpty
                                              ? "Student"
                                              : "${studentName}")
                                          : "${Localization.translate("students")}",
                                  style: TextStyle(
                                    color: AppColors.greyColor(
                                      context,
                                    ).withOpacity(0.7),
                                    fontSize: FontSize.scale(context, 14),
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
                      SizedBox(width: 80),
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.sessions,
                            width: 14,
                            height: 14,
                            color: AppColors.greyColor(context),
                          ),
                          SizedBox(width: 5),
                          Text.rich(
                            TextSpan(
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${widget.sessions} ',
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 14),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.mediumFont,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      (widget.sessions == null ||
                                              widget.sessions.isEmpty ||
                                              widget.sessions == '0' ||
                                              widget.sessions == '1')
                                          ? (widget.sessions == null ||
                                                  widget.sessions.isEmpty
                                              ? "Session"
                                              : "${Localization.translate("session")[0].toUpperCase()}${Localization.translate("session").substring(1).toLowerCase()}")
                                          : "${Localization.translate("sessions")}",
                                  style: TextStyle(
                                    color: AppColors.greyColor(
                                      context,
                                    ).withOpacity(0.7),
                                    fontSize: FontSize.scale(context, 14),
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
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppImages.language,
                        width: 14,
                        height: 14,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: <TextSpan>[
                              if (widget.languagesText)
                                TextSpan(
                                  text: Localization.translate("languages"),
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 14),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.mediumFont,
                                  ),
                                ),
                              TextSpan(
                                text: displayLanguages,
                                style: TextStyle(
                                  color: AppColors.greyColor(
                                    context,
                                  ).withOpacity(0.7),
                                  fontSize: FontSize.scale(context, 14),
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  fontFamily: AppFontFamily.regularFont,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            if (role == 'student')
              Positioned(
                top: 25,
                right:
                    Localization.textDirection == TextDirection.ltr ? 12 : null,
                left:
                    Localization.textDirection == TextDirection.rtl ? 12 : null,
                child: IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed:
                      isLoadingFavorite ? null : () => toggleFavorite(context),
                  icon:
                      isLoadingFavorite
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen(context),
                            ),
                          )
                          : Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color:
                                isFavorite
                                    ? AppColors.redColor
                                    : AppColors.greyColor(context),
                          ),
                ),
              ),
            if (widget.deleteIcon)
              Positioned(
                top: 10,
                right:
                    Localization.textDirection == TextDirection.ltr ? 15 : null,
                left:
                    Localization.textDirection == TextDirection.rtl ? 15 : null,
                child: IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: widget.onDelete,
                  icon: SvgPicture.asset(AppImages.binIcon, height: 45),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
