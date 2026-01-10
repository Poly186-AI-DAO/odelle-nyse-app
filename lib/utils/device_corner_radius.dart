import 'package:flutter/widgets.dart';

/// Utility for getting device-specific corner radius values.
/// 
/// iOS devices have different display corner radii. This utility provides
/// a lookup table based on screen dimensions to return the appropriate
/// corner radius for the current device.
class DeviceCornerRadius {
  DeviceCornerRadius._();

  /// Lookup table mapping screen height (in points) to device corner radius.
  /// Values derived from community research on iOS display specifications.
  /// 
  /// Source: https://kylebashour.com/posts/iphone-screen-corner-radius
  static const Map<int, double> _cornerRadiusByHeight = {
    // iPhone X, XS, 11 Pro (375x812)
    812: 39.0,
    // iPhone XR, 11, 12 mini, 13 mini (375x812 / 360x780)
    780: 44.0,
    // iPhone 12, 12 Pro, 13, 13 Pro, 14 (390x844)
    844: 47.33,
    // iPhone 12 Pro Max, 13 Pro Max, 14 Plus (428x926)
    926: 53.33,
    // iPhone 14 Pro (393x852)
    852: 55.0,
    // iPhone 14 Pro Max (430x932)
    932: 55.0,
    // iPhone 15, 15 Pro (393x852) - same as 14 Pro
    // iPhone 15 Plus, 15 Pro Max (430x932) - same as 14 Pro Max
    // iPhone 16, 16 Plus (393x852 / 430x932) - same as above
    // iPhone 16 Pro (402x874)
    874: 62.0,
    // iPhone 16 Pro Max (440x956)
    956: 62.0,
  };

  /// Returns the device's display corner radius in points.
  /// 
  /// Uses a lookup table based on screen height to determine the radius.
  /// Falls back to 47.0pt if the device is not recognized.
  static double getDeviceCornerRadius(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height.round();
    
    // Direct match
    if (_cornerRadiusByHeight.containsKey(screenHeight)) {
      return _cornerRadiusByHeight[screenHeight]!;
    }
    
    // Find closest match (within 10pt tolerance)
    int? closestHeight;
    int minDiff = 11; // tolerance + 1
    for (final height in _cornerRadiusByHeight.keys) {
      final diff = (height - screenHeight).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestHeight = height;
      }
    }
    
    if (closestHeight != null) {
      return _cornerRadiusByHeight[closestHeight]!;
    }
    
    // Default fallback
    return 47.0;
  }

  /// Computes the ideal card corner radius given the device and margin.
  /// 
  /// The card's corner should follow the device's bezel curve at the
  /// inset distance. This is calculated as:
  /// `cardRadius = deviceCornerRadius - margin`
  /// 
  /// A minimum of 20.0pt is enforced to ensure the card always has
  /// visible rounded corners.
  static double getCardCornerRadius(BuildContext context, double margin) {
    final deviceRadius = getDeviceCornerRadius(context);
    final cardRadius = deviceRadius - margin;
    return cardRadius.clamp(20.0, deviceRadius);
  }
}
