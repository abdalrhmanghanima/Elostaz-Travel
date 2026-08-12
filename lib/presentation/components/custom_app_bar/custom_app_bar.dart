import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/font_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/dimens/dimens.dart';
import '../custom_text/custom_text.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final double? fontSize;
  final Color? fontColor;
  final bool? showBackArrow;
  final bool? centerTitle;
  final List<Widget>? actions;
  final bool? showToolBar;
  final double? elevation;
  final double titlePadding;
  final double? leadingHeight;
  final double? leadingWidth;
  final Color? bgColor;
  final SystemUiOverlayStyle? systemUiOverlayStyle;
  final String? iconPath;
  final VoidCallback? onPressed;
  final double? spacing;



  const CustomAppBar(
      {super.key,
      this.title,
      this.fontSize,
      this.fontColor,
      this.showBackArrow,
      this.centerTitle,
      this.actions,
      this.showToolBar,
      this.elevation,
      this.bgColor,
        this.titlePadding =0,
      this.systemUiOverlayStyle,
        this.iconPath,
        this.onPressed, this.spacing, this.leadingHeight, this.leadingWidth,
      });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing:spacing?? 0,
      backgroundColor:bgColor ?? AppColors.white,
      leading: iconPath != null
          ? IconButton(
            onPressed: onPressed,
            icon: SvgPicture.asset(iconPath!,width:leadingWidth??20.w ,height: leadingHeight??14.w,),
          )
          : null,
      elevation: elevation,
      systemOverlayStyle: systemUiOverlayStyle,
      scrolledUnderElevation: 0,
      title: Padding(
        padding: EdgeInsets.only(left:titlePadding),
        child: CustomText(
          title: title ?? '',
          fontSize: fontSize ?? AppFonts.font_18,
          fontColor: fontColor??AppColors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle??false,
      actions: actions,
      automaticallyImplyLeading: showBackArrow??true,
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size(Dimens.width, showToolBar == true ? 60.h : 0);
}
