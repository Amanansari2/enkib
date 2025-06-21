import 'package:flutter/material.dart';
import 'package:flutter_projects/presentation/view/community/component/forum_detail/reply.dart';
import 'package:flutter_projects/presentation/view/community/component/forum_detail/reply_widget.dart';
import 'package:flutter_projects/presentation/view/community/component/utils/date_utils.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../data/localization/localization.dart';
import '../../../../../styles/app_styles.dart';

class CommentWidget extends StatefulWidget {
  final Map<String, dynamic> comment;

  const CommentWidget({
    Key? key,
    required this.comment,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}
class _CommentWidgetState extends State<CommentWidget> {
  bool showReplies = false;

  @override
  Widget build(BuildContext context) {
    final replies = (widget.comment['replies'] as List<dynamic>?)
        ?.map((reply) => Reply.fromMap(reply as Map<String, dynamic>))
        .toList() ??
        [];
    final creator = widget.comment['creator']?['profile'] ?? {};
    final firstName = creator['first_name'] ?? '';
    final lastName = creator['last_name'] ?? '';
    final imageUrl = creator['image'] ?? '';
    final description = widget.comment['description'] ?? '';
    final createdAt = widget.comment['created_at'] ?? '';
    final likesCount = widget.comment['likes_count']?.toString() ?? '0';

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
                '$firstName $lastName',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: FontSize.scale(context, 14),
                  fontFamily: AppFontFamily.mediumFont,
                  color: AppColors.blackColor,
                ),
              ),
              Spacer(),
              Text(
                createdAt.isNotEmpty ? formatTime(createdAt) : '',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: FontSize.scale(context, 12),
                  fontFamily: AppFontFamily.regularFont,
                  color: AppColors.greyColor(context),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48.0),
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
          if ((likesCount.isNotEmpty &&
              likesCount != '0') ||
              replies.isNotEmpty)
            _buildActionRow(replies.length, likesCount, context),
          if (showReplies)
            Padding(
              padding:  EdgeInsets.only(right: Localization.textDirection==TextDirection.rtl? 8.0:0.0,
              left:Localization.textDirection==TextDirection.ltr? 18.0:0.0),
              child: Column(
                children: replies.map((reply) {
                  return ReplyWidget(reply: reply);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
      int repliesCount, String? likesCount, BuildContext context) {
    return Padding(
      padding:  EdgeInsets.symmetric(
          horizontal: Localization.textDirection == TextDirection.rtl ? 10.0 : 40.0
          , vertical: 10.0,
      ),
      child: Row(
        children: [
          if (likesCount != null &&
              likesCount.isNotEmpty &&
              likesCount != '0') ...[
            const Icon(Icons.favorite, color: AppColors.redColor, size: 16),
            const SizedBox(width: 4),
            Text(
              likesCount,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: FontSize.scale(context, 12),
                fontFamily: AppFontFamily.regularFont,
                color: AppColors.greyColor(context).withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (repliesCount > 0)
            GestureDetector(
              onTap: () {
                setState(() {
                  showReplies = !showReplies;
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
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "$repliesCount",
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: FontSize.scale(context, 12),
                              fontFamily: AppFontFamily.regularFont,
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
                              fontSize: FontSize.scale(context, 12),
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
            ),
        ],
      ),
    );
  }
}
