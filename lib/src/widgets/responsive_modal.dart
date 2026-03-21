import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fixed_stage.dart';

class ResponsiveDialogPanel extends StatelessWidget {
  const ResponsiveDialogPanel({
    super.key,
    required this.child,
    this.maxWidth = 520,
    this.maxHeight = 720,
    this.widthFactor = 0.88,
    this.heightFactor = 0.82,
    this.minWidth = 280,
    this.minHeight = 220,
    this.radius = 28,
    this.padding = const EdgeInsets.all(20),
    this.fillHeight = false,
    this.scrollable = true,
    this.enforceMinSize = false,
    this.insetPadding,
    this.stageScale,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeight;
  final double widthFactor;
  final double heightFactor;
  final double minWidth;
  final double minHeight;
  final double radius;
  final EdgeInsets padding;
  final bool fillHeight;
  final bool scrollable;
  final bool enforceMinSize;
  final EdgeInsets? insetPadding;
  final double? stageScale;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final scale = stageScale == null || stageScale == 0 ? 1.0 : stageScale!;
    final horizontalInset = math.max(12.0, screen.width * 0.04);
    final verticalInset = math.max(12.0, screen.height * 0.03);
    final actualInsetPadding = insetPadding ??
        EdgeInsets.symmetric(
          horizontal: horizontalInset,
          vertical: verticalInset,
        );
    final availableWidth = math.max(
      0.0,
      screen.width - actualInsetPadding.horizontal - viewInsets.horizontal,
    );
    final availableHeight = math.max(
      0.0,
      screen.height - actualInsetPadding.vertical - viewInsets.vertical,
    );
    final actualDialogWidth = math.min(
      maxWidth,
      math.min(availableWidth, math.max(minWidth, screen.width * widthFactor)),
    );
    final actualDialogHeight = math.min(
      maxHeight,
      math.min(
        availableHeight,
        math.max(minHeight, screen.height * heightFactor),
      ),
    );
    final dialogWidth = math.max(0.0, actualDialogWidth / scale);
    final dialogHeight = math.max(0.0, actualDialogHeight / scale);
    final dialogMinWidth = enforceMinSize
        ? math.max(0.0, math.min(actualDialogWidth, minWidth) / scale)
        : 0.0;
    final dialogMinHeight = enforceMinSize
        ? math.max(0.0, math.min(actualDialogHeight, minHeight) / scale)
        : 0.0;
    final scaledInsetPadding = EdgeInsets.fromLTRB(
      actualInsetPadding.left / scale,
      actualInsetPadding.top / scale,
      actualInsetPadding.right / scale,
      actualInsetPadding.bottom / scale,
    );
    final panel = SizedBox(
      width: dialogWidth,
      height: fillHeight ? dialogHeight : null,
      child: StagePanel(
        padding: padding,
        radius: radius,
        child: scrollable ? SingleChildScrollView(child: child) : child,
      ),
    );
    final dialog = Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: scaledInsetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: dialogMinWidth,
          minHeight: dialogMinHeight,
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: panel,
      ),
    );
    if (scale == 1) {
      return dialog;
    }
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: dialog,
    );
  }
}

class StageRelativeDialogPanel extends StatelessWidget {
  const StageRelativeDialogPanel({
    super.key,
    required this.child,
    required this.stageWidth,
    required this.stageHeight,
    required this.stageScale,
    this.widthRatio = 1 / 3,
    this.heightRatio = 0.65,
    this.radius = 28,
    this.padding = const EdgeInsets.all(20),
    this.fillHeight = true,
    this.scrollable = true,
    this.insetPadding,
  });

  final Widget child;
  final double stageWidth;
  final double stageHeight;
  final double stageScale;
  final double widthRatio;
  final double heightRatio;
  final double radius;
  final EdgeInsets padding;
  final bool fillHeight;
  final bool scrollable;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    final scale = stageScale <= 0 ? 1.0 : stageScale;
    final targetWidth = stageWidth * widthRatio * scale;
    final targetHeight = stageHeight * heightRatio * scale;

    // Use the scaled target size directly so dialog hit testing stays stable
    // across desktop and mobile instead of relying on a transformed route.
    return ResponsiveDialogPanel(
      maxWidth: targetWidth,
      maxHeight: targetHeight,
      minWidth: targetWidth,
      minHeight: targetHeight,
      widthFactor: 0,
      heightFactor: 0,
      radius: radius,
      padding: padding,
      fillHeight: fillHeight,
      scrollable: scrollable,
      insetPadding: insetPadding,
      child: child,
    );
  }
}

class ResponsiveBottomSheetPanel extends StatelessWidget {
  const ResponsiveBottomSheetPanel({
    super.key,
    required this.child,
    this.maxWidth = 780,
    this.maxHeight = 640,
    this.widthFactor = 0.94,
    this.heightFactor = 0.84,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
    this.radius = 28,
    this.stageScale,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeight;
  final double widthFactor;
  final double heightFactor;
  final EdgeInsets padding;
  final double radius;
  final double? stageScale;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = stageScale == null || stageScale == 0 ? 1.0 : stageScale!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final actualHorizontalMargin = math.max(10.0, screen.width * 0.025);
    final actualBottomMargin = math.max(12.0, screen.height * 0.016);
    final availableWidth = math.max(0.0, screen.width - actualHorizontalMargin * 2);
    final availableHeight = math.max(
      0.0,
      screen.height - bottomInset - 12.0 - actualBottomMargin,
    );
    final sheetWidth = math.min(
      maxWidth,
      math.min(availableWidth, screen.width * widthFactor),
    );
    final sheetHeight = math.min(
      maxHeight,
      math.min(availableHeight, screen.height * heightFactor),
    );
    final sheet = AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset / scale),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.fromLTRB(
            actualHorizontalMargin / scale,
            12 / scale,
            actualHorizontalMargin / scale,
            actualBottomMargin / scale,
          ),
          constraints: BoxConstraints(
            maxWidth: sheetWidth / scale,
            maxHeight: sheetHeight / scale,
          ),
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x143678A3),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
    if (scale == 1) {
      return sheet;
    }
    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: sheet,
    );
  }
}
