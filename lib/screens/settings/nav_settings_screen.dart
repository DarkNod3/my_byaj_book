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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Settings'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<NavPreferencesProvider>(
              builder: (context, provider, _) {
                final selectedTools = provider.selectedTools;
                final allTools = provider.allTools;
                final unselectedTools = provider.unselectedTools;
                
                return Column(
                  children: [
                    // Fixed Home item
                    _buildFixedHomeItem(provider.homeItem),
                    
                    // List of selected tools with reordering
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'SELECTED TOOLS (MAX 3)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          if (selectedTools.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _showReorderTools(context, provider);
                              },
                              child: Text(
                                'Reorder',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Selected tools list
                    if (selectedTools.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No tools selected. Choose up to 3 tools below.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: selectedTools.map((tool) => 
                          _buildSelectedToolItem(context, tool, provider)
                        ).toList(),
                      ),
                      
                    // Available unselected tools
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'AVAILABLE TOOLS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            selectedTools.length == 3 ? 'Remove a tool to add another' : 'Tap to add',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // List of unselected tools
                    if (unselectedTools.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'All tools have been selected.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: unselectedTools.map((tool) => 
                          _buildUnselectedToolItem(context, tool, provider, selectedTools.length >= 3)
                        ).toList(),
                      ),
                      
                    // Reset to defaults button
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: OutlinedButton(
                        onPressed: () {
                          _showResetConfirmation(context, provider);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade700),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Reset to Defaults'),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
  
  Widget _buildFixedHomeItem(NavItem homeItem) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              homeItem.icon,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fixed Navigation Item',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  homeItem.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This item is always shown in the bottom navigation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSelectedToolItem(BuildContext context, NavItem tool, NavPreferencesProvider provider) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          tool.icon,
          color: Colors.blue.shade700,
        ),
      ),
      title: Text(
        tool.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: const Text('Appears in bottom navigation'),
      trailing: IconButton(
        icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
        onPressed: () {
          provider.removeTool(tool.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tool.title} removed from bottom navigation'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () => provider.addTool(tool.id),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildUnselectedToolItem(BuildContext context, NavItem tool, NavPreferencesProvider provider, bool isDisabled) {
    return ListTile(
      enabled: !isDisabled,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDisabled ? Colors.grey.shade100 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          tool.icon,
          color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
      title: Text(
        tool.title,
        style: TextStyle(
          color: isDisabled ? Colors.grey.shade400 : null,
        ),
      ),
      subtitle: Text(
        isDisabled ? 'Remove a selected tool first' : 'Available to add',
        style: TextStyle(
          color: isDisabled ? Colors.grey.shade400 : null,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.add_circle_outline,
          color: isDisabled ? Colors.grey.shade400 : Colors.green.shade400,
        ),
        onPressed: isDisabled
            ? null
            : () {
                provider.addTool(tool.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${tool.title} added to bottom navigation'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
      ),
      onTap: isDisabled
          ? null
          : () {
              provider.addTool(tool.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${tool.title} added to bottom navigation'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
    );
  }
  
  void _showReorderTools(BuildContext context, NavPreferencesProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedTools = provider.selectedTools;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reorder Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Drag to reorder tools in the bottom navigation bar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderTools(oldIndex, newIndex);
                      setState(() {});
                    },
                    children: selectedTools
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final tool = entry.value;
                          
                          return ListTile(
                            key: ValueKey(tool.id),
                            leading: Icon(tool.icon, color: Colors.blue.shade700),
                            title: Text(tool.title),
                            trailing: const Icon(Icons.drag_handle),
                          );
                        })
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.blue.shade700,
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showResetConfirmation(BuildContext context, NavPreferencesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Navigation'),
        content: const Text(
          'This will reset your bottom navigation to the default tools. Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigation reset to defaults'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
} 