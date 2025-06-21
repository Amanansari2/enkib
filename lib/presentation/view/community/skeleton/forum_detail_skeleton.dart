import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import '../../../../data/localization/localization.dart';

class ForumDetailSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _shimmerBox(height: 130, width: double.infinity),
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
                SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _shimmerBox(height: 14, width: 80),
                          _buildVoteSkeleton(),
                        ],
                      ),
                      SizedBox(height: 8),
                      _shimmerBox(height: 18, width: 150),
                      SizedBox(height: 4),
                      _shimmerBox(height: 20, width: double.infinity),
                      SizedBox(height: 20),
                      _shimmerBox(height: 14, width: 60),
                      SizedBox(height: 6),
                      _buildTagSkeleton(),
                      SizedBox(height: 10),
                      _buildContributorsSkeleton(),
                      SizedBox(height: 10),
                      _buildReplySkeleton(),
                      SizedBox(height: 10),
                      _buildActivitySkeleton(),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          SizedBox(height: 20),
          SectionCardSkeleton(),
          SizedBox(height: 10),
          _buildCommentSkeleton(),
          _buildCommentSkeleton(),
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
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }


  Widget _buildVoteSkeleton() {
    return
      Localization.textDirection==TextDirection.rtl?
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                ],
              ),
              border: Border.all(
                color: AppColors.whiteColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 10,
                width: 40,
                color: Colors.grey[300],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 10,
                width: 20,
                color: Colors.grey[300],
              ),
            ),
          ),
        ],
      )
      :Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(10),
            ),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: 20,
              color: Colors.grey[300],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
              ],
            ),
            border: Border.all(
              color: AppColors.whiteColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: 40,
              color: Colors.grey[300],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSkeleton() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(5, (index) {
        return _shimmerBox(height: 20, width: 80, borderRadius: 8);
      }),
    );
  }

  Widget _buildContributorsSkeleton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
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
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(width: 10),
        _shimmerBox(height: 20, width: 100),
      ],
    );
  }

  Widget _buildReplySkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          _shimmerBox(height: 14, width: 70),
          Spacer(),
          _shimmerBox(height: 14, width: 120),
        ],
      ),
    );
  }

  Widget _buildActivitySkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          _shimmerBox(height: 14, width: 150),
          Spacer(),
          _shimmerBox(height: 14, width: 100),
        ],
      ),
    );
  }

  Widget _buildCommentSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                SizedBox(width: 8),
                _shimmerBox(height: 20, width: 100),
                Spacer(),
                _shimmerBox(height: 14, width: 50),
              ],
            ),
            SizedBox(height: 8),
            _shimmerBox(height: 14, width: double.infinity),
            SizedBox(height: 10),
            _shimmerBox(height: 14, width: 200),
            SizedBox(height: 10),
            _shimmerBox(height: 14, width: 150),
            SizedBox(height: 10),
            Row(
              children: [
                _shimmerBox(height: 14, width: 40),
                SizedBox(width: 10),
                _shimmerBox(height: 14, width: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionCardSkeleton extends StatelessWidget {
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
          SizedBox(
          width: 75,
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(3, (index) {
              return Positioned(
                top: index * 12.0,
                left: Localization.textDirection == TextDirection.rtl
                    ? (3 - 1 - index) * 18.0
                    : index * 15.0,
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
                  _shimmerBox(height: 15, width: 100),
                  SizedBox(height: 4),
                  _shimmerBox(height: 15, width: double.infinity),
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

class FloatingActionButtonSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 50,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Container(
              height: 14,
              width: 60,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
