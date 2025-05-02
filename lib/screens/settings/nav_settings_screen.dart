import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/nav_preferences_provider.dart';
import '../../constants/app_theme.dart';

class NavSettingsScreen extends StatefulWidget {
  static const routeName = '/nav-settings';

  const NavSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NavSettingsScreen> createState() => _NavSettingsScreenState();
}

class _NavSettingsScreenState extends State<NavSettingsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });
    
    await Provider.of<NavPreferencesProvider>(context, listen: false)
        .loadPreferences();
        
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Navigation'),
        content: const Text(
          'This will reset your navigation bar to default settings. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      await Provider.of<NavPreferencesProvider>(context, listen: false)
          .resetToDefaults();
          
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation bar reset to defaults'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Navigation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to the home screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Reset',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<NavPreferencesProvider>(
              builder: (ctx, provider, child) {
                // Get the fixed items count
                final fixedItemsCount = provider.allNavItems
                    .where((item) => item.isFixed)
                    .length;
                
                // Calculate how many more items can be selected
                final maxSelectableItems = 5 - fixedItemsCount;
                final selectedCount = provider.selectedNavItems.length - fixedItemsCount;
                
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade100,
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Customize your bottom navigation bar by selecting up to 4 additional items',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selected: $selectedCount/$maxSelectableItems',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selectedCount >= maxSelectableItems
                                  ? Colors.red
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Show fixed items (Home) first in a disabled state
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.purple.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Default Navigation Item',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...provider.allNavItems
                            .where((item) => item.isFixed)
                            .map((item) => ListTile(
                              leading: Icon(
                                item.icon,
                                color: AppTheme.primaryColor,
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 6
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ))
                            .toList(),
                        ],
                      ),
                    ),
                    
                    // Section title for selectable items
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: const Text(
                        'AVAILABLE ITEMS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    // Show the list of selectable items
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.availableNavItems.length,
                        itemBuilder: (ctx, index) {
                          final navItem = provider.availableNavItems[index];
                          final isSelected = provider.isSelected(navItem.id);
                          final isDisabled = !isSelected && 
                              selectedCount >= maxSelectableItems;
                              
                          return ListTile(
                            leading: Icon(
                              navItem.icon,
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : isDisabled
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                            ),
                            title: Text(
                              navItem.title,
                              style: TextStyle(
                                fontWeight: isSelected 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: isDisabled
                                    ? Colors.grey.shade400
                                    : null,
                              ),
                            ),
                            trailing: Switch(
                              value: isSelected,
                              onChanged: isDisabled
                                  ? null
                                  : (_) => provider.toggleNavItem(navItem.id),
                              activeColor: AppTheme.primaryColor,
                            ),
                            onTap: isDisabled
                                ? null
                                : () => provider.toggleNavItem(navItem.id),
                          );
                        },
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.amber.shade100,
                      child: Row(
                        children: const [
                          Icon(Icons.lightbulb_outline, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The center button will always be available for quick access to all tools',
                              style: TextStyle(color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
} 