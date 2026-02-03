import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/change_password_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _workExperienceController = TextEditingController();
  final _educationController = TextEditingController();

  bool _isEditing = true;
  bool _isSaving = false;
  File? _imageFile;
  File? _documentFile;
  String? _documentName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phoneNumber;
      _bioController.text = user.bio ?? '';
      _skillsController.text = user.skills?.join(', ') ?? '';
      _workExperienceController.text = user.workExperience ?? '';
      _educationController.text = user.education ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _workExperienceController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  // Pick and crop image using StorageService
  Future<void> _pickAndCropImage() async {
    try {
      final file = await StorageService.pickAndCropProfilePicture(context);

      if (file != null) {
        debugPrint('✅ Image selected: ${file.path}');
        debugPrint('✅ File exists: ${await file.exists()}');
        debugPrint('✅ File size: ${await file.length()} bytes');

        setState(() {
          _imageFile = file;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile picture selected! Save to upload.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('❌ No image selected or cropping cancelled');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _documentFile = File(result.files.single.path!);
        _documentName = result.files.single.name;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? profilePictureUrl;
    String? documentUrl;

    // Upload profile picture if changed
    if (_imageFile != null && authProvider.currentUser != null) {
      profilePictureUrl = await StorageService.uploadProfilePicture(
        authProvider.currentUser!.id,
        _imageFile!,
      );

      if (profilePictureUrl == null) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile picture'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    // Upload document if selected
    if (_documentFile != null && authProvider.currentUser != null) {
      documentUrl = await StorageService.uploadDocument(
        authProvider.currentUser!.id,
        _documentFile!,
        _documentName ?? 'document',
      );
    }

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final error = await authProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      bio: _bioController.text.trim().isNotEmpty
          ? _bioController.text.trim()
          : null,
      skills: skills.isNotEmpty ? skills : null,
      workExperience: _workExperienceController.text.trim().isNotEmpty
          ? _workExperienceController.text.trim()
          : null,
      education: _educationController.text.trim().isNotEmpty
          ? _educationController.text.trim()
          : null,
      profilePictureUrl: profilePictureUrl,
      documentUrl: documentUrl,
    );

    setState(() => _isSaving = false);

    if (error == null) {
      setState(() {
        _isEditing = false;
        _imageFile =
            null; // Clear the selected image file after successful upload
        _documentFile = null; // Clear document file as well
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  Future<void> _viewDocument(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL is invalid'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);

      // Try to launch the URL directly
      // Firebase Storage URLs are HTTPS URLs that should open in browsers
      // which can then trigger the appropriate native app
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        // If external application fails, try with platform default
        // This will open in browser which can trigger native apps
        final browserLaunched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );

        if (!browserLaunched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unable to open document. Please check your internet connection.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(String url, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Delete from Storage
      await StorageService.deleteFile(url);

      // Remove from user's documents array in Firestore
      final currentDocs = authProvider.currentUser?.documents ?? [];
      final updatedDocs =
          currentDocs.where((doc) => doc['url'] != url).toList();

      // Update the documents field directly in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authProvider.currentUser!.id)
          .update({'documents': updatedDocs});

      // Reload user data
      await authProvider.reloadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    if (_isEditing) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
              'You have unsaved changes. Do you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return shouldDiscard ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          // Check if we can pop, if not use go_router to navigate back
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            // Navigate to home using go_router
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final route = authProvider.userType == 'job_seeker'
                ? '/home'
                : '/employer-home';
            context.go(route);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                // Check if we can pop, if not use go_router to navigate back
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  // Navigate to home using go_router
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final route = authProvider.userType == 'job_seeker'
                      ? '/home'
                      : '/employer-home';
                  context.go(route);
                }
              }
            },
          ),
          title: const Text('Edit Profile'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: gradient),
          ),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
              ),
            if (_isEditing)
              TextButton(
                onPressed: () {
                  setState(() => _isEditing = false);
                  _loadUserData();
                },
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;
            if (user == null) {
              return const Center(child: Text('No user data'));
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Picture with improved UI
                    Center(
                      child: Stack(
                        children: [
                          // Profile picture with loading state
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF6B35),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF6B35).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              key: ValueKey(_imageFile?.path ??
                                  user.profilePictureUrl ??
                                  'no-image'),
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : (user.profilePictureUrl != null &&
                                          user.profilePictureUrl!.isNotEmpty
                                      ? NetworkImage(user.profilePictureUrl!)
                                          as ImageProvider
                                      : null),
                              child: _imageFile == null &&
                                      (user.profilePictureUrl == null ||
                                          user.profilePictureUrl!.isEmpty)
                                  ? Text(
                                      user.fullName.isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        color: Color(0xFFFF6B35),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),

                          // Edit button
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: gradient,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B35)
                                          .withOpacity(0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 22),
                                  onPressed: _pickAndCropImage,
                                  tooltip: 'Change profile picture',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _isEditing ? Colors.white : Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _isEditing ? Colors.white : Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      enabled: _isEditing,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself...',
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _isEditing ? Colors.white : Colors.grey[100],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Skills
                    TextFormField(
                      controller: _skillsController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Skills',
                        hintText: 'Flutter, Dart, Firebase (comma separated)',
                        prefixIcon: const Icon(Icons.stars_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _isEditing ? Colors.white : Colors.grey[100],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Work Experience
                    TextFormField(
                      controller: _workExperienceController,
                      enabled: _isEditing,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Work Experience',
                        hintText: 'Describe your work experience...',
                        prefixIcon: const Icon(Icons.work_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _isEditing ? Colors.white : Colors.grey[100],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Education
                    TextFormField(
                      controller: _educationController,
                      enabled: _isEditing,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Education',
                        hintText: 'Describe your education...',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _isEditing ? Colors.white : Colors.grey[100],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Document Upload
                    if (_isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Document (CV/Resume)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: gradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: _pickDocument,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Choose File'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _documentName ?? 'No file selected',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Uploaded Documents Section
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final documents = authProvider.currentUser?.documents;
                        if (documents == null || documents.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Uploaded Documents',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...documents.map((doc) {
                              final fileName = doc['name'] ?? 'Document';
                              final fileUrl = doc['url'] ?? '';
                              final uploadedAt = doc['uploadedAt'] ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.insert_drive_file,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  title: Text(
                                    fileName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: uploadedAt.isNotEmpty
                                      ? Text(
                                          'Uploaded: ${_formatDate(uploadedAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        )
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        color: Colors.blue,
                                        onPressed: () => _viewDocument(fileUrl),
                                        tooltip: 'View Document',
                                      ),
                                      if (_isEditing)
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _deleteDocument(
                                              fileUrl, fileName),
                                          tooltip: 'Delete Document',
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Save Button with Gradient
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showChangePasswordDialog(context);
                        },
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Change Password'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: Color(0xFFFF6B35), width: 2),
                          foregroundColor: const Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
