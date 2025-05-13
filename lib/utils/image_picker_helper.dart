import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_byaj_book/utils/permission_handler.dart';

class ImagePickerHelper {
  // Singleton instance
  static final ImagePickerHelper _instance = ImagePickerHelper._internal();
  factory ImagePickerHelper() => _instance;
  ImagePickerHelper._internal();

  // Pick an image from camera or gallery with permission handling
  Future<File?> pickImage(BuildContext context, ImageSource source) async {
    final permissionUtils = PermissionUtils();
    bool hasPermission = false;
    
    // Request appropriate permission based on source
    if (source == ImageSource.camera) {
      hasPermission = await permissionUtils.requestCameraPermission(context);
    } else {
      hasPermission = await permissionUtils.requestGalleryPermission(context);
    }
    
    // Return null if permission not granted
    if (!hasPermission) {
      return null;
    }
    
    try {
      // Pick the image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );
      
      // Return the file if picked
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
    
    return null;
  }
  
  // Show image source selection bottom sheet
  Future<File?> showImageSourceDialog(BuildContext context, {File? currentImage}) async {
    File? resultImage;
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera option
                _buildSourceOption(
                  context: context,
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(context);
                    resultImage = await pickImage(context, ImageSource.camera);
                  },
                ),
                
                // Gallery option
                _buildSourceOption(
                  context: context,
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    resultImage = await pickImage(context, ImageSource.gallery);
                  },
                ),
                
                // Remove option (if current image exists)
                if (currentImage != null)
                  _buildSourceOption(
                    context: context,
                    icon: Icons.delete,
                    label: 'Remove',
                    onTap: () {
                      Navigator.pop(context);
                      resultImage = null;
                      // Signal that image should be removed by returning empty file
                      // This will be handled by the caller
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    
    return resultImage;
  }
  
  // Helper method to build image source option
  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(icon, size: 30, color: primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 