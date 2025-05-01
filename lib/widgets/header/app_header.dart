import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final double height;
  final bool showMenuIcon;
  final Color backgroundColor;

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.height = kToolbarHeight + 8,  // Default height including padding
    this.showMenuIcon = true,
    this.backgroundColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    // Prevent multiple rebuilds by pre-constructing parts of the UI
    final menuIcon = const Icon(Icons.menu, color: Colors.white, size: 22);
    final backIcon = const Icon(Icons.arrow_back, color: Colors.white, size: 22);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), // Hardcoded color for performance
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false, // Optimize SafeArea to only apply to top
        child: Row(
          children: [
            if (showMenuIcon)
              IconButton(
                icon: menuIcon,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Menu',
              ),
            if (showMenuIcon) 
              const SizedBox(width: 8),
            if (showBackButton)
              IconButton(
                icon: backIcon,
                onPressed: () {
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Back',
              ),
            if (showBackButton) const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis, // Prevent layout issues
              ),
            ),
            ...(actions ?? const []),
          ],
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(height);
}
