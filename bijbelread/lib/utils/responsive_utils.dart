import 'package:flutter/material.dart';

/// Utility class for responsive design helpers
class ResponsiveUtils {
  /// Get the screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return ScreenSize.mobile;
    } else if (width < 1200) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.desktop;
    }
  }

  /// Check if the device is mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  /// Check if the device is tablet
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  /// Check if the device is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context) == ScreenSize.desktop;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(16);
      case ScreenSize.tablet:
        return const EdgeInsets.all(24);
      case ScreenSize.desktop:
        return const EdgeInsets.all(32);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return baseSize;
      case ScreenSize.tablet:
        return baseSize * 1.2;
      case ScreenSize.desktop:
        return baseSize * 1.4;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return baseSize;
      case ScreenSize.tablet:
        return baseSize * 1.1;
      case ScreenSize.desktop:
        return baseSize * 1.2;
    }
  }

  /// Get responsive card elevation
  static double getResponsiveCardElevation(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return 2;
      case ScreenSize.tablet:
        return 3;
      case ScreenSize.desktop:
        return 4;
    }
  }

  /// Get responsive border radius
  static BorderRadius getResponsiveBorderRadius(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return BorderRadius.circular(8);
      case ScreenSize.tablet:
        return BorderRadius.circular(12);
      case ScreenSize.desktop:
        return BorderRadius.circular(16);
    }
  }

  /// Get responsive grid cross axis count
  static int getResponsiveGridCount(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return 1;
      case ScreenSize.tablet:
        return 2;
      case ScreenSize.desktop:
        return 3;
    }
  }

  /// Get responsive list item height
  static double getResponsiveListItemHeight(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return 60;
      case ScreenSize.tablet:
        return 70;
      case ScreenSize.desktop:
        return 80;
    }
  }
}

/// Enum for screen size categories
enum ScreenSize {
  mobile,
  tablet,
  desktop,
}

/// Extension methods for easier responsive access
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);

  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);

  double responsiveFontSize(double baseSize) => ResponsiveUtils.getResponsiveFontSize(this, baseSize);

  double responsiveIconSize(double baseSize) => ResponsiveUtils.getResponsiveIconSize(this, baseSize);

  double get responsiveCardElevation => ResponsiveUtils.getResponsiveCardElevation(this);

  BorderRadius get responsiveBorderRadius => ResponsiveUtils.getResponsiveBorderRadius(this);

  int get responsiveGridCount => ResponsiveUtils.getResponsiveGridCount(this);

  double get responsiveListItemHeight => ResponsiveUtils.getResponsiveListItemHeight(this);
}