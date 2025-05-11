import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  // Singleton instance
  static final PermissionUtils _instance = PermissionUtils._internal();
  factory PermissionUtils() => _instance;
  PermissionUtils._internal();

  // Camera permission
  Future<bool> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return _handlePermanentlyDeniedPermission(
        context,
        'Camera',
        'To take photos, this app needs camera permission. Please enable it in app settings.'
      );
    }
    
    status = await Permission.camera.request();
    if (!status.isGranted && context.mounted) {
      _showPermissionRationaleSnackBar(
        context,
        'Camera permission is needed to take photos'
      );
    }
    
    return status.isGranted;
  }
  
  // Gallery/Photos permission
  Future<bool> requestGalleryPermission(BuildContext context) async {
    Permission storagePermission;
    
    // Use correct permission depending on Android version
    if (await _isAndroid13OrAbove()) {
      storagePermission = Permission.photos;
    } else {
      storagePermission = Permission.storage;
    }
    
    var status = await storagePermission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return _handlePermanentlyDeniedPermission(
        context,
        'Storage',
        'To access your photos, this app needs storage permission. Please enable it in app settings.'
      );
    }
    
    status = await storagePermission.request();
    if (!status.isGranted && context.mounted) {
      _showPermissionRationaleSnackBar(
        context,
        'Storage permission is needed to select photos'
      );
    }
    
    return status.isGranted;
  }
  
  // Contacts permission
  Future<bool> requestContactsPermission(BuildContext context) async {
    var status = await Permission.contacts.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return _handlePermanentlyDeniedPermission(
        context,
        'Contacts',
        'To access your contacts, this app needs contacts permission. Please enable it in app settings.'
      );
    }
    
    status = await Permission.contacts.request();
    if (!status.isGranted && context.mounted) {
      _showPermissionRationaleSnackBar(
        context,
        'Contacts permission is needed to manage your contacts'
      );
    }
    
    return status.isGranted;
  }
  
  // Phone call permission
  Future<bool> requestCallPhonePermission(BuildContext context) async {
    var status = await Permission.phone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return _handlePermanentlyDeniedPermission(
        context,
        'Phone',
        'To make calls, this app needs phone permission. Please enable it in app settings.'
      );
    }
    
    status = await Permission.phone.request();
    if (!status.isGranted && context.mounted) {
      _showPermissionRationaleSnackBar(
        context,
        'Phone permission is needed to make calls'
      );
    }
    
    return status.isGranted;
  }
  
  // SMS permission - REMOVED
  // SMS permissions are considered sensitive by Google Play Store
  // Using SMS Intent instead, which doesn't require permission
  /*
  Future<bool> requestSmsPermission(BuildContext context) async {
    var status = await Permission.sms.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return _handlePermanentlyDeniedPermission(
        context,
        'SMS',
        'To send SMS messages, this app needs SMS permission. Please enable it in app settings.'
      );
    }
    
    status = await Permission.sms.request();
    if (!status.isGranted && context.mounted) {
      _showPermissionRationaleSnackBar(
        context,
        'SMS permission is needed to send messages'
      );
    }
    
    return status.isGranted;
  }
  */
  
  // Notification permission
  Future<bool> requestNotificationPermission(BuildContext context) async {
    var status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return _handlePermanentlyDeniedPermission(
        context,
        'Notifications',
        'To receive notifications about your reminders and due dates, please enable notifications in app settings.'
      );
    }
    
    status = await Permission.notification.request();
    if (!status.isGranted && context.mounted) {
      _showPermissionRationaleSnackBar(
        context,
        'Notification permission is needed for reminders and alerts'
      );
    }
    
    return status.isGranted;
  }
  
  // Helper to check Android version
  Future<bool> _isAndroid13OrAbove() async {
    return await Permission.photos.status != PermissionStatus.denied || 
           await Permission.videos.status != PermissionStatus.denied;
  }
  
  // Helper to handle permanently denied permissions
  Future<bool> _handlePermanentlyDeniedPermission(
    BuildContext context,
    String permissionName,
    String explanation
  ) async {
    if (!context.mounted) return false;
    
    final bool shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldOpenSettings) {
      await openAppSettings();
      return false; // Return false as we don't know if user granted permission in settings
    }
    
    return false;
  }
  
  // Helper to show permission rationale
  void _showPermissionRationaleSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }
} 