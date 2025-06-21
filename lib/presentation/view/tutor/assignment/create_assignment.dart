import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_projects/data/provider/settings_provider.dart';
import 'package:flutter_projects/presentation/view/auth/login_screen.dart';
import 'package:flutter_projects/presentation/view/components/bottom_sheet.dart';
import 'package:flutter_projects/presentation/view/components/internet_alert.dart';
import 'package:flutter_projects/presentation/view/components/login_required_alert.dart';
import 'package:flutter_projects/presentation/view/tutor/assignment/published_assignment.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';
import '../../../../base_components/textfield.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../data/localization/localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/provider/auth_provider.dart';
import '../../../../data/provider/connectivity_provider.dart';
import '../../../../domain/api_structure/api_service.dart';
import 'package:http/http.dart' as http;

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  int maxFiles = 0;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _assignmentForController =
      TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _sessionController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController();
  final TextEditingController _assignmentTitleController =
      TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _passingGradeController = TextEditingController();
  final TextEditingController _fileSizeController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _charaterLimitController =
      TextEditingController();
  String _selectedFileSizeUnit = 'MB';
  final List<String> _fileSizeUnits = ['MB'];
  final List<String> assignmentType = ['Subject'];
  final List<String> _typeOptions = ['Text', 'Document', 'Both'];
  String? _selectedAssignmentType;
  String? _selectedCourse;
  String? _selectedSubject;
  String? _selectedSession;
  String? _selectedType;
  String _selectedTime = 'AM';
  final List<String> _timeOptions = ['AM', 'PM'];
  List<PlatformFile> uploadedFiles = [];
  late double screenHeight;
  late double screenWidth;
  List<String> _filteredItems = [];
  String _selectedItem = '';
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> sessions = [];
  bool hasSessions = false;
  List<Map<String, dynamic>> courses = [];
  bool showCourseField = false;
  bool _isLoading = false;

  bool _hasTitleError = false;
  bool _hasDescriptionError = false;
  bool _hasAssignmentTypeError = false;
  bool _hasRelatedIdError = false;
  bool _hasTotalMarksError = false;
  bool _hasPassingGradeError = false;
  bool _hasDueDaysError = false;
  bool _hasDueTimeError = false;
  bool _hasMaxFileUploadError = false;
  bool _hasCharacterLimitError = false;
  bool _hasFileSizeError = false;
  bool _hasAssignmentForError = false;
  bool _hasFileUploadError = false;

  String _titleError = '';
  String _descriptionError = '';
  String _assignmentTypeError = '';
  String _relatedIdError = '';
  String _totalMarksError = '';
  String _passingGradeError = '';
  String _dueDaysError = '';
  String _dueTimeError = '';
  String _maxFileUploadError = '';
  String _characterLimitError = '';
  String _fileSizeError = '';
  String _assignmentForError = '';
  String _fileUploadError = '';

  @override
  void initState() {
    super.initState();
    _filteredItems = _fileSizeUnits;
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getSubjects(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          subjects =
              (response['data'] as List<dynamic>)
                  .map(
                    (subject) => {
                      'id': subject['id'],
                      'name': subject['name'].toString(),
                    },
                  )
                  .toList();
        });
      } else if (response['status'] == 401) {
        showCustomToast(context, response['message'], false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate("invalidToken"),
              content: Localization.translate("loginAgain"),
              buttonText: Localization.translate("goToLogin"),
              buttonAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              showCancelButton: false,
            );
          },
        );
      } else {
        showCustomToast(context, response['message'] ?? "Error", false);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {}
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems =
          _fileSizeUnits
              .where((unit) => unit.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void onItemSelected(String item) {
    setState(() {
      _selectedItem = item;
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: true,
        allowCompression: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          showCustomToast(
            context,
            '${(Localization.translate('successfully_picked_file') ?? '').trim() != 'successfully_picked_file' && (Localization.translate('successfully_picked_file') ?? '').trim().isNotEmpty ? Localization.translate('successfully_picked_file') : 'Successfully picked file'}',
            true,
          );
          setState(() {
            uploadedFiles = [file];
            _hasFileUploadError = false;
            _fileUploadError = '';
          });
        } else {
          showCustomToast(
            context,
            '${(Localization.translate('could_not_load_file_data') ?? '').trim() != 'could_not_load_file_data' && (Localization.translate('could_not_load_file_data') ?? '').trim().isNotEmpty ? Localization.translate('could_not_load_file_data') : 'Could not load file data. Please try another file.'}',
            false,
          );
          setState(() {
            _hasFileUploadError = true;
            _fileUploadError =
                '${(Localization.translate('upload_file') ?? '').trim() != 'upload_file' && (Localization.translate('upload_file') ?? '').trim().isNotEmpty ? Localization.translate('upload_file') : 'Upload file'}';
          });
        }
      } else {
        setState(() {
          _hasFileUploadError = true;
          _fileUploadError =
              '${(Localization.translate('upload_file') ?? '').trim() != 'upload_file' && (Localization.translate('upload_file') ?? '').trim().isNotEmpty ? Localization.translate('upload_file') : 'Upload file'}';
        });
      }
    } on PlatformException catch (e) {
      String errorMessage =
          '${(Localization.translate('error_picking_file') ?? '').trim() != 'error_picking_file' && (Localization.translate('error_picking_file') ?? '').trim().isNotEmpty ? Localization.translate('error_picking_file') : 'Error picking file.Please try again.'}';

      if (e.message?.contains('permission') ?? false) {
        errorMessage =
            '${(Localization.translate('grant_permission_to_access_files') ?? '').trim() != 'grant_permission_to_access_files' && (Localization.translate('grant_permission_to_access_files') ?? '').trim().isNotEmpty ? Localization.translate('grant_permission_to_access_files') : 'Grant permission to access files'}';
      } else if (e.message?.contains('iCloud') ?? false) {
        errorMessage =
            '${(Localization.translate('select_file_from_device') ?? '').trim() != 'select_file_from_device' && (Localization.translate('select_file_from_device') ?? '').trim().isNotEmpty ? Localization.translate('select_file_from_device') : 'Select a file from your device'}';
      }

      showCustomToast(context, errorMessage, false);
      setState(() {
        _hasFileUploadError = true;
        _fileUploadError =
            '${(Localization.translate('upload_file') ?? '').trim() != 'upload_file' && (Localization.translate('upload_file') ?? '').trim().isNotEmpty ? Localization.translate('upload_file') : 'Upload file'}';
      });
    } catch (e) {
      showCustomToast(
        context,
        '${(Localization.translate('error_picking_file') ?? '').trim() != 'error_picking_file' && (Localization.translate('error_picking_file') ?? '').trim().isNotEmpty ? Localization.translate('error_picking_file') : 'Error picking file. Please try again.'}',
        false,
      );
      setState(() {
        _hasFileUploadError = true;
        _fileUploadError =
            '${(Localization.translate('upload_file') ?? '').trim() != 'upload_file' && (Localization.translate('upload_file') ?? '').trim().isNotEmpty ? Localization.translate('upload_file') : 'Upload file'}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final coursesAddon =
        settingsProvider.getSetting('data')?['installed_addons'];

    final isCoursesEnabled =
        (coursesAddon != null && coursesAddon['Learnty'] == true)
            ? true
            : false;

    if (isCoursesEnabled && !assignmentType.contains('Course')) {
      assignmentType.add('Course');
    } else if (!isCoursesEnabled && assignmentType.contains('Course')) {
      assignmentType.remove('Course');
    }

    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        if (!connectivityProvider.isConnected) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor(context),
            body: Center(
              child: InternetAlertDialog(
                onRetry: () async {
                  await connectivityProvider.checkInitialConnection();
                },
              ),
            ),
          );
        }
        return WillPopScope(
          onWillPop: () async {
            if (_isLoading) {
              return false;
            } else {
              return true;
            }
          },

          child: Directionality(
            textDirection: Localization.textDirection,

            child: Scaffold(
              backgroundColor: AppColors.backgroundColor(context),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(70.0),
                child: Container(
                  color: AppColors.whiteColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: AppBar(
                      backgroundColor: AppColors.whiteColor,
                      forceMaterialTransparency: true,
                      elevation: 0,
                      titleSpacing: 0,
                      title: Text(
                        '${(Localization.translate('assignment_creation') ?? '').trim() != 'assignment_creation' && (Localization.translate('assignment_creation') ?? '').trim().isNotEmpty ? Localization.translate('assignment_creation') : 'Assignment Creation'}',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 20),
                          fontFamily: AppFontFamily.mediumFont,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: AppColors.blackColor,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      centerTitle: false,
                    ),
                  ),
                ),
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          "${(Localization.translate('build_assignment') ?? '').trim() != 'build_assignment' && (Localization.translate('build_assignment') ?? '').trim().isNotEmpty ? Localization.translate('build_assignment') : "Let's Build an Assignment"}",
                          style: TextStyle(
                            color: AppColors.blackColor.withOpacity(0.7),
                            fontSize: FontSize.scale(context, 16),
                            fontFamily: AppFontFamily.mediumFont,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(Localization.translate('add_assignment_subtitle') ?? '').trim() != 'add_assignment_subtitle' && (Localization.translate('add_assignment_subtitle') ?? '').trim().isNotEmpty ? Localization.translate('add_assignment_subtitle') : 'Quickly add a new assignment for your learners.'}',
                          style: TextStyle(
                            color: AppColors.greyColor(context),
                            fontSize: FontSize.scale(context, 16),
                            fontFamily: AppFontFamily.regularFont,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hint:
                              '${(Localization.translate('assignment_title') ?? '').trim() != 'assignment_title' && (Localization.translate('assignment_title') ?? '').trim().isNotEmpty ? Localization.translate('assignment_title') : 'Add Assignment Title'}',
                          controller: _assignmentTitleController,
                          mandatory: true,
                          hasError: _hasTitleError,
                          errorText: _titleError,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint:
                              '${(Localization.translate('select_assignment_for') ?? '').trim() != 'select_assignment_for' && (Localization.translate('select_assignment_for') ?? '').trim().isNotEmpty ? Localization.translate('select_assignment_for') : 'Select Assignment for'}',
                          mandatory: true,
                          controller: _assignmentForController,
                          absorbInput: true,
                          onTap:
                              () => _showAssignmentTypeForBottomSheet(
                                _assignmentForController,
                              ),
                          hasError: _hasAssignmentForError,
                          errorText: _assignmentForError,
                        ),
                        const SizedBox(height: 10),
                        if (showCourseField)
                          CustomTextField(
                            hint:
                                '${(Localization.translate('select_course') ?? '').trim() != 'select_course' && (Localization.translate('select_course') ?? '').trim().isNotEmpty ? Localization.translate('select_course') : 'Select Course'}',
                            mandatory: true,
                            controller: _courseController,
                            absorbInput: true,
                            onTap:
                                () => _showCourseForBottomSheet(
                                  _courseController,
                                ),
                          ),
                        if (showCourseField) const SizedBox(height: 10),
                        if (_selectedAssignmentType == 'Subject')
                          CustomTextField(
                            hint:
                                '${(Localization.translate('select_subject') ?? '').trim() != 'select_subject' && (Localization.translate('select_subject') ?? '').trim().isNotEmpty ? Localization.translate('select_subject') : 'Select Subject'}',
                            mandatory: true,
                            controller: _subjectController,
                            absorbInput: true,
                            onTap:
                                () => _showSubjectForBottomSheet(
                                  _subjectController,
                                ),
                          ),
                        if (_selectedAssignmentType == 'Subject')
                          const SizedBox(height: 10),
                        if (hasSessions)
                          CustomTextField(
                            hint:
                                '${(Localization.translate('select_session') ?? '').trim() != 'select_session' && (Localization.translate('select_session') ?? '').trim().isNotEmpty ? Localization.translate('select_session') : 'Select Session'}',
                            mandatory: true,
                            controller: _sessionController,
                            absorbInput: true,
                            onTap:
                                () => _showSessionForBottomSheet(
                                  _sessionController,
                                ),
                          ),
                        if (hasSessions) const SizedBox(height: 10),
                        CustomTextField(
                          hint:
                              '${(Localization.translate('select_type') ?? '').trim() != 'select_type' && (Localization.translate('select_type') ?? '').trim().isNotEmpty ? Localization.translate('select_type') : 'Select Type'}',
                          mandatory: true,
                          controller: _typeController,
                          absorbInput: true,
                          onTap: () => _showTypeForBottomSheet(_typeController),
                          hasError: _hasAssignmentTypeError,
                          errorText: _assignmentTypeError,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint:
                              '${(Localization.translate('total_marks') ?? '').trim() != 'total_marks' && (Localization.translate('total_marks') ?? '').trim().isNotEmpty ? Localization.translate('total_marks') : 'Total Marks (0-100)'}',
                          controller: _totalMarksController,
                          mandatory: true,
                          keyboardType: TextInputType.number,
                          hasError: _hasTotalMarksError,
                          errorText: _totalMarksError,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              int marks = int.parse(value);
                              if (marks > 100) {
                                setState(() {
                                  _hasTotalMarksError = true;
                                  _totalMarksError =
                                      '${(Localization.translate('total_marks_error') ?? '').trim() != 'total_marks_error' && (Localization.translate('total_marks_error') ?? '').trim().isNotEmpty ? Localization.translate('total_marks_error') : 'Total marks cannot exceed 100'}';
                                });
                              } else {
                                setState(() {
                                  _hasTotalMarksError = false;
                                  _totalMarksError = '';
                                });
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint:
                              '${(Localization.translate('passing_grade') ?? '').trim() != 'passing_grade' && (Localization.translate('passing_grade') ?? '').trim().isNotEmpty ? Localization.translate('passing_grade') : 'Passing Grade'}',
                          mandatory: true,
                          percentage: true,
                          controller: _passingGradeController,
                          keyboardType: TextInputType.number,
                          hasError: _hasPassingGradeError,
                          errorText: _passingGradeError,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              double passingGrade = double.parse(value);
                              if (passingGrade > 100) {
                                setState(() {
                                  _hasPassingGradeError = true;
                                  _passingGradeError =
                                      '${(Localization.translate('passing_grade_error') ?? '').trim() != 'passing_grade_error' && (Localization.translate('passing_grade_error') ?? '').trim().isNotEmpty ? Localization.translate('passing_grade_error') : 'Passing grade cannot exceed 100'}';
                                });
                              } else {
                                setState(() {
                                  _hasPassingGradeError = false;
                                  _passingGradeError = '';
                                });
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        if (_typeController.text == 'Text' ||
                            _typeController.text == 'Both')
                          CustomTextField(
                            hint:
                                '${(Localization.translate('character_limit') ?? '').trim() != 'character_limit' && (Localization.translate('character_limit') ?? '').trim().isNotEmpty ? Localization.translate('character_limit') : '450'}',
                            mandatory: true,
                            controller: _charaterLimitController,
                            keyboardType: TextInputType.number,
                            hasError: _hasCharacterLimitError,
                            errorText: _characterLimitError,
                          ),
                        if (_typeController.text == 'Text' ||
                            _typeController.text == 'Both')
                          const SizedBox(height: 10),

                        if (_typeController.text == 'Document' ||
                            _typeController.text == 'Both')
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.blackColor.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _hasMaxFileUploadError
                                        ? AppColors.redColor
                                        : AppColors.dividerColor,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${(Localization.translate('upload_file_size') ?? '').trim() != 'upload_file_size' && (Localization.translate('upload_file_size') ?? '').trim().isNotEmpty ? Localization.translate('upload_file_size') : 'Max Files to Upload'}',
                                    style: TextStyle(
                                      color: AppColors.greyColor(context),
                                      fontSize: FontSize.scale(context, 16),
                                      fontFamily: AppFontFamily.regularFont,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          setState(() {
                                            if (maxFiles > 0) maxFiles--;
                                          });
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.blackColor
                                                .withOpacity(0.03),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.remove,
                                              size: 22,
                                              color: AppColors.blackColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 36,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$maxFiles',
                                          style: TextStyle(
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.blackColor,
                                            fontFamily:
                                                AppFontFamily.mediumFont,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          setState(() {
                                            maxFiles++;
                                          });
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGreen(
                                              context,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.add,
                                              size: 22,
                                              color: AppColors.whiteColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_typeController.text == 'Document' ||
                            _typeController.text == 'Both')
                          if (_hasMaxFileUploadError)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _maxFileUploadError,
                                style: TextStyle(
                                  color: AppColors.redColor,
                                  fontSize: FontSize.scale(context, 12),
                                  fontFamily: AppFontFamily.mediumFont,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ),
                        if (_typeController.text == 'Document' ||
                            _typeController.text == 'Both')
                          const SizedBox(height: 10),

                        if (_typeController.text == 'Document' ||
                            _typeController.text == 'Both')
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomTextField(
                                      hint:
                                          '${(Localization.translate('max_upload_file_size') ?? '').trim() != 'max_upload_file_size' && (Localization.translate('max_upload_file_size') ?? '').trim().isNotEmpty ? Localization.translate('max_upload_file_size') : 'Max Upload File Size'}',
                                      mandatory: true,
                                      controller: _fileSizeController,
                                      keyboardType: TextInputType.number,
                                      showSuffixIcon: false,
                                      hasError: _hasFileSizeError,
                                      errorText: _fileSizeError,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: GestureDetector(
                                  onTap: _showFileSizeUnitPicker,
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      left: 8,
                                      right: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.blackColor.withOpacity(
                                        0.03,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _selectedFileSizeUnit,
                                          style: TextStyle(
                                            fontSize: FontSize.scale(
                                              context,
                                              14,
                                            ),
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.greyColor(context),
                                            fontFamily:
                                                AppFontFamily.mediumFont,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (_typeController.text == 'Document' ||
                            _typeController.text == 'Both')
                          const SizedBox(height: 10),

                        CustomTextField(
                          hint:
                              '${(Localization.translate('number_of_days') ?? '').trim() != 'number_of_days' && (Localization.translate('number_of_days') ?? '').trim().isNotEmpty ? Localization.translate('number_of_days') : 'Number of days'}',
                          mandatory: true,
                          controller: _deadlineController,
                          keyboardType: TextInputType.number,
                          hasError: _hasDueDaysError,
                          errorText: _dueDaysError,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    hint:
                                        '${(Localization.translate('time') ?? '').trim() != 'time' && (Localization.translate('time') ?? '').trim().isNotEmpty ? Localization.translate('time') : 'Time'}',
                                    mandatory: true,
                                    controller: _timeController,
                                    keyboardType: TextInputType.datetime,
                                    showSuffixIcon: false,
                                    absorbInput: true,
                                    onTap: () => _showTimePickerDialog(),
                                    hasError: _hasDueTimeError,
                                    errorText: _dueTimeError,
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: GestureDetector(
                                onTap: _showTimePicker,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.blackColor.withOpacity(
                                      0.03,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _selectedTime ?? '',
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 14),
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.greyColor(context),
                                          fontFamily: AppFontFamily.mediumFont,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        _buildFileUploadBox(),
                        const SizedBox(height: 10),

                        CustomTextField(
                          hint:
                              '${(Localization.translate('description') ?? '').trim() != 'description' && (Localization.translate('description') ?? '').trim().isNotEmpty ? Localization.translate('description') : 'Description'}',
                          mandatory: true,
                          multiLine: true,
                          controller: _descriptionController,
                          hasError: _hasDescriptionError,
                          errorText: _descriptionError,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen(context),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (_isLoading) return;

                              setState(() {
                                _hasTitleError = false;
                                _hasDescriptionError = false;
                                _hasAssignmentTypeError = false;
                                _hasRelatedIdError = false;
                                _hasTotalMarksError = false;
                                _hasPassingGradeError = false;
                                _hasDueDaysError = false;
                                _hasDueTimeError = false;
                                _hasMaxFileUploadError = false;
                                _hasCharacterLimitError = false;
                                _hasFileSizeError = false;
                                _hasAssignmentForError = false;
                                _hasFileUploadError = false;

                                _titleError = '';
                                _descriptionError = '';
                                _assignmentTypeError = '';
                                _relatedIdError = '';
                                _totalMarksError = '';
                                _passingGradeError = '';
                                _dueDaysError = '';
                                _dueTimeError = '';
                                _maxFileUploadError = '';
                                _characterLimitError = '';
                                _fileSizeError = '';
                                _assignmentForError = '';
                                _fileUploadError = '';
                              });

                              bool hasErrors = false;
                              if (_assignmentTitleController.text.isEmpty) {
                                setState(() {
                                  _hasTitleError = true;
                                  _titleError =
                                      '${(Localization.translate('the_title_field_is_required') ?? '').trim() != 'the_title_field_is_required' && (Localization.translate('the_title_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_title_field_is_required') : 'The title field is required.'}';
                                  hasErrors = true;
                                });
                              }
                              if (_descriptionController.text.isEmpty) {
                                setState(() {
                                  _hasDescriptionError = true;
                                  _descriptionError =
                                      '${(Localization.translate('the_description_field_is_required') ?? '').trim() != 'the_description_field_is_required' && (Localization.translate('the_description_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_description_field_is_required') : 'The description field is required.'}';
                                  hasErrors = true;
                                });
                              }
                              if (_typeController.text.isEmpty) {
                                setState(() {
                                  _hasAssignmentTypeError = true;
                                  _assignmentTypeError =
                                      '${(Localization.translate('the_assignment_type_field_is_required') ?? '').trim() != 'the_assignment_type_field_is_required' && (Localization.translate('the_assignment_type_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_assignment_type_field_is_required') : 'The assignment type field is required.'}';
                                  hasErrors = true;
                                });
                              }
                              if ((_selectedAssignmentType == 'Subject' &&
                                      _subjectController.text.isEmpty) ||
                                  (_selectedAssignmentType == 'Course' &&
                                      _courseController.text.isEmpty)) {
                                setState(() {
                                  _hasRelatedIdError = true;
                                  _relatedIdError =
                                      '${(Localization.translate('this_field_is_required') ?? '').trim() != 'this_field_is_required' && (Localization.translate('this_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('this_field_is_required') : 'This field is required.'}';
                                  hasErrors = true;
                                });
                              }
                              if (_totalMarksController.text.isEmpty) {
                                setState(() {
                                  _hasTotalMarksError = true;
                                  _totalMarksError =
                                      '${(Localization.translate('the_total_marks_field_is_required') ?? '').trim() != 'the_total_marks_field_is_required' && (Localization.translate('the_total_marks_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_total_marks_field_is_required') : 'The total marks field is required.'}';
                                  hasErrors = true;
                                });
                              }
                              if (_passingGradeController.text.isEmpty) {
                                setState(() {
                                  _hasPassingGradeError = true;
                                  _passingGradeError =
                                      '${(Localization.translate('the_passing_grade_field_is_required') ?? '').trim() != 'the_passing_grade_field_is_required' && (Localization.translate('the_passing_grade_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_passing_grade_field_is_required') : 'The passing grade field is required.'}';
                                  hasErrors = true;
                                });
                              }
                              if (_deadlineController.text.isEmpty) {
                                setState(() {
                                  _hasDueDaysError = true;
                                  _dueDaysError =
                                      '${(Localization.translate('the_due_days_field_is_required') ?? '').trim() != 'the_due_days_field_is_required' && (Localization.translate('the_due_days_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_due_days_field_is_required') : 'The due days field is required.'}';
                                  hasErrors = true;
                                });
                              }
                              if (_timeController.text.isEmpty) {
                                setState(() {
                                  _hasDueTimeError = true;
                                  _dueTimeError =
                                      '${(Localization.translate('the_due_time_field_is_required') ?? '').trim() != 'the_due_time_field_is_required' && (Localization.translate('the_due_time_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_due_time_field_is_required') : 'The due time field is required.'}';
                                  hasErrors = true;
                                });
                              }
                              if (_typeController.text == 'Document' ||
                                  _typeController.text == 'Both') {
                                if (maxFiles < 1) {
                                  setState(() {
                                    _hasMaxFileUploadError = true;
                                    _maxFileUploadError =
                                        '${(Localization.translate('the_max_file_upload_field_must_be_at_least_1') ?? '').trim() != 'the_max_file_upload_field_must_be_at_least_1' && (Localization.translate('the_max_file_upload_field_must_be_at_least_1') ?? '').trim().isNotEmpty ? Localization.translate('the_max_file_upload_field_must_be_at_least_1') : 'The max file upload field must be at least 1.'}';
                                    hasErrors = true;
                                  });
                                }
                                if (_fileSizeController.text.isEmpty) {
                                  setState(() {
                                    _hasFileSizeError = true;
                                    _fileSizeError =
                                        '${(Localization.translate('the_max_upload_file_size_field_is_required') ?? '').trim() != 'the_max_upload_file_size_field_is_required' && (Localization.translate('the_max_upload_file_size_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_max_upload_file_size_field_is_required') : 'The max upload file size field is required.'}';
                                    hasErrors = true;
                                  });
                                }
                              }
                              if (_typeController.text == 'Text' ||
                                  _typeController.text == 'Both') {
                                if (_charaterLimitController.text.isEmpty) {
                                  setState(() {
                                    _hasCharacterLimitError = true;
                                    _characterLimitError =
                                        '${(Localization.translate('the_character_limit_field_is_required') ?? '').trim() != 'the_character_limit_field_is_required' && (Localization.translate('the_character_limit_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_character_limit_field_is_required') : 'The character limit field is required.'}';
                                    hasErrors = true;
                                  });
                                }
                              }
                              if (_assignmentForController.text.isEmpty) {
                                setState(() {
                                  _hasAssignmentForError = true;
                                  _assignmentForError =
                                      '${(Localization.translate('the_assignment_for_field_is_required') ?? '').trim() != 'the_assignment_for_field_is_required' && (Localization.translate('the_assignment_for_field_is_required') ?? '').trim().isNotEmpty ? Localization.translate('the_assignment_for_field_is_required') : 'The assignment for field is required.'}';
                                  hasErrors = true;
                                });
                              }

                              if (uploadedFiles.isEmpty) {
                                setState(() {
                                  _hasFileUploadError = true;
                                  _fileUploadError =
                                      '${(Localization.translate('upload_file') ?? '').trim() != 'upload_file' && (Localization.translate('upload_file') ?? '').trim().isNotEmpty ? Localization.translate('upload_file') : 'Upload file'}';
                                  hasErrors = true;
                                });
                              }

                              if (hasErrors) {
                                return;
                              }

                              _submitAssignment();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(Localization.translate("save_update") ?? '').trim() != 'save_update' && (Localization.translate("save_update") ?? '').trim().isNotEmpty ? Localization.translate("save_update") : 'Save & Update'}',
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    color: AppColors.whiteColor,
                                    fontFamily: AppFontFamily.mediumFont,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                                if (_isLoading) ...[
                                  SizedBox(width: 12),
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileUploadBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DottedBorder(
          color:
              _hasFileUploadError ? AppColors.redColor : AppColors.dividerColor,
          strokeWidth: 2.0,
          dashPattern: [12, 15],
          borderType: BorderType.RRect,
          radius: Radius.circular(12),
          child: GestureDetector(
            onTap: () {
              _pickFile();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              width: screenWidth,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  uploadedFiles.isNotEmpty
                      ? _buildFilePreview(uploadedFiles.first)
                      : Row(
                        children: [
                          Image.asset(
                            AppImages.uploadDocument,
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                          ),
                          SizedBox(width: 15),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            "${(Localization.translate('drop_file_here') ?? '').trim() != 'drop_file_here' && (Localization.translate('drop_file_here') ?? '').trim().isNotEmpty ? Localization.translate('drop_file_here') : 'Drop file here or'}",
                                        style: TextStyle(
                                          color: AppColors.greyColor(context),
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: AppFontFamily.regularFont,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                      TextSpan(text: " "),
                                      TextSpan(
                                        text:
                                            "${(Localization.translate('click_here') ?? '').trim() != 'click_here' && (Localization.translate('click_here') ?? '').trim().isNotEmpty ? Localization.translate('click_here') : 'click here'}",
                                        style: TextStyle(
                                          color: AppColors.greyColor(context),
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: AppFontFamily.regularFont,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.greyColor(
                                            context,
                                          ),
                                          decorationThickness: 0.6,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = () {
                                                _pickFile();
                                              },
                                      ),
                                      TextSpan(text: " "),
                                      TextSpan(
                                        text:
                                            "${(Localization.translate('to_upload') ?? '').trim() != 'to_upload' && (Localization.translate('to_upload') ?? '').trim().isNotEmpty ? Localization.translate('to_upload') : 'to upload'}",
                                        style: TextStyle(
                                          color: AppColors.greyColor(context),
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: AppFontFamily.regularFont,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "${(Localization.translate('supported_file_formats') ?? '').trim() != 'supported_file_formats' && (Localization.translate('supported_file_formats') ?? '').trim().isNotEmpty ? Localization.translate('supported_file_formats') : 'All file types supported'}",
                                  style: TextStyle(
                                    color: AppColors.greyColor(
                                      context,
                                    ).withOpacity(0.7),
                                    fontSize: FontSize.scale(context, 12),
                                    fontFamily: AppFontFamily.regularFont,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
        if (_hasFileUploadError)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _fileUploadError,
              style: TextStyle(
                color: AppColors.redColor,
                fontSize: FontSize.scale(context, 12),
                fontFamily: AppFontFamily.mediumFont,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilePreview(PlatformFile file) {
    final bool isImage =
        file.extension?.toLowerCase() == 'jpg' ||
        file.extension?.toLowerCase() == 'jpeg' ||
        file.extension?.toLowerCase() == 'png' ||
        file.extension?.toLowerCase() == 'gif';

    String fileSize = _formatFileSize(file.size);

    return Row(
      children: [
        if (isImage && file.bytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              file.bytes!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.blackColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 24,
                  color: AppColors.greyColor(context),
                ),
                SizedBox(height: 4),
                Text(
                  file.extension?.toUpperCase() ?? 'FILE',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.greyColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                style: TextStyle(
                  fontSize: FontSize.scale(context, 14),
                  color: AppColors.blackColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFontFamily.mediumFont,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                fileSize,
                style: TextStyle(
                  fontSize: FontSize.scale(context, 12),
                  color: AppColors.greyColor(context),
                  fontWeight: FontWeight.w400,
                  fontFamily: AppFontFamily.regularFont,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppImages.removeIcon,
            width: 20,
            height: 20,
            color: AppColors.greyColor(context),
          ),
          onPressed: () {
            setState(() {
              uploadedFiles.clear();
            });
          },
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  void _showAssignmentTypeForBottomSheet(TextEditingController controller) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: SingleChildScrollView(
                child: BottomSheetComponent(
                  title:
                      "${(Localization.translate('assignment_type') ?? '').trim() != 'assignment_type' && (Localization.translate('assignment_type') ?? '').trim().isNotEmpty ? Localization.translate('assignment_type') : 'Assignment Type'}",
                  items: assignmentType,
                  selectedItem: _selectedAssignmentType,
                  onItemSelected: (selectedItem) async {
                    setModalState(() {
                      _selectedAssignmentType = selectedItem;
                      controller.text = selectedItem;
                    });
                    setState(() {
                      _selectedAssignmentType = selectedItem;
                      controller.text = selectedItem;
                      if (selectedItem != 'Subject') {
                        hasSessions = false;
                        _sessionController.clear();
                        _selectedSession = null;
                      }
                    });
                    if (selectedItem == 'Course') {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final token = authProvider.token;
                      try {
                        final response = await getCourseList(token);
                        setState(() {
                          courses =
                              (response['data'] as List<dynamic>?)
                                  ?.map(
                                    (course) => {
                                      'id': course['id'],
                                      'title': course['title'].toString(),
                                    },
                                  )
                                  .toList() ??
                              [];
                          showCourseField = true;
                        });
                      } catch (e) {
                        setState(() {
                          courses = [];
                          showCourseField = false;
                        });
                      }
                    } else {
                      setState(() {
                        showCourseField = false;
                        courses = [];
                      });
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSubjectForBottomSheet(TextEditingController controller) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title:
                  "${(Localization.translate('Subject') ?? '').trim() != 'Subject' && (Localization.translate('Subject') ?? '').trim().isNotEmpty ? Localization.translate('Subject') : 'Subject'}",
              items: subjects.map((s) => s['name'] as String).toList(),
              selectedItem: _selectedSubject,

              onItemSelected: (selectedItem) async {
                setModalState(() {
                  _selectedSubject = selectedItem;
                  controller.text = selectedItem;
                });
                setState(() {
                  _selectedSubject = selectedItem;
                  controller.text = selectedItem;
                });
                final selectedSubject = subjects.firstWhere(
                  (s) => s['name'] == selectedItem,
                  orElse: () => {},
                );
                final subjectId = selectedSubject['id'];
                if (subjectId != null) {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final token = authProvider.token;
                  try {
                    final response = await getSessions(
                      token,
                      subjectId.toString(),
                    );
                    setState(() {
                      sessions =
                          (response['data'] as List<dynamic>?)
                              ?.map(
                                (session) => {
                                  'value': session['value'],
                                  'text': session['text'],
                                },
                              )
                              .toList() ??
                          [];
                      hasSessions = sessions.isNotEmpty;
                    });
                  } catch (e) {
                    setState(() {
                      sessions = [];
                      hasSessions = false;
                    });
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  void _showSessionForBottomSheet(TextEditingController controller) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title:
                  "${(Localization.translate('Session') ?? '').trim() != 'Session' && (Localization.translate('Session') ?? '').trim().isNotEmpty ? Localization.translate('Session') : 'Session'}",
              items: sessions.map((s) => s['text'] as String).toList(),
              selectedItem: _selectedSession,
              onItemSelected: (selectedItem) {
                setModalState(() {
                  _selectedSession = selectedItem;
                  controller.text = selectedItem;
                });
                setState(() {
                  _selectedSession = selectedItem;
                  controller.text = selectedItem;
                });
              },
            );
          },
        );
      },
    );
  }

  void _showCourseForBottomSheet(TextEditingController controller) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title:
                  "${(Localization.translate('course') ?? '').trim() != 'course' && (Localization.translate('course') ?? '').trim().isNotEmpty ? Localization.translate('course') : 'Course'}",
              items: courses.map((c) => c['title'] as String).toList(),

              selectedItem: _selectedCourse,
              onItemSelected: (selectedItem) {
                setModalState(() {
                  _selectedCourse = selectedItem;
                  controller.text = selectedItem;
                });
                setState(() {
                  _selectedCourse = selectedItem;
                  controller.text = selectedItem;
                });
              },
            );
          },
        );
      },
    );
  }

  void _showTypeForBottomSheet(TextEditingController controller) {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BottomSheetComponent(
              title:
                  "${(Localization.translate('select_type') ?? '').trim() != 'select_type' && (Localization.translate('select_type') ?? '').trim().isNotEmpty ? Localization.translate('select_type') : 'Select Type'}",
              items: _typeOptions,
              selectedItem: _selectedType,
              onItemSelected: (selectedItem) {
                setModalState(() {
                  _selectedType = selectedItem;
                  controller.text = selectedItem;
                });
                setState(() {
                  _selectedType = selectedItem;
                  controller.text = selectedItem;
                });
              },
            );
          },
        );
      },
    );
  }

  void _showFileSizeUnitPicker() {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: AppColors.sheetBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 10, top: 1),
                    decoration: BoxDecoration(
                      color: AppColors.topBottomSheetDismissColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  "${(Localization.translate('select_option') ?? '').trim() != 'select_option' && (Localization.translate('select_option') ?? '').trim().isNotEmpty ? Localization.translate('select_option') : 'Select Option'}",
                  style: TextStyle(
                    fontSize: FontSize.scale(context, 18),
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontFamily: AppFontFamily.mediumFont,
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _searchController,
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText:
                        '${(Localization.translate('search') ?? '').trim() != 'search' && (Localization.translate('search') ?? '').trim().isNotEmpty ? Localization.translate('search') : 'Search'}',
                    hintStyle: TextStyle(
                      color: AppColors.greyColor(context),
                      fontSize: FontSize.scale(context, 15),
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                      fontFamily: AppFontFamily.mediumFont,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.whiteColor,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18.0,
                      horizontal: 16.0,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        AppImages.search,
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Expanded(
                  child:
                      _filteredItems.isEmpty
                          ? Center(
                            child: Text(
                              "${Localization.translate("item_empty")}",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                          : Container(
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
                            child: ListView.separated(
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        title: Text(
                                          item,
                                          style: TextStyle(
                                            color: AppColors.greyColor(context),
                                            fontSize: FontSize.scale(
                                              context,
                                              16,
                                            ),
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.normal,
                                            fontFamily:
                                                AppFontFamily.mediumFont,
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedFileSizeUnit = item;
                                            _selectedItem = item;
                                          });
                                          onItemSelected(item);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                    Radio<String>(
                                      value: item,
                                      groupValue: _selectedItem,
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedFileSizeUnit = value;
                                            _selectedItem = value;
                                          });
                                          onItemSelected(value);
                                          Navigator.pop(context);
                                        }
                                      },

                                      activeColor: AppColors.primaryGreen(
                                        context,
                                      ),
                                      fillColor:
                                          MaterialStateProperty.resolveWith<
                                            Color?
                                          >((Set<MaterialState> states) {
                                            if (states.contains(
                                              MaterialState.selected,
                                            )) {
                                              return AppColors.primaryGreen(
                                                context,
                                              );
                                            }
                                            return AppColors.greyColor(context);
                                          }),
                                    ),
                                  ],
                                );
                              },
                              separatorBuilder: (context, index) {
                                return Divider(
                                  color: AppColors.dividerColor,
                                  thickness: 1,
                                  height: 1,
                                  indent: 16.0,
                                  endIndent: 16.0,
                                );
                              },
                            ),
                          ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimePicker() {
    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: Localization.textDirection,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              color: AppColors.sheetBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 10, top: 1),
                    decoration: BoxDecoration(
                      color: AppColors.topBottomSheetDismissColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  "${(Localization.translate('select_option') ?? '').trim() != 'select_option' && (Localization.translate('select_option') ?? '').trim().isNotEmpty ? Localization.translate('select_option') : 'Select Option'}",
                  style: TextStyle(
                    fontSize: FontSize.scale(context, 18),
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontFamily: AppFontFamily.mediumFont,
                  ),
                ),
                const SizedBox(height: 16.0),
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
                    child: ListView.separated(
                      itemCount: _timeOptions.length,
                      itemBuilder: (context, index) {
                        final item = _timeOptions[index];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(
                                  item,
                                  style: TextStyle(
                                    color: AppColors.greyColor(context),
                                    fontSize: FontSize.scale(context, 16),
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: AppFontFamily.mediumFont,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedTime = item;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Radio<String>(
                              value: item,
                              groupValue: _selectedTime,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedTime = value;
                                  });
                                  Navigator.pop(context);
                                }
                              },
                              activeColor: AppColors.primaryGreen(context),
                              fillColor: MaterialStateProperty.resolveWith<
                                Color?
                              >((Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return AppColors.primaryGreen(context);
                                }
                                return AppColors.greyColor(context);
                              }),
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(
                          color: AppColors.dividerColor,
                          thickness: 1,
                          height: 1,
                          indent: 16.0,
                          endIndent: 16.0,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimePickerDialog() {
    TimeOfDay? selectedTime;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "${(Localization.translate('select_time') ?? '').trim() != 'select_time' && (Localization.translate('select_time') ?? '').trim().isNotEmpty ? Localization.translate('select_time') : 'Select Time'}",
            style: TextStyle(
              fontSize: FontSize.scale(context, 18),
              color: AppColors.blackColor,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              fontFamily: AppFontFamily.mediumFont,
            ),
          ),
          content: Container(
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: FontSize.scale(context, 16),
                          fontFamily: AppFontFamily.regularFont,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      minuteInterval: 1,
                      onDateTimeChanged: (DateTime newTime) {
                        selectedTime = TimeOfDay.fromDateTime(newTime);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "${(Localization.translate('cancel') ?? '').trim() != 'cancel' && (Localization.translate('cancel') ?? '').trim().isNotEmpty ? Localization.translate('cancel') : 'Cancel'}",
                style: TextStyle(
                  color: AppColors.greyColor(context),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (selectedTime != null) {
                  final hour = selectedTime!.hourOfPeriod;
                  final minute = selectedTime!.minute.toString().padLeft(
                    2,
                    '0',
                  );
                  setState(() {
                    _timeController.text = '$hour:$minute';
                  });
                  Navigator.of(context).pop();
                  _showTimePicker();
                }
              },
              child: Text(
                "${(Localization.translate('ok') ?? '').trim() != 'ok' && (Localization.translate('ok') ?? '').trim().isNotEmpty ? Localization.translate('ok') : 'OK'}",
                style: TextStyle(
                  color: AppColors.primaryGreen(context),
                  fontSize: FontSize.scale(context, 16),
                  fontFamily: AppFontFamily.mediumFont,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAssignment() async {
    setState(() {
      _isLoading = true;
      _hasFileUploadError = false;
      _fileUploadError = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      String apiAssignmentType = '';
      if (_typeController.text == 'Text') {
        apiAssignmentType = 'text';
      } else if (_typeController.text == 'Document') {
        apiAssignmentType = 'document';
      } else if (_typeController.text == 'Both') {
        apiAssignmentType = 'both';
      }

      if ((_typeController.text == 'Document' ||
              _typeController.text == 'Both') &&
          uploadedFiles.isEmpty) {
        setState(() {
          _hasFileUploadError = true;
          _fileUploadError = 'Upload image';
          _isLoading = false;
        });
        showCustomToast(
          context,
          '${(Localization.translate('upload_image') ?? '').trim() != 'upload_image' && (Localization.translate('upload_image') ?? '').trim().isNotEmpty ? Localization.translate('upload_image') : 'Upload image'}',
          false,
        );
        return;
      }

      Map<String, dynamic> data = {
        'assignment_for':
            _selectedAssignmentType == 'Subject' ? 'subject' : 'courses',
        'related_id':
            _selectedAssignmentType == 'Subject'
                ? subjects.firstWhere(
                  (s) => s['name'] == _subjectController.text,
                  orElse: () => {'id': ''},
                )['id']
                : courses.firstWhere(
                  (c) => c['title'] == _courseController.text,
                  orElse: () => {'id': ''},
                )['id'],
        'title': _assignmentTitleController.text,
        'total_marks': _totalMarksController.text,
        'passing_grade': _passingGradeController.text,
        'dueDays': _deadlineController.text,
        'dueTime': _timeController.text,
        'charactersCount':
            _typeController.text == 'Text' || _typeController.text == 'Both'
                ? _charaterLimitController.text
                : '',
        'assignment_type': apiAssignmentType,
        'user_subject_slots':
            hasSessions
                ? [
                  (sessions.firstWhere(
                            (s) => s['text'] == _sessionController.text,
                            orElse: () => {'value': ''},
                          )['value'] ??
                          '')
                      .toString(),
                ]
                : [],
        'description':
            _descriptionController.text.isEmpty
                ? ''
                : _descriptionController.text,
      };

      if (_typeController.text == 'Document' ||
          _typeController.text == 'Both') {
        data['max_file_upload'] = maxFiles.toString();
        data['max_upload_file_size'] = _fileSizeController.text;
      }

      List<http.MultipartFile> files = [];
      if (uploadedFiles.isNotEmpty &&
          (_typeController.text == 'Document' ||
              _typeController.text == 'Both')) {
        final file = uploadedFiles.first;
        files.add(
          http.MultipartFile.fromBytes(
            'existingAttachments[]',
            file.bytes!,
            filename: file.name,
          ),
        );
      }

      final response = await createAssignment(
        token: token!,
        data: data,
        files: files,
      );

      setState(() {
        _isLoading = false;
      });

      if (response['status'] == 200 || response['status'] == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PublishedAssignment()),
        );
        showCustomToast(
          context,
          '${response['message'] ?? "${(Localization.translate('assignment_created_successfully') ?? '').trim() != 'assignment_created_successfully' && (Localization.translate('assignment_created_successfully') ?? '').trim().isNotEmpty ? Localization.translate('assignment_created_successfully') : 'Assignment created successfully'}"}',
          true,
        );
      } else if (response['status'] == 422) {
        if (response['data'] != null && response['data'] is Map) {
          Map<String, dynamic> errors = response['data'];
          setState(() {
            _hasTitleError = false;
            _hasDescriptionError = false;
            _hasAssignmentTypeError = false;
            _hasRelatedIdError = false;
            _hasTotalMarksError = false;
            _hasPassingGradeError = false;
            _hasDueDaysError = false;
            _hasDueTimeError = false;
            _hasMaxFileUploadError = false;
            _hasCharacterLimitError = false;
            _hasFileSizeError = false;
            _hasAssignmentForError = false;
            _hasFileUploadError = false;

            if (errors.containsKey('title')) {
              _hasTitleError = true;
              _titleError = errors['title'][0] ?? 'Title is required';
            }
            if (errors.containsKey('description')) {
              _hasDescriptionError = true;
              _descriptionError =
                  errors['description'][0] ?? 'Description is required';
            }
            if (errors.containsKey('assignment_type')) {
              _hasAssignmentTypeError = true;
              _assignmentTypeError =
                  errors['assignment_type'][0] ?? 'Assignment type is required';
            }
            if (errors.containsKey('related_id')) {
              _hasRelatedIdError = true;
              _relatedIdError =
                  errors['related_id'][0] ?? 'Related ID is required';
            }
            if (errors.containsKey('total_marks')) {
              _hasTotalMarksError = true;
              _totalMarksError =
                  errors['total_marks'][0] ?? 'Total marks is required';
            }
            if (errors.containsKey('passing_grade')) {
              _hasPassingGradeError = true;
              _passingGradeError =
                  errors['passing_grade'][0] ?? 'Passing grade is required';
            }
            if (errors.containsKey('dueDays')) {
              _hasDueDaysError = true;
              _dueDaysError = errors['dueDays'][0] ?? 'Due days is required';
            }
            if (errors.containsKey('dueTime')) {
              _hasDueTimeError = true;
              _dueTimeError = errors['dueTime'][0] ?? 'Due time is required';
            }
            if (errors.containsKey('max_file_upload')) {
              _hasMaxFileUploadError = true;
              _maxFileUploadError =
                  errors['max_file_upload'][0] ?? 'Max file upload is required';
            }
            if (errors.containsKey('charactersCount')) {
              _hasCharacterLimitError = true;
              _characterLimitError =
                  errors['charactersCount'][0] ?? 'Character limit is required';
            }
            if (errors.containsKey('max_upload_file_size')) {
              _hasFileSizeError = true;
              _fileSizeError =
                  errors['max_upload_file_size'][0] ??
                  'Max upload file size is required';
            }
            if (errors.containsKey('assignment_for')) {
              _hasAssignmentForError = true;
              _assignmentForError =
                  errors['assignment_for'][0] ?? 'Assignment for is required';
            }
            if (errors.containsKey('existingAttachments')) {
              _hasFileUploadError = true;
              _fileUploadError =
                  errors['existingAttachments'][0] ??
                  'Please upload at least one file';
            }
          });
        }
        showCustomToast(
          context,
          '${(Localization.translate('please_check_the_form_for_errors') ?? '').trim() != 'please_check_the_form_for_errors' && (Localization.translate('please_check_the_form_for_errors') ?? '').trim().isNotEmpty ? Localization.translate('please_check_the_form_for_errors') : 'Please check the form for errors'}',
          false,
        );
      } else if (response['status'] == 401) {
        showCustomToast(context, '${response['message']}', true);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: Localization.translate('invalidToken'),
              content: Localization.translate('loginAgain'),
              buttonText: Localization.translate('goToLogin'),
              buttonAction: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              showCancelButton: false,
            );
          },
        );
      } else if (response['status'] == 403) {
        showCustomToast(context, response['message'], false);
      } else {
        showCustomToast(
          context,
          response['message'] ?? 'Failed to create assignment',
          false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showCustomToast(context, 'Error: ' + e.toString(), false);
    }
  }
}
