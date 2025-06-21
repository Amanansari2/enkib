import 'package:flutter_projects/presentation/view/components/skeleton/skeleton_card.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/provider/auth_provider.dart';


class DisputeListingSkeleton extends StatelessWidget {


  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor(context).withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SkeletonCard(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              SkeletonCard(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SkeletonCard(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: 45,
                    height: 45,
                    color: Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonCard(
                    child: Container(
                      height: 16,
                      width: 100,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SkeletonCard(
                child: Container(
                  width: 15,
                  height: 15,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(width: 6),
              SkeletonCard(
                child: Container(
                  height: 14,
                  width: 270,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SkeletonCard(
                child: Container(
                  width: 15,
                  height: 15,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(width: 6),
              SkeletonCard(
                child: Container(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.7,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
        ],
      ),
    );

  }
}





