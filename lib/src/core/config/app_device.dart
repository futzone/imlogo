import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

DeviceType getDeviceType(BuildContext context) {
  final double width = MediaQuery.of(context).size.width;

  if (width >= 1200) {
    return DeviceType.desktop;
  } else if (width >= 600) {
    return DeviceType.tablet;
  } else {
    return DeviceType.mobile;
  }
}

extension DTE on BuildContext {
  bool get isTablet => getDeviceType(this) == DeviceType.tablet;

  bool get isMobile => getDeviceType(this) == DeviceType.mobile;

  bool get isDesktop => getDeviceType(this) == DeviceType.desktop;
}
