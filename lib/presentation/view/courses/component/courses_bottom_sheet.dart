import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../data/localization/localization.dart';

class CoursesBottomSheet extends StatefulWidget {
  final List<String> categories;
  final List<String> languages;
  final List<String> subjectGroups;
  final String? selectedSubjectGroup;
  final List<String> levels;

  final double? maxPrice;
  final List<int>? subjectIds;
  final List<int>? languageIds;
  final Map<String, dynamic> ratings;

  final Function(String) onSubjectGroupSelected;
  final Function({
    String? keyword,
    double? maxPrice,
    int? country,
    int? groupId,
    String? levelType,
    String? rating,
    String? priceType,
    List<int>? subjectIds,
    List<int>? languageIds,
    int? selectedPriceIndex,
  }) onApplyFilters;

  CoursesBottomSheet(
      {required this.categories,
      required this.languages,
      required this.subjectGroups,
      required this.levels,
      this.selectedSubjectGroup,
      this.maxPrice,
      this.subjectIds,
      this.languageIds,
      required this.onSubjectGroupSelected,
      required this.onApplyFilters,
      required this.ratings});

  @override
  _CoursesBottomSheetState createState() => _CoursesBottomSheetState();
}

class _CoursesBottomSheetState extends State<CoursesBottomSheet> {
  late List<String> selectedSubjects;
  late List<String> selectedLanguages;
  late String? selectedSubjectGroup;
  late double maxPrice;
  late List<String> levels;
  String? selectedLevel;
  int? _selectedPriceIndex;

  bool showAllSelectedSubjects = false;
  bool showAllSelectedLanguages = false;
  double _currentRating = 0.0;

  final double _minFee = 0;
  final double _maxFee = 500;
  double _currentMinFee = 0;

  void _togglePriceSelection(int index) {
    setState(() {
      _selectedPriceIndex = (_selectedPriceIndex == index) ? null : index;
    });
  }

  @override
  void initState() {
    super.initState();
    selectedSubjects =
        widget.subjectIds?.map((id) => widget.categories[id - 1]).toList() ??
            [];
    selectedLanguages =
        widget.languageIds?.map((id) => widget.languages[id - 1]).toList() ??
            [];
    selectedSubjectGroup = widget.selectedSubjectGroup;
    maxPrice = widget.maxPrice ?? 0;
    levels = widget.levels;

    _currentMinFee = widget.maxPrice ?? _minFee;
    selectedLevel = null;
    _selectedPriceIndex = null;
  }

  void _clearFilters() {
    setState(() {
      selectedSubjects.clear();
      selectedLanguages.clear();
      selectedSubjectGroup = null;
      _currentMinFee = _minFee;
    });

    widget.onApplyFilters(
      keyword: null,
      maxPrice: null,
      country: null,
      groupId: null,
      levelType: null,
      subjectIds: [],
      languageIds: [],
    );

    Navigator.pop(context);
  }

  void _applyFilters() {
    widget.onApplyFilters(
      maxPrice: _currentMinFee > 0 ? _currentMinFee : null,
      groupId: selectedSubjectGroup != null
          ? widget.subjectGroups.indexOf(selectedSubjectGroup!) + 1
          : null,
      subjectIds: selectedSubjects
          .map((subject) => widget.categories.indexOf(subject) + 1)
          .toList(),
      languageIds: selectedLanguages
          .map((language) => widget.languages.indexOf(language) + 1)
          .toList(),
      levelType: selectedLevel,
      rating: _currentRating >= 1.0 ? _currentRating.toStringAsFixed(1) : null,
      priceType: _selectedPriceIndex == 0
          ? "paid"
          : _selectedPriceIndex == 1
              ? "all"
              : null,
      selectedPriceIndex: _selectedPriceIndex,
    );
    Navigator.pop(context);
  }

