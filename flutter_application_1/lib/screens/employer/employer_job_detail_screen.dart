import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/job_model.dart';
import '../../utils/app_colors.dart';

class EmployerJobDetailScreen extends StatefulWidget {
  final String jobId;

  const EmployerJobDetailScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<EmployerJobDetailScreen> createState() =>
      _EmployerJobDetailScreenState();
}

class _EmployerJobDetailScreenState extends State<EmployerJobDetailScreen> {
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color textSecondary = Color(0xFF757575);

  JobModel? _job;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await jobProvider.fetchEmployerJobs(authProvider.currentUser!.id);

    setState(() {
      _job = jobProvider.myJobs.firstWhere(
        (job) => job.id == widget.jobId,
        orElse: () => JobModel(
          id: '',
          title: '',
          description: '',
          location: '',
          employerId: '',
          jobType: '',
          requirements: '',
          viewCount: 0,
          applicationCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: false,
        ),
      );
      _isLoading = false;
    });
  }

  Future<void> _toggleJobStatus() async {
    if (_job == null) return;

    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await jobProvider.updateJob(
      jobId: _job!.id,
      isActive: !_job!.isActive,
    );

    await jobProvider.fetchEmployerJobs(authProvider.currentUser!.id);

    setState(() {
      _job = jobProvider.myJobs.firstWhere(
        (job) => job.id == widget.jobId,
        orElse: () => _job!,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _job!.isActive
                ? 'Job posting activated'
                : 'Job posting deactivated',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteJob() async {
    if (_job == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job Posting'),
        content: const Text(
          'Are you sure you want to permanently delete this job posting? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await jobProvider.deleteJob(_job!.id);
      await jobProvider.fetchEmployerJobs(authProvider.currentUser!.id);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posting deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editJob() {
    if (_job == null) return;
    context.push('/post-job?jobId=${_job!.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Job Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_job == null || _job!.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Job Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Job not found'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _job!.isActive
                        ? [primaryOrange, secondaryOrange]
                        : [Colors.grey.shade600, Colors.grey.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_job!.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off,
                                    size: 16, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'INACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          _job!.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _job!.companyName ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _editJob,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleJobStatus,
                          icon: Icon(_job!.isActive
                              ? Icons.visibility_off
                              : Icons.visibility),
                          label:
                              Text(_job!.isActive ? 'Deactivate' : 'Activate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _job!.isActive ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _deleteJob,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Job Posting'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Job Information
                  _buildSectionTitle('Job Information'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    children: [
                      _buildInfoRow(Icons.work, 'Job Type', _job!.jobType),
                      const Divider(height: 24),
                      _buildInfoRow(
                          Icons.location_on, 'Location', _job!.location),
                      if (_job!.salaryMin != null ||
                          _job!.salaryMax != null) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.attach_money,
                          'Salary',
                          _job!.salaryMin != null && _job!.salaryMax != null
                              ? 'R${_job!.salaryMin!.toStringAsFixed(0)} - R${_job!.salaryMax!.toStringAsFixed(0)}'
                              : _job!.salaryMin != null
                                  ? 'From R${_job!.salaryMin!.toStringAsFixed(0)}'
                                  : 'Up to R${_job!.salaryMax!.toStringAsFixed(0)}',
                        ),
                      ],
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Posted',
                        DateFormat('MMMM dd, yyyy').format(_job!.createdAt),
                      ),
                      if (_job!.applicationDeadline != null) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.event,
                          'Deadline',
                          DateFormat('MMMM dd, yyyy')
                              .format(_job!.applicationDeadline!),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _buildSectionTitle('Job Description'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    children: [
                      Text(
                        _job!.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Requirements
                  if (_job!.requirements.isNotEmpty) ...[
                    _buildSectionTitle('Requirements'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      children: [
                        Text(
                          _job!.requirements,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Benefits
                  if (_job!.benefits != null && _job!.benefits!.isNotEmpty) ...[
                    _buildSectionTitle('Benefits'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      children: [
                        Text(
                          _job!.benefits!,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
