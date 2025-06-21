import 'package:flutter/material.dart';
import 'package:flutter_projects/localization/localization.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> subjects;
  final List<String> languages;
  final List<Map<String, dynamic>> location;
  final List<String> subjectGroups;
  final String? selectedSubjectGroup;
  final int? selectedCountryId;
  final String? keyword;
  final double? maxPrice;
  final String? sessionType;
  final List<int>? subjectIds;
  final List<int>? languageIds;

  final Function(String) onSubjectGroupSelected;
  final Function(int) onCountrySelected;
  final Function({
    String? keyword,
    double? maxPrice,
    int? country,
    int? groupId,
    String? sessionType,
    List<int>? subjectIds,
    List<int>? languageIds,
  }) onApplyFilters;

  FilterBottomSheet({
    required this.subjects,
    required this.languages,
    required this.location,
    required this.subjectGroups,
    this.selectedSubjectGroup,
    this.selectedCountryId,
    this.keyword,
    this.maxPrice,
    this.sessionType,
    this.subjectIds,
    this.languageIds,
    required this.onSubjectGroupSelected,
    required this.onCountrySelected,
    required this.onApplyFilters,
  });

  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> selectedSubjects;
  late List<String> selectedLanguages;
  late String? selectedSubjectGroup;
  late int? selectedCountryId;
  late String? keyword;
  late double maxPrice;
  late String? sessionType;

  final TextEditingController _keywordController = TextEditingController();

  bool showAllSelectedSubjects = false;
  bool showAllSelectedLanguages = false;

  final double _minFee = 0;
  final double _maxFee = 500;
  double _currentMinFee = 0;

  List<String> sessionTypes = [
    "${Localization.translate("all_sessions")}",
    "${Localization.translate("private")}",
    "${Localization.translate("group")}"
  ];
  int selectedSessionTypeIndex = -1;

  @override
  void initState() {
    super.initState();
    selectedSubjects =
        widget.subjectIds?.map((id) => widget.subjects[id - 1]).toList() ?? [];
    selectedLanguages =
        widget.languageIds?.map((id) => widget.languages[id - 1]).toList() ??
            [];
    selectedSubjectGroup = widget.selectedSubjectGroup;
    selectedCountryId = widget.selectedCountryId;
    keyword = widget.keyword;
    maxPrice = widget.maxPrice ?? 0;

    if (keyword != null) {
      _keywordController.text = keyword!;
    }

    _currentMinFee = widget.maxPrice ?? _minFee;

    sessionType = null;
    selectedSessionTypeIndex = -1;

    if (widget.sessionType != null) {
      sessionType = widget.sessionType;
      switch (widget.sessionType) {
        case "one":
          selectedSessionTypeIndex =
              sessionTypes.indexOf("${Localization.translate("private")}");
          break;
        case "group":
          selectedSessionTypeIndex =
              sessionTypes.indexOf("${Localization.translate("group")}");
          break;
        default:
          selectedSessionTypeIndex = -1;
          sessionType = null;
      }
    }
  }

  void _clearFilters() {
    setState(() {
      selectedSubjects.clear();
      selectedLanguages.clear();
      selectedSubjectGroup = null;
      selectedCountryId = null;
      sessionType = null;
      selectedSessionTypeIndex = -1;
      _currentMinFee = _minFee;
      keyword = null;
      _keywordController.clear();
    });

    widget.onApplyFilters(
      keyword: null,
      maxPrice: null,
      country: null,
      groupId: null,
      sessionType: null,
      subjectIds: [],
      languageIds: [],
    );

    Navigator.pop(context);
  }

  void _applyFilters() {
    if (selectedSessionTypeIndex != -1) {
      sessionType = (selectedSessionTypeIndex ==
              sessionTypes.indexOf("${Localization.translate("private")}"))
          ? "one"
          : (selectedSessionTypeIndex ==
                  sessionTypes.indexOf("${Localization.translate("group")}"))
              ? "group"
              : null;
    }

    widget.onApplyFilters(
      keyword:
          _keywordController.text.isNotEmpty ? _keywordController.text : null,
      maxPrice: _currentMinFee > 0 ? _currentMinFee : null,
      country: selectedCountryId,
      groupId: selectedSubjectGroup != null
          ? widget.subjectGroups.indexOf(selectedSubjectGroup!) + 1
          : null,
      sessionType: sessionType,
      subjectIds: selectedSubjects
          .map((subject) => widget.subjects.indexOf(subject) + 1)
          .toList(),
      languageIds: selectedLanguages
          .map((language) => widget.languages.indexOf(language) + 1)
          .toList(),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  bool _hasActiveFilters() {
    return selectedSubjects.isNotEmpty ||
        selectedLanguages.isNotEmpty ||
        selectedSubjectGroup != null ||
        selectedCountryId != null ||
        (keyword != null && keyword!.isNotEmpty) ||
        maxPrice > 0 ||
        sessionType != null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        height: 470,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: const BoxDecoration(
          color: AppColors.sheetBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                decoration: BoxDecoration(
                  color: AppColors.topBottomSheetDismissColor,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Localization.translate("search_tutor"),
                  style: TextStyle(
                    fontSize: FontSize.scale(context, 18),
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFontFamily.font,
                  ),
                ),
                if (_hasActiveFilters())
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Text(
                      Localization.translate("clear"),
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.font,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 25),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _keywordController,
                      cursorColor: AppColors.greyColor(context),
                      decoration: InputDecoration(
                       // hintText: Localization.translate('search_keyword'),
                        hintText: "Search with Tutor Name",
                        hintStyle: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize: FontSize.scale(context, 16),
                          fontFamily: AppFontFamily.font,
                          fontWeight: FontWeight.w400,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 15),
                        suffixIcon: SvgPicture.asset(AppImages.search,
                            color: AppColors.greyColor(context),
                            width: 10,
                            height: 15,
                            fit: BoxFit.scaleDown),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // _buildSegmentedControl(),
                    // const SizedBox(height: 20),
                    // _buildSection(
                    //   title: Localization.translate("subjects"),
                    //   items: widget.subjects,
                    //   selectedItems: selectedSubjects,
                    //   onItemsSelected: (subjects) {
                    //     setState(() {
                    //       selectedSubjects = subjects;
                    //     });
                    //   },
                    //   showAllItems: showAllSelectedSubjects,
                    //   showAllItemsChanged: (value) {
                    //     setState(() {
                    //       showAllSelectedSubjects = value;
                    //     });
                    //   },
                    // ),
                    // const SizedBox(height: 20),
                    // _buildSingleSelectSectionForStrings(
                    //   title: Localization.translate("subject_group"),
                    //   items: widget.subjectGroups,
                    //   selectedItem: selectedSubjectGroup,
                    //   onItemSelected: (selectedGroup) {
                    //     setState(() {
                    //       selectedSubjectGroup = selectedGroup;
                    //     });
                    //   },
                    // ),
                    // const SizedBox(height: 20),
                    // _buildSection(
                    //   title: Localization.translate("language"),
                    //   items: widget.languages,
                    //   selectedItems: selectedLanguages,
                    //   onItemsSelected: (languages) {
                    //     setState(() {
                    //       selectedLanguages = languages;
                    //     });
                    //   },
                    //   showAllItems: showAllSelectedLanguages,
                    //   showAllItemsChanged: (value) {
                    //     setState(() {
                    //       showAllSelectedLanguages = value;
                    //     });
                    //   },
                    // ),
                    // const SizedBox(height: 20),
                    Text(
                      Localization.translate("fee_session"),
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.font,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Slider(
                            value: _currentMinFee,
                            min: _minFee,
                            max: _maxFee,
                            divisions: 50,
                            activeColor: AppColors.primaryGreen(context),
                            inactiveColor: AppColors.dividerColor,
                            onChanged: (double value) {
                              setState(() {
                                _currentMinFee = value.roundToDouble();
                              });
                            },
                          ),
                          _buildFeeDisplay(_currentMinFee, context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // _buildSingleSelectSection(
                    //   title: Localization.translate("location"),
                    //   items: widget.location,
                    //   selectedItemId: selectedCountryId,
                    //   onItemSelected: (countryId) {
                    //     setState(() {
                    //       selectedCountryId = countryId;
                    //     });
                    //   },
                    // ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen(context),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                Localization.translate("apply_filter"),
                style: TextStyle(
                  fontSize: FontSize.scale(context, 16),
                  color: AppColors.whiteColor,
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSelectSectionForStrings({
    required String title,
    required List<String> items,
    required String? selectedItem,
    required Function(String?) onItemSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 14),
                fontFamily: AppFontFamily.font,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (selectedItem != null)
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: AppColors.sheetBackgroundColor,
                    context: context,
                    builder: (BuildContext context) {
                      return _SingleSelectionBottomSheetForStrings(
                        title: title,
                        items: items,
                        selectedItem: selectedItem,
                        onItemSelected: (selected) {
                          setState(() {
                            onItemSelected(selected);
                          });
                        },
                      );
                    },
                  );
                },
                child: Text(
                  '${Localization.translate("select")} $title',
                  style: TextStyle(
                    color: AppColors.primaryGreen(context),
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.font,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedItem != null)
          Container(
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                selectedItem,
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w400,
                ),
              ),
              trailing: Transform.translate(
                offset: Localization.textDirection == TextDirection.rtl
                    ? Offset(-20, 0)
                    : Offset(15, 0),
                child: IconButton(
                  splashColor: Colors.transparent,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.greyColor(context),
                  ),
                  onPressed: () {
                    setState(() {
                      onItemSelected(null);
                    });
                  },
                ),
              ),
            ),
          ),
        if (selectedItem == null)
          OutlinedButton(
            onPressed: () {
              showModalBottomSheet(
                backgroundColor: AppColors.sheetBackgroundColor,
                context: context,
                builder: (BuildContext context) {
                  return _SingleSelectionBottomSheetForStrings(
                    title: title,
                    items: items,
                    selectedItem: selectedItem,
                    onItemSelected: (selected) {
                      setState(() {
                        onItemSelected(selected);
                      });
                    },
                  );
                },
              );
            },
            child: Text(
              '${Localization.translate("select")} $title ${Localization.translate("from_list")}',
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontFamily: AppFontFamily.font,
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              elevation: 1,
              side: BorderSide(color: AppColors.whiteColor, width: 0.2),
              shadowColor: AppColors.greyColor(context).withOpacity(0.2),
              backgroundColor: AppColors.whiteColor,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onItemsSelected,
    required bool showAllItems,
    required Function(bool) showAllItemsChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 14),
                fontFamily: AppFontFamily.font,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (selectedItems.isNotEmpty)
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: AppColors.sheetBackgroundColor,
                    context: context,
                    builder: (BuildContext context) {
                      return _SelectionBottomSheet(
                        items: items,
                        selectedItems: selectedItems,
                        onItemsSelected: onItemsSelected,
                        title: title,
                      );
                    },
                  );
                },
                child: Text(
                  '${Localization.translate("select")} $title',
                  style: TextStyle(
                    color: AppColors.primaryGreen(context),
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.font,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedItems.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
              borderRadius: BorderRadius.circular(8.0),
              color: AppColors.whiteColor,
            ),
            child: Column(
              children: [
                for (var item in showAllItems
                    ? selectedItems
                    : selectedItems.take(5).toList())
                  Column(
                    children: [
                      ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 16),
                            fontFamily: AppFontFamily.font,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        trailing: Transform.translate(
                          offset:
                          Localization.textDirection == TextDirection.rtl
                              ? Offset(-20, 0)
                              : Offset(15, 0),
                          child: IconButton(
                            splashColor: Colors.transparent,
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: AppColors.greyColor(context),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedItems.remove(item);
                              });
                            },
                          ),
                        ),
                      ),
                      if (item !=
                          (showAllItems
                              ? selectedItems.last
                              : selectedItems.take(5).last))
                        Divider(
                          color: AppColors.dividerColor,
                          height: 0,
                          thickness: 0.5,
                          indent: 24,
                          endIndent: 24,
                        ),
                    ],
                  ),
                if (selectedItems.length > 5 && !showAllItems)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: OutlinedButton(
                      onPressed: () {
                        showAllItemsChanged(true);
                      },
                      child: Text(
                        '${Localization.translate("load_more")}',
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontFamily: AppFontFamily.font,
                          fontSize: FontSize.scale(context, 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: AppColors.greyFadeColor,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                if (selectedItems.length > 1) const SizedBox(height: 2),
              ],
            ),
          ),
        if (selectedItems.isEmpty)
          OutlinedButton(
            onPressed: () {
              showModalBottomSheet(
                backgroundColor: AppColors.sheetBackgroundColor,
                context: context,
                builder: (BuildContext context) {
                  return _SelectionBottomSheet(
                    items: items,
                    selectedItems: selectedItems,
                    onItemsSelected: onItemsSelected,
                    title: title,
                  );
                },
              );
            },
            child: Text(
              '${Localization.translate("select")} $title ${Localization.translate("from_list")}',
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontFamily: AppFontFamily.font,
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              elevation: 1,
              side: BorderSide(color: AppColors.whiteColor, width: 0.2),
              shadowColor: AppColors.greyColor(context).withOpacity(0.2),
              backgroundColor: AppColors.whiteColor,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleSelectSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required int? selectedItemId,
    required Function(int?) onItemSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontSize: FontSize.scale(context, 14),
                fontFamily: AppFontFamily.font,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (selectedItemId != null)
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: AppColors.sheetBackgroundColor,
                    context: context,
                    builder: (BuildContext context) {
                      return _SingleSelectionBottomSheet(
                        title: title,
                        items: items,
                        selectedItemId: selectedItemId,
                        onItemSelected: onItemSelected,
                      );
                    },
                  );
                },
                child: Text(
                  '${Localization.translate("select")} $title',
                  style: TextStyle(
                    color: AppColors.primaryGreen(context),
                    fontSize: FontSize.scale(context, 14),
                    fontFamily: AppFontFamily.font,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedItemId != null)
          Container(
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                items.firstWhere(
                    (country) => country['id'] == selectedItemId)['name'],
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w400,
                ),
              ),
              trailing: Transform.translate(
                offset: Localization.textDirection == TextDirection.rtl
                    ? Offset(-20, 0)
                    : Offset(15, 0),
                child: IconButton(
                  splashColor: Colors.transparent,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.greyColor(context),
                  ),
                  onPressed: () {
                    setState(() {
                      onItemSelected(null);
                    });
                  },
                ),
              ),
            ),
          ),
        if (selectedItemId == null)
          OutlinedButton(
            onPressed: () {
              showModalBottomSheet(
                backgroundColor: AppColors.sheetBackgroundColor,
                context: context,
                builder: (BuildContext context) {
                  return _SingleSelectionBottomSheet(
                    title: title,
                    items: items,
                    selectedItemId: selectedItemId,
                    onItemSelected: onItemSelected,
                  );
                },
              );
            },
            child: Text(
              '${Localization.translate("select")} $title ${Localization.translate("from_list")}',
              style: TextStyle(
                color: AppColors.greyColor(context),
                fontFamily: AppFontFamily.font,
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              elevation: 1,
              side: BorderSide(color: AppColors.whiteColor, width: 0.2),
              shadowColor: AppColors.greyColor(context).withOpacity(0.2),
              backgroundColor: AppColors.whiteColor,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(sessionTypes.length, (index) {
          bool isSelected = selectedSessionTypeIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selectedSessionTypeIndex == index) {
                  selectedSessionTypeIndex = -1;
                  sessionType = null;
                } else {
                  selectedSessionTypeIndex = index;
                  sessionType = (index == sessionTypes.indexOf("Private"))
                      ? "one"
                      : "group";
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: 10, horizontal: isSelected ? 25 : 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.greyFadeColor : AppColors.whiteColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                sessionTypes[index],
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 14),
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFontFamily.font,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SingleSelectionBottomSheetForStrings extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedItem;
  final Function(String?) onItemSelected;

  _SingleSelectionBottomSheetForStrings({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  __SingleSelectionBottomSheetForStringsState createState() =>
      __SingleSelectionBottomSheetForStringsState();
}

class __SingleSelectionBottomSheetForStringsState
    extends State<_SingleSelectionBottomSheetForStrings> {
  String? _selectedItem;
  TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
    _filteredItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: const BoxDecoration(
          color: AppColors.sheetBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                decoration: BoxDecoration(
                  color: AppColors.topBottomSheetDismissColor,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontFamily: AppFontFamily.font,
                    fontSize: FontSize.scale(context, 18),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedItem = null;
                    });
                    widget.onItemSelected(null);
                  },
                  child: Text(
                    '${Localization.translate("clear")}',
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.font,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _filterItems,
              cursorColor: AppColors.greyColor(context),
              decoration: InputDecoration(
                hintText: '${Localization.translate("search")} ${widget.title}',
                hintStyle: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                suffixIcon: SvgPicture.asset(AppImages.search,
                    width: 10, height: 15, fit: BoxFit.scaleDown),
                suffixIconColor: AppColors.greyColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.whiteColor,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(8.0),
                  color: AppColors.whiteColor,
                ),
                child: ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final isSelected = _selectedItem == item;
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                            });
                            widget.onItemSelected(item);
                            Navigator.pop(context);
                          },
                          title: Text(
                            item,
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: AppFontFamily.font,
                            ),
                          ),
                          trailing: Transform.scale(
                            scale: 1.35,
                            child: Checkbox(
                              value: isSelected,
                              side: BorderSide(color: AppColors.dividerColor),
                              activeColor: AppColors.primaryGreen(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5.0),
                                ),
                              ),
                              onChanged: (bool? selected) {
                                setState(() {
                                  _selectedItem =
                                      selected == true ? item : null;
                                });
                                widget.onItemSelected(item);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        if (index < _filteredItems.length - 1)
                          Divider(
                            color: AppColors.dividerColor,
                            height: 1,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SingleSelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final int? selectedItemId;
  final Function(int) onItemSelected;

  _SingleSelectionBottomSheet({
    required this.title,
    required this.items,
    required this.selectedItemId,
    required this.onItemSelected,
  });

  @override
  __SingleSelectionBottomSheetState createState() =>
      __SingleSelectionBottomSheetState();
}

class __SingleSelectionBottomSheetState
    extends State<_SingleSelectionBottomSheet> {
  int? _selectedItemId;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItemId = widget.selectedItemId;
    _filteredItems.addAll(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) =>
                item['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: const BoxDecoration(
          color: AppColors.sheetBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                decoration: BoxDecoration(
                  color: AppColors.topBottomSheetDismissColor,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontFamily: AppFontFamily.font,
                    fontSize: FontSize.scale(context, 18),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedItemId = null;
                    });
                  },
                  child: Text(
                    '${Localization.translate("clear")}',
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.font,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _filterItems,
              cursorColor: AppColors.greyColor(context),
              decoration: InputDecoration(
                hintText: '${Localization.translate("search")} ${widget.title}',
                hintStyle: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                suffixIcon: SvgPicture.asset(AppImages.search,
                    width: 10, height: 15, fit: BoxFit.scaleDown),
                suffixIconColor: AppColors.greyColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.whiteColor,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(8.0),
                  color: AppColors.whiteColor,
                ),
                child: ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final isSelected = _selectedItemId == item['id'];
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            setState(() {
                              _selectedItemId = item['id'];
                            });
                            widget.onItemSelected(item['id']);
                            Navigator.pop(context);
                          },
                          title: Text(
                            item['name'],
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: AppFontFamily.font,
                            ),
                          ),
                          trailing: Transform.scale(
                            scale: 1.35,
                            child: Checkbox(
                              value: isSelected,
                              side: BorderSide(color: AppColors.dividerColor),
                              activeColor: AppColors.primaryGreen(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5.0),
                                ),
                              ),
                              onChanged: (bool? selected) {
                                setState(() {
                                  _selectedItemId =
                                      selected == true ? item['id'] : null;
                                });
                                widget.onItemSelected(item['id']);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        if (index < _filteredItems.length - 1)
                          Divider(
                            color: AppColors.dividerColor,
                            height: 1,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SelectionBottomSheet extends StatefulWidget {
  final List<String> items;
  final List<String> selectedItems;
  final Function(List<String>) onItemsSelected;
  final String title;

  _SelectionBottomSheet({
    required this.items,
    required this.selectedItems,
    required this.onItemsSelected,
    required this.title,
  });

  @override
  __SelectionBottomSheetState createState() => __SelectionBottomSheetState();
}

class __SelectionBottomSheetState extends State<_SelectionBottomSheet> {
  Set<String> _selectedItems = {};
  TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.selectedItems);
    _filteredItems.addAll(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: const BoxDecoration(
          color: AppColors.sheetBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                decoration: BoxDecoration(
                  color: AppColors.topBottomSheetDismissColor,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.title}',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontFamily: AppFontFamily.font,
                    fontSize: FontSize.scale(context, 18),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedItems.clear();
                    });
                  },
                  child: Text(
                    '${Localization.translate("clear")}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 14),
                      fontFamily: AppFontFamily.font,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _filterItems,
              cursorColor: AppColors.greyColor(context),
              decoration: InputDecoration(
                hintText: '${Localization.translate("search")} ${widget.title}',
                hintStyle: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                suffixIcon: SvgPicture.asset(AppImages.search,
                    width: 10, height: 10, fit: BoxFit.none),
                suffixIconColor: AppColors.greyColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.whiteColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 9,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(8.0),
                  color: AppColors.whiteColor,
                ),
                child: ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final isSelected = _selectedItems.contains(item);
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedItems.remove(item);
                              } else {
                                _selectedItems.add(item);
                              }
                            });
                          },
                          title: Text(
                            item,
                            style: TextStyle(
                              color: AppColors.greyColor(context),
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: AppFontFamily.font,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          trailing: Transform.scale(
                            scale: 1.35,
                            child: Checkbox(
                              side: BorderSide(color: AppColors.dividerColor),
                              activeColor: AppColors.primaryGreen(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5.0),
                                ),
                              ),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value != null) {
                                    if (value) {
                                      _selectedItems.add(item);
                                    } else {
                                      _selectedItems.remove(item);
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        Divider(
                          color: AppColors.dividerColor,
                          height: 0,
                          thickness: 0.5,
                          indent: 24,
                          endIndent: 24,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selectedItems.isNotEmpty
                  ? () {
                      widget.onItemsSelected(_selectedItems.toList());
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedItems.isNotEmpty
                    ? AppColors.primaryGreen(context)
                    : AppColors.fadeColor,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                '${Localization.translate("select")} ${widget.title}',
                style: TextStyle(
                  fontSize: FontSize.scale(context, 16),
                  color: AppColors.whiteColor,
                  fontFamily: AppFontFamily.font,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

Widget _buildFeeDisplay(double fee, BuildContext context) {
  return Container(
    width: 150,
    padding: EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.fadeColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          '${fee.round()}',
          style: TextStyle(
            color: AppColors.greyColor(context),
            fontSize: 16,
            fontFamily: AppFontFamily.font,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '₹',
          style: TextStyle(
            color: AppColors.blackColor.withOpacity(0.20),
            fontSize: 18,
            fontFamily: AppFontFamily.font,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}
