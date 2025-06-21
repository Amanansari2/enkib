import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart' hide FontSize;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {

  bool isLoading = true;
  Map<String, dynamic>? privacyPolicy;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchPrivacyPolicyData();
  }

  void fetchPrivacyPolicyData() async {
    try{
      final data = await getPrivacyPolicy();
      setState(() {
        privacyPolicy = data ;
        isLoading = false;
      });
    } catch(e){
      print("Error : $e");
      showCustomToast(context, "Error : $e", false);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Container(
            color: AppColors.whiteColor,
            child: AppBar(
              backgroundColor: AppColors.whiteColor,
              forceMaterialTransparency: true,
              elevation: 0,
              titleSpacing: 0,
              title: Text(
                "Privacy-Policy",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: 20,
                  fontFamily: 'SF-Pro-text',
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal
                ),
              ),
              leading: Padding(
                  padding: const EdgeInsets.only(top: 3),
                child: IconButton(
                    onPressed: (){
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.arrow_back_ios,
                    size: 20, color: AppColors.blackColor,
                    )
                ),
              ),
            ),
          )
      ),

      body: isLoading
      ? Center(child: SpinKitCircle(
        color: AppColors.primaryGreen(context),
        size: 200,
      ),)
          :SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 20, 5, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              privacyPolicy!['heading']??'',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10,),

            Html(
              data : privacyPolicy!['paragraph']??'',
              style:{
                "h2" : Style(fontSize: FontSize.large),
                "p" : Style(fontSize: FontSize.medium),
              }
            )
          ],
        ),
      )

    );
  }
}
