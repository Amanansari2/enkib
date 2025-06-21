import 'package:flutter/material.dart';
import 'package:flutter_projects/data/localization/localization.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../styles/app_styles.dart';
import '../../forum_detail.dart';

class ForumCard extends StatelessWidget {
  final String imageUrl;
  final String profileImage;
  final String author;
  final String time;
  final String replies;
  final String views;
  final String title;
  final String description;
  final String postsCount;
  final String slug;
  final int id;

  ForumCard({
    required this.imageUrl,
    required this.profileImage,
    required this.author,
    required this.time,
    required this.replies,
    required this.views,
    required this.title,
    required this.description,
    required this.postsCount,
    required this.slug,
    required this.id
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForumDetail(slug:slug, id: id, )),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Image.asset(
                        AppImages.placeHolderImage,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -15,
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                            AppColors.greyColor(context).withOpacity(0.3),
                            blurRadius: 5,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.whiteColor,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: (profileImage.isNotEmpty)
                              ? NetworkImage(profileImage)
                              : AssetImage(AppImages.placeHolderImage) as ImageProvider<Object>,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      author,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.mediumFont,
                        color: AppColors.blackColor.withOpacity(0.7),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blackColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${Localization.translate("author")}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.mediumFont,
                          color: AppColors.greyColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                  height:
                  Localization.textDirection == TextDirection.rtl ? 5 : 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Transform.translate(
                      offset: Localization.textDirection == TextDirection.rtl
                          ? Offset(0, 5)
                          : Offset(0, 0),
                      child: SvgPicture.asset(
                        AppImages.activity,
                        width: 20,
                        height: 20,
                      ),
                    ),
                    SizedBox(width: 10),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: time,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.mediumFont,
                              color: AppColors.greyColor(context),
                            ),
                          ),
                          TextSpan(
                            text: " ",
                          ),
                          TextSpan(
                            text: "${Localization.translate("last_activity")}",
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.regularFont,
                              color:
                              AppColors.greyColor(context).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: postsCount,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.mediumFont,
                              color: AppColors.greyColor(context),
                            ),
                          ),
                          TextSpan(
                            text: " ",
                          ),
                          TextSpan(
                            text: "${Localization.translate("posts")}",
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: FontSize.scale(context, 14),
                              fontFamily: AppFontFamily.regularFont,
                              color:
                              AppColors.greyColor(context).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                  height:
                  Localization.textDirection == TextDirection.rtl ? 12 : 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Localization.textDirection == TextDirection.rtl
                            ? SvgPicture.asset(
                          AppImages.replyForward,
                          width: 15,
                          height: 15,
                        )
                            : SvgPicture.asset(
                          AppImages.reply,
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: replies,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.mediumFont,
                                  color: AppColors.greyColor(context),
                                ),
                              ),
                              TextSpan(
                                text: " ",
                              ),
                              TextSpan(
                                text: "${Localization.translate("replies")}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.regularFont,
                                  color: AppColors.greyColor(context)
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Transform.translate(
                          offset:
                          Localization.textDirection == TextDirection.rtl
                              ? Offset(0, 2)
                              : Offset(0, 0),
                          child: SvgPicture.asset(
                            AppImages.showIcon,
                            width: 18,
                            height: 18,
                            color: AppColors.orangeColor,
                          ),
                        ),
                        SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: views,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.mediumFont,
                                  color: AppColors.greyColor(context),
                                ),
                              ),
                              TextSpan(
                                text: " ",
                              ),
                              TextSpan(
                                text: "${Localization.translate("views")}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSize.scale(context, 14),
                                  fontFamily: AppFontFamily.regularFont,
                                  color: AppColors.greyColor(context)
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.mediumFont,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  description,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.regularFont,
                    color: AppColors.greyColor(context),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
