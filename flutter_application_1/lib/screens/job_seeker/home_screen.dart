import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/application_provider.dart';
import '../../models/application_model.dart';
import '../../widgets/job_card.dart';
import '../../widgets/search_filters.dart';
import '../../widgets/email_verification_banner.dart';
import '../../widgets/jobs_near_me_button.dart';
import '../../services/notification_service.dart';
import 'interview_prep_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  // Orange gradient colors
  static const Color primaryOrange = Color(0xFFFF6B35);

  // Supporting colors
  static const Color backgroundColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      jobProvider.fetchJobs();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          const EmailVerificationBanner(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _HomeTab(searchController: _searchController),
                _SavedJobsTab(),
                _ApplicationsTab(),
                _ProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60,
        backgroundColor: backgroundColor,
        color: primaryOrange,
        buttonBackgroundColor: Colors.deepOrange,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.bookmark, size: 30, color: Colors.white),
          Icon(Icons.work, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final TextEditingController searchController;

  const _HomeTab({required this.searchController});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color lightOrange = Color(0xFFFFAA64);
  static const Color errorColor = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
  }

  // Perform search
  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Perform actual search
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.updateSearchFilters(searchQuery: query);
    jobProvider.fetchJobs();
  }

  void _showSearchFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchFilters(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App Bar with Orange Gradient
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: primaryOrange,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryOrange, secondaryOrange, lightOrange],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final name =
                                      authProvider.currentUser?.fullName ??
                                          'User';
                                  return Text(
                                    'Hello, ${name.split(' ').first}!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              const Text(
                                'Find your dream job today',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          // Notifications
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              if (authProvider.currentUser == null) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.notifications_outlined),
                                    color: Colors.white,
                                    onPressed: () {
                                      context.go('/notifications');
                                    },
                                  ),
                                );
                              }
                              return StreamBuilder<int>(
                                stream: NotificationService.getUnreadCount(
                                    authProvider.currentUser!.id),
                                builder: (context, snapshot) {
                                  final unreadCount = snapshot.data ?? 0;
                                  return Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.notifications_outlined),
                                          color: Colors.white,
                                          onPressed: () {
                                            context.go('/notifications');
                                          },
                                        ),
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 18,
                                              minHeight: 18,
                                            ),
                                            child: Text(
                                              unreadCount > 9
                                                  ? '9+'
                                                  : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Search Bar Section (outside SliverAppBar to avoid overflow)
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryOrange, secondaryOrange, lightOrange],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search jobs...',
                    prefixIcon: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [primaryOrange, secondaryOrange],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clear button
                        if (widget.searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              widget.searchController.clear();
                              setState(() {});
                            },
                          ),
                        // Filter button
                        IconButton(
                          icon: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [primaryOrange, secondaryOrange],
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.filter_list,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: _showSearchFilters,
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: _performSearch,
                ),
              ),
            ),
          ),
        ),

        // Job Listings
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Jobs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Jobs Near Me Button
                const JobsNearMeButton(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Jobs List
        Consumer<JobProvider>(
          builder: (context, jobProvider, child) {
            if (jobProvider.isLoading) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: primaryOrange),
                  ),
                ),
              );
            }

            if (jobProvider.error != null) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Error loading jobs',
                          style: TextStyle(color: errorColor),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryOrange, secondaryOrange],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ElevatedButton(
                            onPressed: () => jobProvider.fetchJobs(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (jobProvider.jobs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No jobs found'),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final job = jobProvider.jobs[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: JobCard(
                      job: job,
                      onTap: () => context.go('/job/${job.id}'),
                      userLatitude: jobProvider.userLatitude,
                      userLongitude: jobProvider.userLongitude,
                    ),
                  );
                },
                childCount: jobProvider.jobs.length,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Don't dispose the controller here as it's owned by the parent
    super.dispose();
  }
}

class _SavedJobsTab extends StatefulWidget {
  @override
  State<_SavedJobsTab> createState() => _SavedJobsTabState();
}

