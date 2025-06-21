import 'package:flutter/material.dart';
import '../../../../../styles/app_styles.dart';

class Contributors extends StatelessWidget {
  final String title;
  final List<String> imageUrls;

  Contributors({
    required this.title,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    double totalWidth =
    imageUrls.isEmpty ? 0 : 40 + (imageUrls.length - 1) * 18.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: totalWidth,
          height: 40,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: List.generate(imageUrls.length, (index) {
              return Positioned(
                left: index * 18.0,
                child: CircleAvatar(
                  radius: 20,
                  child:
                  imageUrls.isNotEmpty && imageUrls.length > index
                      ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(imageUrls[index]),
                  )
                      : ClipOval(
                    child: Image.asset(
                      AppImages.placeHolderImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Text(
          title,
          style: TextStyle(
            color: AppColors.greyColor(context),
            fontSize: FontSize.scale(context, 14),
            fontFamily: AppFontFamily.mediumFont,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
          ),
        ),
      ],
    );
  }
}
