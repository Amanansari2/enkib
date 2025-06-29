import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/localization/localization.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final bool mandatory;
  final bool obscureText;
  final bool multiLine;
  final bool showSuffixIcon;
  final bool dateIcon;
  final bool searchIcon;
  final bool readOnly;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool hasError;
  final String? errorText;
  final TextInputType keyboardType;
  final bool absorbInput;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool percentage;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    required this.hint,
    this.mandatory = true,
    this.obscureText = false,
    this.multiLine = false,
    this.showSuffixIcon = false,
    this.dateIcon = false,
    this.searchIcon = false,
    this.readOnly = false,
    this.controller,
    this.focusNode,
    this.hasError = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.absorbInput = false,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.percentage = false,
    this.inputFormatters,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _placeholderPosition;
  late Animation<double> _placeholderSize;
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _placeholderPosition = Tween<double>(
      begin: 22,
      end: 6,
    ).animate(_animationController);
    _placeholderSize = Tween<double>(
      begin: 16,
      end: 12,
    ).animate(_animationController);

    if (widget.controller?.text.isNotEmpty ?? false) {
      _animationController.forward();
    }

    widget.controller?.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleTextChange() {
    if (mounted) {
      setState(() {});
      if (widget.controller?.text.isNotEmpty ?? false) {
        _animationController.forward();
      }
      if (widget.onChanged != null) {
        widget.onChanged!(widget.controller?.text ?? '');
      }
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
      if (_focusNode.hasFocus ||
          (widget.controller?.text.isNotEmpty ?? false)) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);

    if (_focusNode != widget.focusNode) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasText = widget.controller?.text.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap:
              widget.readOnly || widget.absorbInput
                  ? widget.onTap
                  : () {
                    FocusScope.of(context).requestFocus(_focusNode);
                  },
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color:
                  (widget.readOnly)
                      ? AppColors.blackColor.withOpacity(0.03)
                      : (_focusNode.hasFocus || hasText)
                      ? AppColors.whiteColor
                      : AppColors.blackColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color:
                    widget.hasError
                        ? AppColors.redColor
                        : AppColors.dividerColor,
                width: 1.0,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
            child: Stack(
              children: [
                Positioned(
                  top: (_focusNode.hasFocus || hasText) ? 5.0 : 13.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.hint,
                        style: TextStyle(
                          color: AppColors.greyColor(context),
                          fontSize:
                              _focusNode.hasFocus || hasText
                                  ? FontSize.scale(context, 12)
                                  : FontSize.scale(context, 16),
                          fontFamily: AppFontFamily.regularFont,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      if (widget.mandatory)
                        Padding(
                          padding: const EdgeInsets.only(left: 3.0),
                          child: SvgPicture.asset(
                            AppImages.mandatory,
                            height: 12.0,
                            color: AppColors.redColor,
                          ),
                        ),
                    ],
                  ),
                ),
                AbsorbPointer(
                  absorbing: widget.absorbInput,
                  child: TextFormField(
                    cursorHeight: 20,
                    controller: widget.controller,
                    readOnly: widget.readOnly,
                    focusNode: _focusNode,
                    obscureText: _isObscured,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    cursorColor: AppColors.blackColor,
                    maxLines: widget.multiLine ? 5 : 1,
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: FontSize.scale(context, 16),
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFontFamily.regularFont,
                      fontStyle: FontStyle.normal,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                        top: 4.0,
                        bottom: (_focusNode.hasFocus || hasText) ? 8.0 : 4.0,
                      ),
                      labelText: '',
                      alignLabelWithHint: widget.multiLine,
                      suffixIcon:
                          widget.percentage
                              ? Transform.translate(
                                offset:
                                    Localization.textDirection ==
                                            TextDirection.rtl
                                        ? const Offset(-10, 0.0)
                                        : const Offset(15, 0.0),
                                child: Icon(
                                  Icons.percent,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              )
                              : widget.absorbInput
                              ? Transform.translate(
                                offset:
                                    Localization.textDirection ==
                                            TextDirection.rtl
                                        ? const Offset(-10, 0.0)
                                        : const Offset(15, 0.0),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 25,
                                  color: Colors.grey,
                                ),
                              )
                              : widget.dateIcon
                              ? Transform.translate(
                                offset: const Offset(10, 0.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: SvgPicture.asset(
                                    AppImages.dateTimeIcon,
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              )
                              : widget.searchIcon
                              ? Transform.translate(
                                offset:
                                    Localization.textDirection ==
                                            TextDirection.rtl
                                        ? const Offset(-12, 0.0)
                                        : const Offset(10, 0.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: SvgPicture.asset(
                                    AppImages.search,
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              )
                              : widget.showSuffixIcon
                              ? SvgPicture.asset(
                                AppImages.showIcon,
                                width: 20,
                                height: 20,
                                color: AppColors.greyColor(context),
                              )
                              : (widget.obscureText
                                  ? IconButton(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    icon: Transform.translate(
                                      offset:
                                          Localization.textDirection ==
                                                  TextDirection.rtl
                                              ? const Offset(-10, 0.0)
                                              : const Offset(15, 0.0),
                                      child: SvgPicture.asset(
                                        _isObscured
                                            ? AppImages.hideIcon
                                            : AppImages.showIcon,
                                        width: 20,
                                        height: 20,
                                        color: AppColors.greyColor(
                                          context,
                                        ).withOpacity(0.7),
                                      ),
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  )
                                  : null),
                    ),
                    onChanged: (text) {
                      setState(() {
                        hasText = text.isNotEmpty;
                        widget.onChanged;
                      });
                    },
                    onFieldSubmitted: widget.onFieldSubmitted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.hasError && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: AppColors.redColor,
                fontFamily: AppFontFamily.mediumFont,
                fontSize: FontSize.scale(context, 12),
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
      ],
    );
  }
}
