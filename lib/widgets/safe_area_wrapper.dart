import 'package:flutter/material.dart';

/// A utility widget that ensures content is not hidden behind system UI elements like 
/// navigation bars, notches, or status bars.
/// 
/// This widget automatically detects the safe area and adjusts content accordingly.
class SafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;
  
  const SafeAreaWrapper({
    Key? key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Get bottom padding to check if device has navigation buttons
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasNavButtons = bottomPadding > 0;
    
    return SafeArea(
      top: top,
      bottom: bottom, 
      left: left,
      right: right,
      minimum: minimum,
      // Add extra padding if the device has navigation buttons
      child: Padding(
        padding: EdgeInsets.only(bottom: hasNavButtons ? 8.0 : 0.0),
        child: child,
      ),
    );
  }
} 