import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/location_service.dart';

class PostJobScreen extends StatefulWidget {
  final String? jobId; // For editing existing job

  const PostJobScreen({super.key, this.jobId});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();

  String _selectedJobType = 'full-time';
  DateTime? _applicationDeadline;
  bool _isPosting = false;

  // Location coordinates for "Jobs Near Me" feature
  double? _latitude;
  double? _longitude;
  bool _isGettingCoordinates = false;

  final List<String> _jobTypes = [
    'full-time',
    'part-time',
    'contract',
    'internship',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      _loadJobData();
    }
  }

  Future<void> _loadJobData() async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await jobProvider.fetchEmployerJobs(authProvider.currentUser!.id);

    final job = jobProvider.myJobs.firstWhere(
      (j) => j.id == widget.jobId,
      orElse: () => jobProvider.myJobs.first,
    );

    setState(() {
      _titleController.text = job.title;
      _locationController.text = job.location;
      _descriptionController.text = job.description;
      _requirementsController.text = job.requirements;
      _benefitsController.text = job.benefits ?? '';
      _selectedJobType = job.jobType;
      if (job.salaryMin != null) {
        _minSalaryController.text = job.salaryMin!.toStringAsFixed(0);
      }
      if (job.salaryMax != null) {
        _maxSalaryController.text = job.salaryMax!.toStringAsFixed(0);
      }
      _applicationDeadline = job.applicationDeadline;
      _latitude = job.latitude;
      _longitude = job.longitude;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _applicationDeadline = picked;
      });
    }
  }

  Future<void> _getCoordinates() async {
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a location first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isGettingCoordinates = true);

    try {
      final position = await LocationService.getCoordinatesFromLocation(
        '${_locationController.text.trim()}, Free State, South Africa',
      );

      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📍 Coordinates found: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not find coordinates for this location. Job will still be posted.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting coordinates: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isGettingCoordinates = false);
    }
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isPosting = false);
      return;
    }

    String? error;

    if (widget.jobId != null) {
      // Update existing job
      error = await jobProvider.updateJob(
        jobId: widget.jobId!,
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        jobType: _selectedJobType,
        description: _descriptionController.text.trim(),
        requirements: _requirementsController.text.trim(),
        benefits: _benefitsController.text.trim().isNotEmpty
            ? _benefitsController.text.trim()
            : null,
        salaryMin: _minSalaryController.text.isNotEmpty
            ? double.tryParse(_minSalaryController.text)
            : null,
        salaryMax: _maxSalaryController.text.isNotEmpty
            ? double.tryParse(_maxSalaryController.text)
            : null,
        applicationDeadline: _applicationDeadline,
        latitude: _latitude,
        longitude: _longitude,
      );
    } else {
      // Create new job
      error = await jobProvider.createJob(
        employerId: authProvider.currentUser!.id,
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        jobType: _selectedJobType,
        description: _descriptionController.text.trim(),
        requirements: _requirementsController.text.trim(),
        benefits: _benefitsController.text.trim().isNotEmpty
            ? _benefitsController.text.trim()
            : null,
        salaryMin: _minSalaryController.text.isNotEmpty
            ? double.tryParse(_minSalaryController.text)
            : null,
        salaryMax: _maxSalaryController.text.isNotEmpty
            ? double.tryParse(_maxSalaryController.text)
            : null,
        applicationDeadline: _applicationDeadline,
        latitude: _latitude,
        longitude: _longitude,
      );
    }

    setState(() => _isPosting = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.jobId != null
                ? 'Job updated successfully!'
                : 'Job posted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/employer-home');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobId != null ? 'Edit Job' : 'Post a Job'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/employer-home'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Job Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),

              // Job Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Job Title',
                  hintText: 'e.g., Software Developer',
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter job title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Location Dropdown
              DropdownButtonFormField<String>(
                initialValue: _locationController.text.isNotEmpty
                    ? _locationController.text
                    : null,
                decoration: InputDecoration(
                  labelText: 'Location',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Bloemfontein',
                    child: Text('Bloemfontein'),
                  ),
                  DropdownMenuItem(
                    value: 'Botshabelo',
                    child: Text('Botshabelo'),
                  ),
                  DropdownMenuItem(
                    value: 'ThabaNchu',
                    child: Text('ThabaNchu'),
                  ),
                  DropdownMenuItem(
                    value: 'Dewetsdorp',
                    child: Text('Dewetsdorp'),
                  ),
                  DropdownMenuItem(
                    value: 'Wepener',
                    child: Text('Wepener'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _locationController.text = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Get Coordinates Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGettingCoordinates ? null : _getCoordinates,
                  icon: _isGettingCoordinates
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.my_location, size: 20),
                  label: Text(_isGettingCoordinates
                      ? 'Getting coordinates...'
                      : _latitude != null && _longitude != null
                          ? 'Coordinates found'
                          : 'Get Coordinates for Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _latitude != null && _longitude != null
                        ? Colors.green
                        : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Job Type
              DropdownButtonFormField<String>(
                initialValue: _selectedJobType,
                decoration: InputDecoration(
                  labelText: 'Job Type',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _jobTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type
                          .split('-')
                          .map((word) =>
                              word[0].toUpperCase() + word.substring(1))
                          .join(' '),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedJobType = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Salary Range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min Salary (R)',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'R',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max Salary (R)',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'R',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Application Deadline
              InkWell(
                onTap: _selectDeadline,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Application Deadline (Optional)',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: Text(
                    _applicationDeadline != null
                        ? '${_applicationDeadline!.day}/${_applicationDeadline!.month}/${_applicationDeadline!.year}'
                        : 'Select deadline',
                    style: TextStyle(
                      color: _applicationDeadline != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Job Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      'Describe the role, responsibilities, and what makes this position unique...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter job description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Requirements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Requirements
              TextFormField(
                controller: _requirementsController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      'List the qualifications, skills, and experience required...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter job requirements';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Benefits (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Benefits
              TextFormField(
                controller: _benefitsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'List the benefits and perks of this position...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Post Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _postJob,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(widget.jobId != null ? 'Update Job' : 'Post Job'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
