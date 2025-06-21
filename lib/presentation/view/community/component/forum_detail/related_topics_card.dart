import 'package:flutter/material.dart';
import '../../../../../data/localization/localization.dart';
import '../../../../../styles/app_styles.dart';

class RelatedTopicsCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> imageUrls;

  RelatedTopicsCard({
    required this.title,
    required this.subtitle,
    required this.imageUrls,
  });

  @override
  _RelatedTopicsCardState createState() => _RelatedTopicsCardState();
}

class _RelatedTopicsCardState extends State<RelatedTopicsCard> {
  bool showAdditionalImages = false;

  @override
  Widget build(BuildContext context) {
    final displayedImages =
        showAdditionalImages
            ? widget.imageUrls
            : widget.imageUrls.take(3).toList();

    double totalWidth =
        widget.imageUrls.isEmpty
            ? 0
            : 40 + (widget.imageUrls.length - 1) * 18.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyColor(context).withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.imageUrls.length == 1
                    ? SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.imageUrls[0],
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Image.asset(
                                AppImages.placeHolderImage,
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    )
                    : SizedBox(
                      width: totalWidth,
                      height: 70,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: List.generate(displayedImages.length, (
                          index,
                        ) {
                          final bool isLast =
                              index == 2 &&
                              !showAdditionalImages &&
                              widget.imageUrls.length > 3;

                          return Positioned(
                            top: index * 12.0,
                            left:
                                Localization.textDirection == TextDirection.rtl
                                    ? (3 - index) * 18.0
                                    : index * 15.0,
                            child: GestureDetector(
                              onTap:
                                  isLast
                                      ? () {
                                        setState(() {
                                          showAdditionalImages = true;
                                        });
                                      }
                                      : null,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.whiteColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.greyColor(
                                        context,
                                      ).withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child:
                                      isLast
                                          ? Stack(
                                            children: [
                                              Image.network(
                                                widget.imageUrls[index],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Image.asset(
                                                      AppImages.placeHolderImage,
                                                      fit: BoxFit.cover,
                                                    ),
                                              ),
                                              Container(
                                                color: Colors.black.withOpacity(
                                                  0.6,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '+${widget.imageUrls.length - 3}',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.whiteColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                          : Image.network(
                                            displayedImages[index],
                                            fit: BoxFit.cover,
                                          ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                SizedBox(
                  width: Localization.textDirection == TextDirection.rtl? 10:5,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.mediumFont,
                          color: AppColors.blackColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: FontSize.scale(context, 14),
                          fontFamily: AppFontFamily.regularFont,
                          color: AppColors.greyColor(context),
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
    );
  }
}
