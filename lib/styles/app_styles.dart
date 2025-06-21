import 'package:flutter/material.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/provider/settings_provider.dart';
import 'package:provider/provider.dart';

class AppColors {
  static Color backgroundColor(BuildContext context) {
    const defaultColor = Color(0xFFF4F4FB);

    try {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final String? appBgColorHex =
          settingsProvider.settings['data']?['_app']?['app_bg_color'];

      if (appBgColorHex != null) {
        return Color(int.parse(appBgColorHex.replaceFirst('0X', '0xff')));
      }
    } catch (e) {}

    return defaultColor;
  }

  static Color primaryGreen(BuildContext context) {
    const defaultColor =   Color(0xFFFC5119);    //Color(0xFF295C51);

    try {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final String? appBgColorHex =
          settingsProvider.settings['data']?['_app']?['app_pri_color'];

      if (appBgColorHex != null) {
        return Color(int.parse(appBgColorHex.replaceFirst('0X', '0xff')));
      }
    } catch (e) {}

    return defaultColor;
  }

  static Color greyColor(BuildContext context) {
    const defaultColor = Color(0xFF585858);

    try {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final String? appBgColorHex =
          settingsProvider.settings['data']?['_app']?['app_sec_color'];

      if (appBgColorHex != null) {
        return Color(int.parse(appBgColorHex.replaceFirst('0X', '0xff')));
      }
    } catch (e) {}

    return defaultColor;
  }
  static const whiteColor = Color(0xFFFFFFFF);
  static const blackColor = Color(0xFF000000);
  static const greyFadeColor = Color(0xFFF9FBFF);
  static const dividerColor = Color(0xFFEAEAEA);
  static const blueColor = Color(0xFF0265FB); //Color(0xFF1570EF);
  static const sheetBackgroundColor = Color(0xFFF8F8F8);
  static const topBottomSheetDismissColor = Color(0xFF3C3C434D);
  static const fadeColor = Color(0xFFF7F7F8);
  static const primaryWhiteColor = Color(0xFFFAFAFA);
  static const orangeColor = Color(0xFFFC5119); //Color(0xFFFF9000);
  static const purpleColor = Color(0xFF601DA4);
  static const redColor = Color(0xFFF04438);
  static const redBackgroundColor = Color(0xFFFC5119); //Color(0xFFFEF3F2);
  static const redBorderColor = Color(0xFFFC5119);  //Color(0xFFFFD5D2);
  static const yellowColor = Color(0xFFFEC84B);
  static const lightGreenColor = Color(0xFF75E0A7);
  static const lightBlueColor = Color(0xFF53B1FD);
  static const pinkColor = Color(0xFFFDE7E7);
  static const lightPinkColor = Color(0xFFFEF2F1);
  static const unfocusedColor = Color(0xFFEDEDF3);
  static const darkBlue = Color(0xFF101828);
  static const completeStatusColor = Color(0xFFDCFAE6);
  static const completeStatusTextColor = Color(0xFF0265FB); //Color(0xFF085D3A);
  static const pendingStatusColor = Color(0xFFEFF8FF);
  static const bookBorderPinkColor = Color(0xFFFDA29B);
  static const typeBackgroundColor = Color(0xFFFEF3F2);
  static const yellowBorderColor = Color(0xFFFFFAEB);
  static const userIconColor = Color(0xFFDC6803); //Color(0xFFDC6803);
  static const clockColor = Color(0xFF4843BC);
  static const purpleBorderColor = Color(0xFFF2EEFA);
  static const darkGreen = Color(0xFF079455);
  static const lightGreen = Color(0xFFECFDF3);
  static const lightBlue = Color(0xFFEFF8FF);
  static const blue = Color(0xFF1570EF);
  static const speakerBgColor = Color(0xFFf2f5f5);
  static const trashBgColor = Color(0xFFFAEDED);
}

class AppImages {
//  static const String logo = 'assets/svg/app_logo.svg';
  static const String logo = 'assets/logo/enkib1.png';
  static String getDynamicAppLogo(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    try {
      final dynamic appLogo =
          settingsProvider.settings['data']?['_app']?['app_logo'];
      if (appLogo != null && appLogo is List && appLogo.isNotEmpty) {
        return appLogo[0]['thumbnail'] ?? logo;
      }
    } catch (e) {}

    return logo;
  }

  static const String defaultSplash = 'assets/logo/enkib1.png';

  static String getDynamicSplash(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    try {
      final dynamic splashData =
          settingsProvider.settings['data']?['_app']?['app_splash'];
      if (splashData != null && splashData is List && splashData.isNotEmpty) {
        return splashData[0]['thumbnail'] ?? defaultSplash;
      }
    } catch (e) {}

    return defaultSplash;
  }

