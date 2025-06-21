import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shimmer/shimmer.dart';

class CommunityPageSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(left: 15, right: 15.0,bottom: 20,top: 20),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
              ),
            ),
            child: Container(
              padding: EdgeInsets.only(left: 20.0, top: 30, right: 20, bottom: 20.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(height: 20, width: 350),
                  SizedBox(height: 8),
                  _shimmerBox(height: 20, width: 100),
                  SizedBox(height: 20),
                  _shimmerBox(height: 14, width: double.infinity),
                  SizedBox(height: 8),
                  _shimmerBox(height: 20, width: 300),
                  SizedBox(height: 8),
                  _shimmerBox(height: 20, width: 100),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _shimmerBox(
                        height: 50,
                        width: MediaQuery.of(context).size.width - 155,
                        borderRadius: 10,
                      ),
                      _shimmerBox(
                        height: 50,
                        width: 50,
                        borderRadius: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10.0),
            child: _shimmerBox(height: 20, width: 80),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 1.0),
            child: _shimmerBox(height: 20, width: double.infinity),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 1.0),
            child: _shimmerBox(height: 20, width: 150),
          ),
          SizedBox(height: 20),
          _buildSkeletonSection(context, 3),
          SizedBox(height: 10),
          _buildSkeletonSection(context, 2),
          SizedBox(height: 10),
          _buildSkeletonSection(context, 2),
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

  Widget _buildSkeletonSection(BuildContext context, int itemCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _shimmerBox(
            height: 20,
            width: 60,
            borderRadius: 8,
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return _buildSkeletonForumCard(context);
          },
        ),
      ],
    );
  }

  Widget _buildSkeletonForumCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5,vertical: 8),
              child: _shimmerBox(
                height: 100,
                width: 100,
                borderRadius: 10,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(height: 20, width: 150),
                    SizedBox(height: 8),
                    _shimmerBox(height: 14, width: double.infinity),
                    SizedBox(height: 30),
                    Row(
                      children: [
                        _shimmerBox(height: 20, width: 20),
                        SizedBox(
                          width: 10,
                        ),
                        _shimmerBox(height: 14, width: 50),
                        SizedBox(width: 16),
                        _shimmerBox(height: 20, width: 20),
                        SizedBox(
                          width: 10,
                        ),
                        _shimmerBox(height: 14, width: 50),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
