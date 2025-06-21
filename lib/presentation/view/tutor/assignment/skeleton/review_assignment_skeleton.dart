import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../styles/app_styles.dart';

class ReviewAssignmentSkeleton extends StatelessWidget {
  const ReviewAssignmentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSectionSkeleton(context),
                SizedBox(height: 10),
                _buildDescriptionSkeleton(context),
                SizedBox(height: 10),
                _buildAnswerSkeleton(context),
                SizedBox(height: 10),
                _buildUploadedDocumentsSkeleton(context),
                SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
        _buildBottomButtonSkeleton(context),
      ],
    );
  }

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    double borderRadius = 4.0,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildProfileSectionSkeleton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShimmerContainer(width: 40, height: 40, borderRadius: 10),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildShimmerContainer(width: 120, height: 14),
                      SizedBox(height: 4),
                      _buildShimmerContainer(width: 150, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildShimmerContainer(width: double.infinity, height: 16),
            SizedBox(height: 8),
            _buildShimmerContainer(width: double.infinity * 0.7, height: 16),
            SizedBox(height: 16),
            Row(
              children: [
                _buildShimmerContainer(width: 15, height: 15, borderRadius: 4),
                SizedBox(width: 6),
                _buildShimmerContainer(width: 200, height: 14),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildShimmerContainer(
                      width: 15,
                      height: 15,
                      borderRadius: 4,
                    ),
                    SizedBox(width: 6),
                    _buildShimmerContainer(width: 150, height: 14),
                  ],
                ),
                Row(
                  children: [
                    _buildShimmerContainer(
                      width: 15,
                      height: 15,
                      borderRadius: 4,
                    ),
                    SizedBox(width: 6),
                    _buildShimmerContainer(width: 150, height: 14),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSkeleton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerContainer(width: 100, height: 16),
          SizedBox(height: 10),
          _buildShimmerContainer(width: double.infinity, height: 14),
          SizedBox(height: 6),
          _buildShimmerContainer(width: double.infinity, height: 14),
          SizedBox(height: 6),
          _buildShimmerContainer(width: double.infinity * 0.8, height: 14),
        ],
      ),
    );
  }

  Widget _buildAnswerSkeleton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.whiteColor),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerContainer(width: 90, height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.0, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        width: 20,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 12,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildShimmerContainer(
            width: double.infinity,
            height: 150,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedDocumentsSkeleton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerContainer(width: 90, height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.0, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        width: 20,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 12,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children: List.generate(3, (index) {
              return _buildAttachmentItemSkeleton(context);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItemSkeleton(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          _buildShimmerContainer(width: 20, height: 20, borderRadius: 4),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(width: 120, height: 14),
                SizedBox(height: 4),
                _buildShimmerContainer(width: 80, height: 12),
              ],
            ),
          ),
          _buildShimmerContainer(width: 20, height: 20, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildBottomButtonSkeleton(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.09,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 8,
            blurRadius: 10,
          ),
        ],
        color: AppColors.whiteColor,
        border: Border(
          top: BorderSide(color: AppColors.dividerColor, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: _buildShimmerContainer(
        width: double.infinity,
        height: 50,
        borderRadius: 12,
      ),
    );
  }
}