class _SavedJobsTabState extends State<_SavedJobsTab> {
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color textSecondary = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        jobProvider.fetchSavedJobs(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          if (jobProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryOrange),
            );
          }

          if (jobProvider.savedJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryOrange.withOpacity(0.2),
                          primaryOrange.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved jobs yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: textSecondary,
                    ),
                  ),
                  const Text(
                    'Save jobs you\'re interested in to view them here',
                    style: TextStyle(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobProvider.savedJobs.length,
            itemBuilder: (context, index) {
              final job = jobProvider.savedJobs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: JobCard(
                  job: job,
                  onTap: () => context.go('/job/${job.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ApplicationsTab extends StatefulWidget {
  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color textSecondary = Color(0xFF757575);
  static const Color errorColor = Color(0xFFF44336);

  String _selectedStatus = 'all'; // Filter state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final applicationProvider =
          Provider.of<ApplicationProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        applicationProvider.fetchMyApplications(authProvider.currentUser!.id);
      }
    });
  }

  List<ApplicationModel> _filterApplications(
      List<ApplicationModel> applications) {
    if (_selectedStatus == 'all') {
      return applications;
    }
    return applications.where((app) => app.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, applicationProvider, child) {
          if (applicationProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryOrange),
            );
          }

          if (applicationProvider.myApplications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryOrange.withOpacity(0.2),
                          primaryOrange.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work_outline,
                      size: 64,
                      color: primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No applications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: textSecondary,
                    ),
                  ),
                  const Text(
                    'Start applying to jobs to see your applications here',
                    style: TextStyle(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final filteredApplications =
              _filterApplications(applicationProvider.myApplications);

          return Column(
            children: [
              // Filter Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: textSecondary),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter by:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryOrange.withOpacity(0.1),
                              primaryOrange.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryOrange.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: primaryOrange),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStatus = newValue!;
                              });
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Applications'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'shortlisted',
                                child: Text('Shortlisted'),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Text('Rejected'),
                              ),
                              DropdownMenuItem(
                                value: 'hired',
                                child: Text('Hired'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Results count
              if (filteredApplications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${filteredApplications.length} ${filteredApplications.length == 1 ? 'application' : 'applications'}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              // Applications List
              Expanded(
                child: filteredApplications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${_selectedStatus == 'all' ? '' : _selectedStatus} applications found',
                              style: const TextStyle(
                                fontSize: 16,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredApplications.length,
                        itemBuilder: (context, index) {
                          final application = filteredApplications[index];
                          final canWithdraw = application.status == 'pending' ||
                              application.status == 'shortlisted';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      application.statusColor.withOpacity(0.3),
                                      application.statusColor.withOpacity(0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    _getStatusIcon(application.status),
                                    color: application.statusColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                              title: Text(
                                application.jobTitle ?? 'Job Application',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (application.companyName != null)
                                    Text(application.companyName!),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              application.statusColor
                                                  .withOpacity(0.2),
                                              application.statusColor
                                                  .withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: application.statusColor
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          application.statusDisplayName,
                                          style: TextStyle(
                                            color: application.statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('MMM dd')
                                            .format(application.appliedAt),
                                        style: const TextStyle(
                                          color: textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: canWithdraw
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.cancel_outlined,
                                        color: errorColor,
                                      ),
                                      tooltip: 'Withdraw Application',
                                      onPressed: () =>
                                          _showWithdrawDialog(application),
                                    )
                                  : null,
                              onTap: () {
                                context.push('/application/${application.id}');
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'shortlisted':
        return Icons.star;
      case 'rejected':
        return Icons.close;
      case 'hired':
        return Icons.check;
      default:
        return Icons.info;
    }
  }

  void _showWithdrawDialog(application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text(
          'Are you sure you want to withdraw this application? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final applicationProvider = Provider.of<ApplicationProvider>(
                context,
                listen: false,
              );
              final error = await applicationProvider.withdrawApplication(
                application.id,
              );
              if (error != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: _ApplicationsTabState.errorColor,
                  ),
                );
              } else {
                // Refresh applications
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                applicationProvider
                    .fetchMyApplications(authProvider.currentUser!.id);
              }
            },
            child: Text(
              'Withdraw',
              style: TextStyle(color: _ApplicationsTabState.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color lightOrange = Color(0xFFFFAA64);
  static const Color textSecondary = Color(0xFF757575);
  static const Color errorColor = Color(0xFFF44336);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryOrange.withOpacity(0.2),
                  secondaryOrange.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [primaryOrange, secondaryOrange],
                ).createShader(bounds),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
              onPressed: () => context.go('/profile'),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InterviewPrepScreen(),
                ),
              );
            },
            icon: const Icon(Icons.school),
            label: const Text('Interview Preparation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Picture with Gradient Border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [primaryOrange, secondaryOrange, lightOrange],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundImage: user.profilePictureUrl != null
                          ? NetworkImage(user.profilePictureUrl!)
                          : null,
                      child: user.profilePictureUrl == null
                          ? ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [primaryOrange, secondaryOrange],
                              ).createShader(bounds),
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                Text(
                  user.email,
                  style: const TextStyle(
                    color: textSecondary,
                  ),
                ),

                if (user.bio != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryOrange.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.bio!),
                      ],
                    ),
                  ),
                ],

                if (user.skills != null && user.skills!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryOrange.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Skills',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: user.skills!
                              .map((skill) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryOrange.withOpacity(0.2),
                                          secondaryOrange.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: primaryOrange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      skill,
                                      style: TextStyle(
                                        color: primaryOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Logout Button with Gradient
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [errorColor, Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: errorColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await authProvider.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
