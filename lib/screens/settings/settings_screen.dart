import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cross_file/cross_file.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  
  static const routeName = '/settings';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  Future<void> _loadLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('last_backup_date');
    
    if (dateString != null) {
      setState(() {
        final dateTime = DateTime.parse(dateString);
        _lastBackupDate = DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
      });
    }
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final data = await transactionProvider.exportAllData();
      
      // Convert to JSON
      final jsonData = jsonEncode(data);
      
      // Get temporary directory to store the file
      final directory = await getTemporaryDirectory();
      final String fileName = 'byaj_book_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final String filePath = '${directory.path}/$fileName';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonData);
      
      // Share the file using the updated Share API
      await Share.shareXFiles([XFile(filePath)], subject: 'My Byaj Book Backup');
      
      // Create automatic backup too
      await transactionProvider.createAutomaticBackup();
      await _loadLastBackupDate();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      // Pick a file using file_selector
      final XTypeGroup jsonTypeGroup = XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
      );
      
      final XFile? pickedFile = await openFile(
        acceptedTypeGroups: [jsonTypeGroup],
      );
      
      if (pickedFile == null) {
        setState(() {
          _isImporting = false;
        });
        return;
      }
      
      final String jsonString = await pickedFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: const Text(
            'Importing will replace all current data. Are you sure you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        final success = await transactionProvider.importAllData(jsonData);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported successfully'))
          );
          
          // Update last backup date
          await _loadLastBackupDate();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to import data'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing data: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _restoreFromAutoBackup() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore from Backup'),
          content: const Text(
            'This will restore data from the last automatic backup. Continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        final success = await transactionProvider.restoreFromAutomaticBackup();
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data restored successfully'))
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to restore data or no backup found'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring data: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Data management section
          _buildSectionHeader('Data Management'),
          
          // Backup data
          _buildSettingItem(
            title: 'Backup Data',
            subtitle: 'Export all contacts and transactions',
            icon: Icons.backup,
            onTap: _isExporting ? null : _exportData,
            trailing: _isExporting 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) 
              : const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          
          // Restore data
          _buildSettingItem(
            title: 'Restore Data',
            subtitle: 'Import from a backup file',
            icon: Icons.restore,
            onTap: _isImporting ? null : _importData,
            trailing: _isImporting 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) 
              : const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          
          // Auto backup info
          _buildSettingItem(
            title: 'Auto Backup & Sync',
            subtitle: 'Coming soon!',
            icon: Icons.sync,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This feature will be available soon!'))
              );
            },
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SOON',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
            ),
          ),
            
          const Divider(),
          
          // App information section
          _buildSectionHeader('About'),
          
          // Version info
          _buildSettingItem(
            title: 'Version',
            subtitle: '1.0.0',
            icon: Icons.info_outline,
            onTap: null,
          ),
          
          // Privacy policy
          _buildSettingItem(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              // Show privacy policy
            },
          ),
          
          // Terms of service
          _buildSettingItem(
            title: 'Terms of Service',
            icon: Icons.description_outlined,
            onTap: () {
              // Show terms of service
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
} 