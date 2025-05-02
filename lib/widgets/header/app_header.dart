import 'package:flutter/material.dart';
import 'package:my_byaj_book/constants/app_theme.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final double height;

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.height = kToolbarHeight + 8,  // Default height including padding
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false, // Optimize SafeArea to only apply to top
        child: Row(
          children: [
            // Menu or back button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  if (showBackButton) {
                    Navigator.pop(context);
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    showBackButton ? Icons.arrow_back : Icons.menu,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Build action buttons with proper tap areas
            if (actions != null) ..._buildActionButtons(actions!),
          ],
        ),
      ),
    );
  }
  
  // Helper method to wrap action buttons with proper tap areas
  List<Widget> _buildActionButtons(List<Widget> actions) {
    return actions.map((widget) {
      if (widget is IconButton) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: widget.icon,
            ),
          ),
        );
      }
      return widget;
    }).toList();
  }
  
  @override
  Size get preferredSize => Size.fromHeight(height);
}
