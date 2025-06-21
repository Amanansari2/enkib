import 'package:flutter_projects/presentation/view/components/skeleton/skeleton_card.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/provider/auth_provider.dart';


class TutorCardSkeleton extends StatelessWidget {
  final bool isFullWidth;
  final bool isDelete;

  const TutorCardSkeleton({this.isFullWidth = false, this.isDelete = false});

  @override
  Widget build(BuildContext context) {

    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? role = userData != null && userData['user'] != null
        ? userData['user']['role']
        : null;

    return Container(
      width: isFullWidth ? MediaQuery.of(context).size.width : 360,
      margin: EdgeInsets.only(right: isFullWidth ? 0 : 16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonCard(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonCard(
                            child: Container(
                              width: 100,
                              height: 15,
                              color: Colors.grey[300],
                            ),
                          ),
                          SizedBox(width: 10),
                          SkeletonCard(
                            child: Container(
                              width: 15,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          SkeletonCard(
                            child: Container(
                              width: 25,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      SkeletonCard(
                        child: Container(
                          width: 100,
                          height: 15,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                if (role == 'student')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0, right: 8.0),
                    child: isDelete
                        ? SkeletonCard(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(10)
                        ),
                      ),
                    )
                        : SkeletonCard(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            SkeletonCard(
              child: Container(
                width: 300,
                height: 12,
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: 8),
            SkeletonCard(
              child: Container(
                width: 200,
                height: 12,
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                SkeletonCard(
                  child: Container(
                    width: 16,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(width: 5),
                SkeletonCard(
                  child: Container(
                    width: 120,
                    height: 12,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Row(
                  children: [
                    SkeletonCard(
                      child: Container(
                        width: 16,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                    ),
                    SizedBox(width: 5),
                    SkeletonCard(
                      child: Container(
                        width: 120,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 60),
                Row(
                  children: [
                    SkeletonCard(
                      child: Container(
                        width: 16,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                    ),
                    SizedBox(width: 5),
                    SkeletonCard(
                      child: Container(
                        width: 100,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                SkeletonCard(
                  child: Container(
                    width: 16,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: SkeletonCard(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 12,
                      color: Colors.grey[300],
                    ),
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





