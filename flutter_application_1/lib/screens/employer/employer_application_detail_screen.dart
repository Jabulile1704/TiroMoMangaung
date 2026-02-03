import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../providers/application_provider.dart';
import '../../utils/app_colors.dart';

class EmployerApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const EmployerApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<EmployerApplicationDetailScreen> createState() =>
      _EmployerApplicationDetailScreenState();
}

class _EmployerApplicationDetailScreenState
    extends State<EmployerApplicationDetailScreen> {
  ApplicationModel? _application;
  UserModel? _applicant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicationDetails();
  }

  Future<void> _loadApplicationDetails() async {
    try {
      // Load application
      final appDoc = await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .get();

      if (!appDoc.exists) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      final application = ApplicationModel.fromFirestore(appDoc);

      // Load applicant details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(application.seekerId)
          .get();

      if (mounted) {
        setState(() {
          _application = application;
          _applicant = userDoc.exists ? UserModel.fromFirestore(userDoc) : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading application details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);

    final error = await applicationProvider.updateApplicationStatus(
      applicationId: widget.applicationId,
      status: newStatus,
    );

    if (error == null) {
      await _loadApplicationDetails(); // Reload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application status updated to: $newStatus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _viewDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched && mounted) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
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

  Future<void> _deleteApplication() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: Text(
          'Are you sure you want to permanently delete this withdrawn application from ${_applicant?.fullName ?? "this applicant"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);

    final error =
        await applicationProvider.deleteApplication(widget.applicationId);

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to applications list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Application Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_application == null || _applicant == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Application Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: Text('Application not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _application!.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _application!.statusColor),
              ),
              child: Text(
                _application!.statusDisplayName,
                style: TextStyle(
                  color: _application!.statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Applicant Information
            _buildSectionTitle('Applicant Information'),
            const SizedBox(height: 12),
            _buildInfoCard(
              children: [
                _buildInfoRow(Icons.person, 'Name', _applicant!.fullName),
                _buildInfoRow(Icons.email, 'Email', _applicant!.email),
                if (_applicant!.phoneNumber.isNotEmpty)
                  _buildInfoRow(Icons.phone, 'Phone', _applicant!.phoneNumber),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Applied On',
                  DateFormat('MMM dd, yyyy').format(_application!.appliedAt),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Job Applied For
            _buildSectionTitle('Job Applied For'),
            const SizedBox(height: 12),
            _buildInfoCard(
              children: [
                _buildInfoRow(
                    Icons.work, 'Position', _application!.jobTitle ?? 'N/A'),
              ],
            ),

            const SizedBox(height: 24),

            // Bio
            if (_applicant!.bio != null && _applicant!.bio!.isNotEmpty) ...[
              _buildSectionTitle('About'),
              const SizedBox(height: 12),
              _buildInfoCard(
                children: [
                  Text(
                    _applicant!.bio!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Skills
            if (_applicant!.skills != null &&
                _applicant!.skills!.isNotEmpty) ...[
              _buildSectionTitle('Skills'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _applicant!.skills!.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Education
            if (_applicant!.education != null &&
                _applicant!.education!.isNotEmpty) ...[
              _buildSectionTitle('Education'),
              const SizedBox(height: 12),
              _buildInfoCard(
                children: [
                  Text(
                    _applicant!.education!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Work Experience
            if (_applicant!.workExperience != null &&
                _applicant!.workExperience!.isNotEmpty) ...[
              _buildSectionTitle('Work Experience'),
              const SizedBox(height: 12),
              _buildInfoCard(
                children: [
                  Text(
                    _applicant!.workExperience!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Cover Letter
            if (_application!.coverLetter != null &&
                _application!.coverLetter!.isNotEmpty) ...[
              _buildSectionTitle('Cover Letter'),
              const SizedBox(height: 12),
              _buildInfoCard(
                children: [
                  Text(
                    _application!.coverLetter!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Uploaded Documents
            if (_application!.documents != null &&
                _application!.documents!.isNotEmpty) ...[
              _buildSectionTitle('Uploaded Documents'),
              const SizedBox(height: 12),
              _buildInfoCard(
                children: _application!.documents!.map((doc) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file,
                        color: AppColors.primary),
                    title: Text(doc['name'] ?? 'Document'),
                    subtitle: Text(
                      'Uploaded: ${_formatDate(doc['uploadedAt'] ?? '')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility,
                          color: AppColors.primary),
                      onPressed: () => _viewDocument(doc['url'] ?? ''),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            _buildSectionTitle('Actions'),
            const SizedBox(height: 12),

            // Show warning for withdrawn applications
            if (_application!.isWithdrawn) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Application Withdrawn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This application was withdrawn by the job seeker on ${DateFormat('MMM dd, yyyy').format(_application!.updatedAt)}.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Only show delete button for withdrawn applications
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deleteApplication,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Application'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // Regular action buttons for non-withdrawn applications
              Row(
                children: [
                  if (_application!.status == 'pending') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('shortlisted'),
                        icon: const Icon(Icons.star),
                        label: const Text('Shortlist'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('rejected'),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  if (_application!.status == 'shortlisted') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('hired'),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Hire'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('rejected'),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
