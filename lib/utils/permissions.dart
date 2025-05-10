// Export permission handler class
export 'permission_handler.dart';

// Additional permission utilities for easy importing
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_byaj_book/utils/permission_handler.dart';

/// Quick utility to check if a permission is granted without showing UI
Future<bool> isPermissionGranted(Permission permission) async {
  final status = await permission.status;
  return status.isGranted;
}

/// Request a specific permission with context for UI
Future<bool> requestPermission(Permission permission, BuildContext context) async {
  final permissionUtils = PermissionUtils();
  
  switch (permission) {
    case Permission.camera:
      return await permissionUtils.requestCameraPermission(context);
    case Permission.photos:
    case Permission.storage:
      return await permissionUtils.requestGalleryPermission(context);
    case Permission.contacts:
      return await permissionUtils.requestContactsPermission(context);
    case Permission.phone:
      return await permissionUtils.requestCallPhonePermission(context);
    case Permission.sms:
      return await permissionUtils.requestSmsPermission(context);
    case Permission.notification:
      return await permissionUtils.requestNotificationPermission(context);
    default:
      // For other permissions, use the basic permission flow
      final status = await permission.request();
      return status.isGranted;
  }
} 