  bool _hasActiveFilters() {
    return selectedSubjects.isNotEmpty ||
        selectedLanguages.isNotEmpty ||
        selectedSubjectGroup != null ||
        maxPrice > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localization.textDirection,
      child: Container(
        height: 600,
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
                  '${(Localization.translate('search_course') ?? '').trim() != 'search_course' && (Localization.translate('search_course') ?? '').trim().isNotEmpty ? Localization.translate('search_course') : 'Search Course'}',
                  style: TextStyle(
                    fontSize: FontSize.scale(context, 18),
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFontFamily.mediumFont,
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
                        fontFamily: AppFontFamily.regularFont,
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
                    _buildSection(
                      title:
                          "${(Localization.translate('category') ?? '').trim() != 'category' && (Localization.translate('category') ?? '').trim().isNotEmpty ? Localization.translate('category') : 'Category'}",
                      items: widget.categories,
                      selectedItems: selectedSubjects,
                      onItemsSelected: (subjects) {
                        setState(() {
                          selectedSubjects = subjects;
                        });
                      },
                      showAllItems: showAllSelectedSubjects,
                      showAllItemsChanged: (value) {
                        setState(() {
                          showAllSelectedSubjects = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${(Localization.translate('ratings') ?? '').trim() != 'ratings' && (Localization.translate('ratings') ?? '').trim().isNotEmpty ? Localization.translate('ratings') : 'Ratings'}",
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.mediumFont,
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
                          SizedBox(height: 10),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: CustomRatingThumb(context),
                              trackHeight: 3,
                              activeTrackColor: AppColors.primaryGreen(context),
                              inactiveTrackColor: AppColors.dividerColor,
                              trackShape: RoundedRectSliderTrackShape(),
                              overlayShape:
                                  RoundSliderOverlayShape(overlayRadius: 0),
                            ),
                            child: Slider(
                              value: _currentRating,
                              min: 0.0,
                              max: 5.0,
                              divisions: 4,
                              onChanged: (double value) {
                                setState(() {
                                  _currentRating = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 16),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(5, (index) {
                                return ratingLabel(context,
                                    "${(index + 1).toDouble().toStringAsFixed(1)}");
                              }),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSingleSelectSectionForStrings(
                      title:
                          "${(Localization.translate('course_duration') ?? '').trim() != 'course_duration' && (Localization.translate('course_duration') ?? '').trim().isNotEmpty ? Localization.translate('course_duration') : 'Course Duration'}",
                      items: widget.subjectGroups,
                      selectedItem: selectedSubjectGroup,
                      onItemSelected: (selectedGroup) {
                        setState(() {
                          selectedSubjectGroup = selectedGroup;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSingleSelectSectionForStrings(
                      title:
                          "${(Localization.translate('level') ?? '').trim() != 'level' && (Localization.translate('level') ?? '').trim().isNotEmpty ? Localization.translate('level') : 'Level'}",
                      items: levels,
                      selectedItem: selectedLevel,
                      onItemSelected: (selected) {
                        setState(() {
                          selectedLevel = selected;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${(Localization.translate('price') ?? '').trim() != 'price' && (Localization.translate('price') ?? '').trim().isNotEmpty ? Localization.translate('price') : 'Price'}",
                      style: TextStyle(
                        color: AppColors.greyColor(context),
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: AppFontFamily.mediumFont,
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
                          Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: AppColors.fadeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildToggleButton(
                                    "${(Localization.translate('paid') ?? '').trim() != 'paid' && (Localization.translate('paid') ?? '').trim().isNotEmpty ? Localization.translate('paid') : 'Paid'}",
                                    0,
                                    _selectedPriceIndex,
                                    context,
                                    _togglePriceSelection),
                                _buildToggleButton(
                                    "${(Localization.translate('all') ?? '').trim() != 'all' && (Localization.translate('all') ?? '').trim().isNotEmpty ? Localization.translate('all') : 'All'}",
                                    1,
                                    _selectedPriceIndex,
                                    context,
                                    _togglePriceSelection),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: CustomRatingThumb(context),
                              trackHeight: 3,
                              activeTrackColor: AppColors.primaryGreen(context),
                              inactiveTrackColor: AppColors.dividerColor,
                              trackShape: RoundedRectSliderTrackShape(),
                              overlayShape:
                                  RoundSliderOverlayShape(overlayRadius: 0),
                            ),
                            child: Slider(
                              value: _currentMinFee,
                              min: _minFee,
                              max: _maxFee,
                              onChanged: (double value) {
                                setState(() {
                                  _currentMinFee = value.roundToDouble();
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildFeeDisplay(_currentMinFee, context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: Localization.translate("language"),
                      items: widget.languages,
                      selectedItems: selectedLanguages,
                      onItemsSelected: (languages) {
                        setState(() {
                          selectedLanguages = languages;
                        });
                      },
                      showAllItems: showAllSelectedLanguages,
                      showAllItemsChanged: (value) {
                        setState(() {
                          showAllSelectedLanguages = value;
                        });
                      },
                    ),
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
                  fontFamily: AppFontFamily.mediumFont,
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
                fontFamily: AppFontFamily.mediumFont,
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
                    fontFamily: AppFontFamily.mediumFont,
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
                  fontFamily: AppFontFamily.mediumFont,
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
                fontFamily: AppFontFamily.mediumFont,
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
                fontFamily: AppFontFamily.mediumFont,
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
                    fontFamily: AppFontFamily.mediumFont,
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
                            fontFamily: AppFontFamily.mediumFont,
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
                          fontFamily: AppFontFamily.mediumFont,
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
                fontFamily: AppFontFamily.mediumFont,
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
                    fontFamily: AppFontFamily.mediumFont,
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
                      fontFamily: AppFontFamily.mediumFont,
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
                  fontFamily: AppFontFamily.mediumFont,
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
                              fontFamily: AppFontFamily.mediumFont,
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
                    fontFamily: AppFontFamily.mediumFont,
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
                      fontFamily: AppFontFamily.mediumFont,
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
                  fontFamily: AppFontFamily.mediumFont,
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
                              fontFamily: AppFontFamily.mediumFont,
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
                    fontFamily: AppFontFamily.mediumFont,
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
                      fontFamily: AppFontFamily.mediumFont,
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
                  fontFamily: AppFontFamily.mediumFont,
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
                              fontFamily: AppFontFamily.mediumFont,
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
                  fontFamily: AppFontFamily.mediumFont,
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

Widget _buildToggleButton(String title, int index, int? selectedIndex,
    BuildContext context, Function(int) onSelect) {
  bool isSelected = selectedIndex != null && selectedIndex == index;

  return Expanded(
    child: GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greyFadeColor : AppColors.whiteColor,
          borderRadius:
              isSelected ? BorderRadius.circular(12) : BorderRadius.zero,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: FontSize.scale(context, 16),
            fontWeight: FontWeight.w500,
            color: isSelected
                ? AppColors.blackColor
                : AppColors.greyColor(context),
          ),
        ),
      ),
    ),
  );
}

Widget _buildFeeDisplay(double fee, BuildContext context) {
  return Container(
    width: 500,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.fadeColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${fee.round()}',
          style: TextStyle(
            color: AppColors.blackColor.withOpacity(0.6),
            fontSize: FontSize.scale(context, 16),
            fontFamily: AppFontFamily.mediumFont,
            fontWeight: FontWeight.w500,
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "\$",
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 18),
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
              TextSpan(
                text: "   ",
              ),
              TextSpan(
                text:
                    '${(Localization.translate('max') ?? '').trim() != 'max' && (Localization.translate('max') ?? '').trim().isNotEmpty ? Localization.translate('max') : 'Max'}',
                style: TextStyle(
                  color: AppColors.blackColor.withOpacity(0.2),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.mediumFont,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget ratingLabel(BuildContext context, String text) {
  return Text(
    text,
    style: TextStyle(
      color: AppColors.greyColor(context),
      fontSize: FontSize.scale(context, 16),
      fontFamily: AppFontFamily.regularFont,
      fontWeight: FontWeight.w400,
    ),
  );
}

class CustomRatingThumb extends SliderComponentShape {
  final BuildContext context;

  CustomRatingThumb(this.context);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(34, 34);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint borderPaint = Paint()
      ..color = AppColors.primaryGreen(this.context)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint thumbPaint = Paint()
      ..color = AppColors.primaryGreen(this.context)
      ..style = PaintingStyle.fill;

    const double thumbRadius = 9.0;
    canvas.drawCircle(center, thumbRadius, thumbPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}
