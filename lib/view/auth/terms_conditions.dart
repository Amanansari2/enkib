import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart' hide FontSize;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {

  bool isLoading = true;
  Map<String, dynamic>?termsConditions;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchTermConditionData();
  }

  void fetchTermConditionData() async{
    try{
      final data = await getTermsConditions();
      
      setState(() {
        termsConditions = data;
        isLoading = false;
      });
      
    } catch(e){
      print("Error : $e");
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
          preferredSize: Size.fromHeight(70.0), 
          child: Container(
            color: AppColors.whiteColor,
            child: Padding(
                padding: EdgeInsets.only(top: 10),
              child: AppBar(
                backgroundColor: AppColors.whiteColor,
                forceMaterialTransparency: true,
                titleSpacing: 0,
                elevation: 0,
                title: Text(
                  'Terms & Conditions',
                      textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 20,
                    fontFamily: 'SF-Pro-Text',
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
                      ),
                    padding: EdgeInsets.zero,
                  ),
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
              termsConditions!['heading'] ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10,),
            Html(
              data: termsConditions!['paragraph']??'',
              style: {
                "h2" : Style(fontSize: FontSize.large),
                "p" : Style(fontSize: FontSize.medium),
              },
            )
          ],
        ),
      )
      ,

    );
  }
}
