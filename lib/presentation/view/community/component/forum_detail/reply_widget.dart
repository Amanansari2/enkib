import 'package:flutter/material.dart';
import 'package:flutter_projects/data/localization/localization.dart';
import 'package:flutter_projects/presentation/view/community/component/forum_detail/reply.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../styles/app_styles.dart';

class ReplyWidget extends StatefulWidget {
  final Reply reply;

  const ReplyWidget({
    Key? key,
    required this.reply,
  }) : super(key: key);

  @override
  _ReplyWidgetState createState() => _ReplyWidgetState();
}

class _ReplyWidgetState extends State<ReplyWidget> {
  bool showSubReplies = false;

  @override
  Widget build(BuildContext context) {
    final reply = widget.reply;
    final fullName =
    '${reply.firstName ?? 'Unknown'} ${reply.lastName ?? ''}'.trim();
    final imageUrl = reply.imageUrl ?? '';

    return Padding(
      padding:  EdgeInsets.only(left:
      Localization.textDirection==TextDirection.rtl?2: 32.0, bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: (imageUrl.isNotEmpty)
                    ? NetworkImage(imageUrl)
                    : AssetImage(AppImages.placeHolderImage) as ImageProvider<Object>,
                radius: 15,
              ),
              const SizedBox(width: 8),
              Text(
                fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: FontSize.scale(context, 14),
                  fontFamily: AppFontFamily.mediumFont,
                  color: AppColors.blackColor,
                ),
              ),
              Spacer(),
              Text(
                formatTime(reply.createdAt),
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: FontSize.scale(context, 12),
                  fontFamily: AppFontFamily.regularFont,
                  color: AppColors.greyColor(context),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              reply.description,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: FontSize.scale(context, 14),
                fontFamily: AppFontFamily.regularFont,
                color: AppColors.greyColor(context),
              ),
            ),
          ),
          if ((reply.likesCount > 0) ||
              (reply.repliesCount > 0))
            Padding(
              padding: EdgeInsets.only(right:Localization.textDirection==TextDirection.rtl? 20.0:0.0),
              child: Row(
                children: [
                  if (reply.likesCount > 0) ...[
                    const Icon(Icons.favorite, color: AppColors.redColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      reply.likesCount.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: FontSize.scale(context, 12),
                        fontFamily: AppFontFamily.regularFont,
                        color: AppColors.greyColor(context).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (reply.repliesCount > 0)
                    Padding(
                      padding: EdgeInsets.only(right:Localization.textDirection==TextDirection.rtl?8.0:0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            showSubReplies = !showSubReplies;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: AppColors.blackColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                AppImages.commentIcon,
                                width: 15,
                                height: 15,
                                color: AppColors.greyColor(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${reply.repliesCount}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSize.scale(context, 12),
                                  fontFamily: AppFontFamily.regularFont,
                                  color: AppColors.greyColor(context),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                Localization.translate("replies"),
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSize.scale(context, 12),
                                  fontFamily: AppFontFamily.regularFont,
                                  color:
                                  AppColors.greyColor(context).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (showSubReplies && reply.replies.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: Localization.textDirection==TextDirection.rtl?2:0.0, top: 10,),
              child: Column(
                children: reply.replies.map((subReply) {
                  return Padding(
                    padding:  EdgeInsets.only(right:
                    Localization.textDirection==TextDirection.rtl?20.0:0.0,
                  ),
                    child: ReplyWidget(reply: subReply),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