  static const String icon = 'assets/images/icon.png';
  static const String flag = 'assets/images/flag.png';
  static const String filledStar = 'assets/svg/filledstar.svg';
  static const String star = 'assets/svg/star.svg';
  static const String userIcon = 'assets/svg/users.svg';
  static const String sessions = 'assets/svg/sessions.svg';
  static const String language = 'assets/svg/language.svg';
  static const String active = 'assets/images/active.png';
  static const String bookingCalender = 'assets/svg/booking_calender.svg';
  static const String speaker = 'assets/svg/speaker.svg';
  static const String search = 'assets/svg/search.svg';
  static const String dateIcon = 'assets/svg/date_picker.svg';
  static const String locationIcon = 'assets/svg/location.svg';
  static const String emptyEducation = 'assets/images/empty_eductaion.png';
  static const String deleteIcon = 'assets/svg/delete_alert.svg';
  static const String emptyExperience = 'assets/images/empty_experience.png';
  static const String briefcase = 'assets/svg/briefcase.svg';
  static const String emptyCertificate = 'assets/svg/empty_certificate.svg';
  static const String forwardArrow = 'assets/svg/forward_Arrow.svg';
  static const String backArrow = 'assets/svg/back_arrow.svg';
  static const String addSessionIcon = 'assets/svg/calender_plus.svg';
  static const String loginRequired = 'assets/svg/required.svg';
  static const String internetRequired = 'assets/svg/internetRequired.svg';
  static const String hideIcon = 'assets/svg/eye_close.svg';
  static const String showIcon = 'assets/svg/eye.svg';
  static const String mandatory = 'assets/svg/staric.svg';
  static const String dateTimeIcon = 'assets/svg/date_time.svg';
  static const String filterIcon = 'assets/svg/filters.svg';
  static const String searchBottomFilled =
      'assets/svg/search_bottom_filled.svg';
  static const String bookingIcon = 'assets/svg/booking.svg';
  static const String calenderIcon = 'assets/svg/calender_icon_bottom.svg';
  static const String placeHolder = 'assets/svg/placeHolder.svg';
  static const String videoPlaceHolder = 'assets/svg/video.svg';
  static const String onlineIndicator = 'assets/images/online_indicator.png';
  static const String insightsIcon = 'assets/svg/insights.svg';
  static const String insightsBg = 'assets/images/e1.png';
  static const String walletBalanceIcon = 'assets/svg/wallet_balance.svg';
  static const String walletBalanceBg = 'assets/images/e2.png';
  static const String clockIcon = 'assets/svg/clock.svg';
  static const String pendingAmountBg = 'assets/images/e3.png';
  static const String dollarIcon = 'assets/svg/dollar.svg';
  static const String walletFundsBg = 'assets/images/e4.png';
  static const String walletIcon = 'assets/svg/wallet.svg';
  static const String pendingWithDrawIcon = 'assets/svg/pending_withdraw.svg';
  static const String withdrawBg = 'assets/images/e5.png';
  static const String paypal = 'assets/images/paypal.png';
  static const String payoneer = 'assets/images/payoneer.png';
  static const String bankTransfer = 'assets/images/bank_transfer.png';
  static const String personOutline = 'assets/svg/person.svg';
  static const String bookEducationIcon = 'assets/svg/book_education.svg';
  static const String certificateIcon = 'assets/svg/certificate.svg';
  static const String settingIcon = 'assets/svg/setting.svg';
  static const String invoicesIcon = 'assets/svg/invoices.svg';
  static const String placeHolderImage = 'assets/images/placeHolderImage.png';
  static const String sorting = 'assets/svg/asc_sort.svg';
  static const String typeSession = 'assets/svg/type_session.svg';
  static const String type = 'assets/svg/type.svg';
  static const String calenderSession = 'assets/svg/calender_session.svg';
  static const String timerSession = 'assets/svg/timer_session.svg';
  static const String dollarSession = 'assets/svg/dollar_session.svg';
  static const String dollarInsightIcon = 'assets/svg/dollar_insight.svg';
  static const String dateCalender = 'assets/svg/date_calender.svg';
  static const String trashIcon = 'assets/svg/trash.svg';
  static const String videoAppLogo = 'assets/images/logo.png';
  static const String arrowDown = 'assets/svg/arrow_down.svg';
  static const String clockInsightIcon = 'assets/svg/clock_insight.svg';
  static const String sessionCart = 'assets/svg/session_cart.svg';
  static const String binIcon = 'assets/svg/delete.svg';
  static const String favorite = 'assets/svg/favorite.svg';
  static const String favoriteFilled = 'assets/svg/heart_filled.svg';
  static const String identityVerification = 'assets/svg/identity.svg';
  static const String accepted = 'assets/myimg/accept.png';
  static const String imagePlaceholder ='assets/images/placeholder.png';
  static const String courseImage = 'assets/myimg/course_image.jpg';
  static const String termConditions = 'assets/logo/terms.png';
  static const String privacyPolicy = 'assets/logo/insurance.png';
  static const String userImage = 'assets/myimg/user.png';
}

class AppFontFamily {
  static const String font = 'SF-Pro-Text';
}

class FontSize {
  static double scale(BuildContext context, double size) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double baseWidth = Localization.textDirection == TextDirection.rtl? 410.0:375.0;
    double baseHeight =Localization.textDirection == TextDirection.rtl? 400.0:812.0;

    double widthFactor = screenWidth / baseWidth;
    double heightFactor = screenHeight / baseHeight;

    double scaleFactor =
        widthFactor < heightFactor ? widthFactor : heightFactor;

    return size * scaleFactor;
  }
}

class AppUrls {
  static const String privacyPolicyUrl = 'REPLACE_YOUR_PRIVACY_URL';
  static const String termsConditionUrl = 'REPLACE_YOUR_TERMS&CONDITIONS_URL';
  static const String flagUrl = 'https://flagcdn.com/w20/';
}
