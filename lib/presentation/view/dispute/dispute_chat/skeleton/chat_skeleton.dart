import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerChatList extends StatelessWidget {
  const ShimmerChatList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Align(
            alignment: index.isEven ? Alignment.topRight : Alignment.topLeft,
            child: Column(
              crossAxisAlignment:
              index.isEven ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (index.isOdd)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerCircle(),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            _buildShimmerLine(width: 100, height: 15),
                            SizedBox(height: 8),
                            _buildShimmerBox(width: 200),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (index.isEven) _buildShimmerBox(width: 200),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: _buildShimmerLine(width: 70, height: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCircle() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 25,
          height: 25,
          color: AppColors.whiteColor,
        ),
      ),
    );
  }

  Widget _buildShimmerLine({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: AppColors.whiteColor,
        ),
      ),
    );
  }

  Widget _buildShimmerBox({double width = double.infinity, double height = 40}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: AppColors.whiteColor,
        ),
      ),
    );
  }
}
