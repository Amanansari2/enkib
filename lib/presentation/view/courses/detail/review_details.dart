import 'package:flutter/material.dart';
import '../../../../data/localization/localization.dart';
import '../../../../styles/app_styles.dart';
import '../../components/student_card.dart';

class DetailReviewScreen extends StatelessWidget {
  final List<dynamic> ratings;

  const DetailReviewScreen({Key? key, required this.ratings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor(context),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: Container(
            color: AppColors.whiteColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: AppBar(
                forceMaterialTransparency: true,
                centerTitle: false,
                backgroundColor: AppColors.whiteColor,
                elevation: 0,
                titleSpacing: 0,
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${(Localization.translate('course_reviews') ?? '').trim() != 'course_reviews' && (Localization.translate('course_reviews') ?? '').trim().isNotEmpty ? Localization.translate('course_reviews') : "Reviews"}",
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSize.scale(context, 20),
                        fontFamily: AppFontFamily.mediumFont,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: '${ratings.length}',
                        style: TextStyle(
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w600,
                          fontSize: FontSize.scale(context, 13),
                          fontStyle: FontStyle.normal,
                          color: AppColors.greyColor(context),
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: ' ',
                          ),
                          TextSpan(
                            text: '${Localization.translate("found")}',
                            style: TextStyle(
                              fontFamily: AppFontFamily.regularFont,
                              fontWeight: FontWeight.w400,
                              fontSize: FontSize.scale(context, 13),
                              fontStyle: FontStyle.normal,
                              color: AppColors.greyColor(context),
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
        body:
        ratings.isEmpty == null
            ? Center(
          child: Text(
            "${(Localization.translate('empty_course_reviews') ?? '').trim() != 'empty_course_reviews' && (Localization.translate('empty_course_reviews') ?? '').trim().isNotEmpty ? Localization.translate('empty_course_reviews') : "Reviews not available"}",
            style: TextStyle(
              color: AppColors.greyColor(context),
              fontSize: FontSize.scale(context, 16),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
        )
            :
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 5),
                itemCount: ratings.length,
                itemBuilder: (context, index) {
                  final review = ratings[index];
                  final user = review['user'] ?? {};
                  final reviewDate = review['created_at'] ?? '';
                  final country = user ?? '';
                  final countryShortCode = country['short_code'] ?? '';
                  final countryFlagUrl =
                      '${AppUrls.flagUrl}${countryShortCode.toLowerCase()}.png';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: StudentCard(
                      name: user['name'] ?? '',
                      date: reviewDate,
                      description: review['comment'] ?? '',
                      rating: review['rating'].toDouble(),
                      image: user['image'] ?? '',
                      countryFlag: countryFlagUrl.isNotEmpty ? countryFlagUrl : '',
                      isFullWidth: true,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 30)
          ],
        ),
      ),
    );
  }
}
