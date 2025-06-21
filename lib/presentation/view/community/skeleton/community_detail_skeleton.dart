import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shimmer/shimmer.dart';

class CommunityDetailSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
              child: Stack(
                children: [
                  _shimmerBox(
                      height: 180, width: double.infinity, borderRadius: 12),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _shimmerBox(height: 20, width: 150),
                        SizedBox(height: 8),
                        _shimmerBox(height: 14, width: 350),
                        SizedBox(height: 8),
                        _shimmerBox(height: 14, width: 100),
                        SizedBox(height: 40),
                        _shimmerBox(height: 45, width: 350, borderRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),
          SectionCardSkeleton(
              isCircularImages: false),
          SizedBox(height: 10),
          SectionCardSkeleton(isCircularImages: true),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child:
                _shimmerBox(height: 20, width: 80),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: _shimmerBox(
                height: 14,
                width: double.infinity),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: _shimmerBox(
                height: 40,
                width: double.infinity,
                borderRadius: 8),
          ),
          SizedBox(height: 10),
          _buildSkeletonTabs(context),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: _shimmerBox(
                height: 20,
                width: 50,
                borderRadius: 8),
          ),
          SizedBox(height: 5),
          ...List.generate(
            4,
            (index) => _buildSkeletonPostCard(context),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double borderRadius = 4,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildSkeletonTabs(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: _shimmerBox(
                  height: 35, width: 450, borderRadius: 10),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: _shimmerBox(
                  height: 35, width: 450, borderRadius: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonPostCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _shimmerBox(
                      height: 180, width: double.infinity,borderRadius: 12),
                  Positioned(
                    bottom: -15,
                    left: 15,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _shimmerBox(height: 20, width: 100),
                  Spacer(),
                  _shimmerBox(height: 25, width: 80),
                ],
              )
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _shimmerBox(height: 14, width: 190),
                  Spacer(),
                  _shimmerBox(height: 14, width: 70),
                ],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _shimmerBox(height: 14, width: 70),
                  Spacer(),
                  _shimmerBox(height: 14, width: 70),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _shimmerBox(
                  height: 20, width: 120),
            ),
            SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _shimmerBox(
                  height: 14,
                  width: double.infinity),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class SectionCardSkeleton extends StatelessWidget {
  final bool isCircularImages;

  SectionCardSkeleton({this.isCircularImages = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isCircularImages
                ? SizedBox(
              width: 75,
              height: 40,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: List.generate(3, (index) {
                  return Positioned(
                    left: index * 18.0,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            )
                : SizedBox(
              width: 75,
              height: 70,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(3, (index) {
                  return Positioned(
                    top: index * 12.0,
                    left: index * 15.0,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.whiteColor,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[300]!.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shimmerBox(height: 20, width: 100),
                  SizedBox(height: 4),
                  _shimmerBox(height: 14, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double borderRadius = 4,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
