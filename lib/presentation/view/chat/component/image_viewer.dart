import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../data/localization/localization.dart';
import '../../../../styles/app_styles.dart';

class ImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewer({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor(context),
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          centerTitle: false,
          elevation: 0,
          titleSpacing: 0,
          title: Text(
            "${(Localization.translate('image_viewer') ?? '').trim() != 'image_viewer' && (Localization.translate('image_viewer') ?? '').trim().isNotEmpty ? Localization.translate('image_viewer') : 'Image Viewer'}",
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: FontSize.scale(context, 20),
              fontFamily: AppFontFamily.mediumFont,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading:IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: AppColors.blackColor,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body:PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        physics: BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final imagePath = images[index];

          if (imagePath.startsWith("http")) {
            return CachedNetworkImage(
              imageUrl: imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => SizedBox(
                width: 50,
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppColors.primaryGreen(context),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Image.asset(
                AppImages.placeHolderImage,
                fit: BoxFit.cover,
              ),
            );
          } else {
            return Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
            );
          }
        },
      ),
      ),
    );
  }
}
