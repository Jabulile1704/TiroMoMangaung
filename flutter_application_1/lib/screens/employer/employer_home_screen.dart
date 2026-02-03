import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/application_provider.dart';
import '../../widgets/email_verification_banner.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  int _selectedIndex = 0;
  int _applicationTabIndex = 0; // Track which subtab in Applications to show

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
    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      jobProvider.fetchEmployerJobs(authProvider.currentUser!.id);
      applicationProvider
          .fetchReceivedApplications(authProvider.currentUser!.id);
    }
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
                _DashboardTab(
                  onNavigate: (index, {int? subtabIndex}) {
                    setState(() {
                      _selectedIndex = index;
                      if (subtabIndex != null) {
                        _applicationTabIndex = subtabIndex;
                      }
                    });
                  },
                ),
                const _MyJobsTab(),
                _ApplicationsTab(initialTabIndex: _applicationTabIndex),
                const _ProfileTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/post-job'),
              icon: const Icon(Icons.add),
              label: const Text('Post Job'),
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60,
        backgroundColor: backgroundColor,
        color: primaryOrange,
        buttonBackgroundColor: Colors.deepOrange,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.dashboard, size: 30, color: Colors.white),
          Icon(Icons.work, size: 30, color: Colors.white),
          Icon(Icons.people, size: 30, color: Colors.white),
          Icon(Icons.business, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Function(int, {int? subtabIndex}) onNavigate;

  const _DashboardTab({required this.onNavigate});

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color lightOrange = Color(0xFFFFAA64);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF29B6F6);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: primaryOrange,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryOrange,
                    secondaryOrange,
                    lightOrange,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final companyName =
                              authProvider.currentUser?.companyName ??
                                  'Company';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Employer Dashboard',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                Consumer2<JobProvider, ApplicationProvider>(
                  builder: (context, jobProvider, applicationProvider, child) {
                    final totalJobs = jobProvider.myJobs.length;
                    final activeJobs =
                        jobProvider.myJobs.where((j) => j.isActive).length;
                    final stats = applicationProvider.applicationStats;
                    final totalApplications =
                        stats.values.fold<int>(0, (sum, count) => sum + count);

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.work,
                                title: 'Active Jobs',
                                value: activeJobs.toString(),
                                subtitle: '$totalJobs total',
                                gradientColors: const [
                                  primaryOrange,
                                  secondaryOrange
                                ],
                                onTap: () =>
                                    onNavigate(1), // Navigate to My Jobs tab
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.people,
                                title: 'Applications',
                                value: totalApplications.toString(),
                                subtitle: '${stats['pending'] ?? 0} pending',
                                gradientColors: const [
                                  secondaryOrange,
                                  lightOrange
                                ],
                                onTap: () => onNavigate(2,
                                    subtabIndex:
                                        0), // Navigate to Applications tab, Pending subtab
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star,
                                title: 'Shortlisted',
                                value: (stats['shortlisted'] ?? 0).toString(),
                                subtitle: 'candidates',
                                gradientColors: const [
                                  infoColor,
                                  Color(0xFF4FC3F7)
                                ],
                                onTap: () => onNavigate(2,
                                    subtabIndex:
                                        1), // Navigate to Applications tab, Shortlisted subtab
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle,
                                title: 'Hired',
                                value: (stats['hired'] ?? 0).toString(),
                                subtitle: 'this month',
                                gradientColors: const [
                                  successColor,
                                  Color(0xFF66BB6A)
                                ],
                                onTap: () => onNavigate(2,
                                    subtabIndex:
                                        3), // Navigate to Applications tab, Hired subtab (index 3)
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Recent Applications
                Text(
                  'Recent Applications',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                Consumer<ApplicationProvider>(
                  builder: (context, applicationProvider, child) {
                    if (applicationProvider.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: primaryOrange,
                        ),
                      );
                    }

                    final recentApplications = applicationProvider
                        .receivedApplications
                        .take(5)
                        .toList();

                    if (recentApplications.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No applications yet'),
                        ),
                      );
                    }

                    return Column(
                      children: recentApplications.map((application) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () => context.push(
                              '/employer/application/${application.id}',
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  application.statusColor.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: application.statusColor,
                              ),
                            ),
                            title: Text(application.seekerName ?? 'Applicant'),
                            subtitle: Text(application.jobTitle ?? 'Job'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    application.statusColor.withOpacity(0.2),
                                    application.statusColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      application.statusColor.withOpacity(0.3),
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
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors[0].withOpacity(0.1),
              gradientColors[1].withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gradientColors[0].withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gradientColors[0], size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: gradientColors[0],
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyJobsTab extends StatelessWidget {
  const _MyJobsTab();

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Job Postings'),
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

          if (jobProvider.myJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No job postings yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/post-job'),
                    icon: const Icon(Icons.add),
                    label: const Text('Post Your First Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobProvider.myJobs.length,
            itemBuilder: (context, index) {
              final job = jobProvider.myJobs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: job.isActive
                            ? [
                                successColor.withOpacity(0.2),
                                successColor.withOpacity(0.1)
                              ]
                            : [
                                Colors.grey.withOpacity(0.2),
                                Colors.grey.withOpacity(0.1)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: job.isActive
                            ? successColor.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.work,
                      color: job.isActive ? successColor : Colors.grey,
                    ),
                  ),
                  title: Text(
                    job.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${job.location} • ${job.formattedJobType}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${job.viewCount} views',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${job.applicationCount} applications',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              job.isActive ? Icons.pause : Icons.play_arrow,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(job.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: errorColor),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: errorColor)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'toggle') {
                        await jobProvider.updateJob(
                          jobId: job.id,
                          isActive: !job.isActive,
                        );
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        jobProvider
                            .fetchEmployerJobs(authProvider.currentUser!.id);
                      }
                    },
                  ),
                  onTap: () => context.push('/employer/job/${job.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ApplicationsTab extends StatelessWidget {
  final int initialTabIndex;

  const _ApplicationsTab({this.initialTabIndex = 0});

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Applications'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Shortlisted'),
              Tab(text: 'Rejected'),
              Tab(text: 'Hired'),
            ],
            labelColor: primaryOrange,
            unselectedLabelColor: textSecondary,
            indicatorColor: primaryOrange,
          ),
        ),
        body: Consumer<ApplicationProvider>(
          builder: (context, applicationProvider, child) {
            if (applicationProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: primaryOrange),
              );
            }

            return TabBarView(
              children: [
                // Pending tab with withdrawn applications section
                _PendingApplicationsTab(
                  applicationProvider: applicationProvider,
                ),
                _ApplicationsList(
                  applications: applicationProvider
                      .getApplicationsByStatus('shortlisted'),
                  emptyMessage: 'No shortlisted candidates',
                ),
                _ApplicationsList(
                  applications:
                      applicationProvider.getApplicationsByStatus('rejected'),
                  emptyMessage: 'No rejected applications',
                ),
                _ApplicationsList(
                  applications:
                      applicationProvider.getApplicationsByStatus('hired'),
                  emptyMessage: 'No hired candidates yet',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Custom widget for Pending tab that shows both active and withdrawn applications
class _PendingApplicationsTab extends StatelessWidget {
  final ApplicationProvider applicationProvider;

  static const Color textSecondary = Color(0xFF757575);
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color errorColor = Color(0xFFF44336);

  const _PendingApplicationsTab({
    required this.applicationProvider,
  });

  @override
  Widget build(BuildContext context) {
    final activePending = applicationProvider
        .getApplicationsByStatus('pending')
        .where((app) => !app.isWithdrawn)
        .toList();
    final withdrawn = applicationProvider.getWithdrawnApplications();

    if (activePending.isEmpty && withdrawn.isEmpty) {
      return const Center(
        child: Text(
          'No pending applications',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active pending applications
        if (activePending.isNotEmpty) ...[
          Text(
            'Active Applications (${activePending.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...activePending.map((application) => Card(
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
                          primaryOrange.withOpacity(0.2),
                          primaryOrange.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Text(
                        (application.seekerName ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(
                          color: primaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    application.seekerName ?? 'Applicant',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.jobTitle ?? 'Job'),
                      const SizedBox(height: 4),
                      Text(
                        'Applied ${DateFormat('MMM dd').format(application.appliedAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/employer/application/${application.id}');
                  },
                ),
              )),
        ],

        // Withdrawn applications section
        if (withdrawn.isNotEmpty) ...[
          if (activePending.isNotEmpty) const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.info_outline, color: errorColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Withdrawn Applications (${withdrawn.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: errorColor.withOpacity(0.3)),
            ),
            child: const Text(
              'These applications have been withdrawn by job seekers. You can delete them from your list.',
              style: TextStyle(
                fontSize: 12,
                color: errorColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...withdrawn.map((application) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: errorColor.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          errorColor.withOpacity(0.2),
                          errorColor.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Text(
                        (application.seekerName ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(
                          color: errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          application.seekerName ?? 'Applicant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87.withOpacity(0.6),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: errorColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: errorColor.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'WITHDRAWN',
                          style: TextStyle(
                            color: errorColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.jobTitle ?? 'Job',
                        style: TextStyle(color: textSecondary.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Withdrawn ${DateFormat('MMM dd').format(application.updatedAt)}',
                        style: const TextStyle(fontSize: 12, color: errorColor),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: errorColor),
                    tooltip: 'Delete application',
                    onPressed: () => _showDeleteDialog(context, application),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Withdrawn Application'),
        content: Text(
          'Are you sure you want to permanently delete ${application.seekerName ?? "this applicant"}\'s withdrawn application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final error =
                  await applicationProvider.deleteApplication(application.id);
              if (context.mounted) {
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: errorColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  final List applications;
  final String emptyMessage;

  static const Color textSecondary = Color(0xFF757575);
  static const Color primaryOrange = Color(0xFFFF6B35);

  const _ApplicationsList({
    required this.applications,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
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
                    primaryOrange.withOpacity(0.2),
                    primaryOrange.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Text(
                  (application.seekerName ?? 'A')[0].toUpperCase(),
                  style: TextStyle(
                      color: primaryOrange, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: Text(
              application.seekerName ?? 'Applicant',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.jobTitle ?? 'Job'),
                const SizedBox(height: 4),
                Text(
                  'Applied ${DateFormat('MMM dd').format(application.appliedAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/employer/application/${application.id}');
            },
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color lightOrange = Color(0xFFFFAA64);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color errorColor = Color(0xFFF44336);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryOrange, secondaryOrange, lightOrange],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    backgroundImage: user.logoUrl != null
                        ? NetworkImage(user.logoUrl!)
                        : null,
                    child: user.logoUrl == null
                        ? Text(
                            user.companyName?.isNotEmpty == true
                                ? user.companyName![0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.companyName ?? 'Company',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (user.verificationStatus != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: user.verificationStatus == 'verified'
                            ? [
                                successColor.withOpacity(0.2),
                                successColor.withOpacity(0.1)
                              ]
                            : [
                                warningColor.withOpacity(0.2),
                                warningColor.withOpacity(0.1)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: user.verificationStatus == 'verified'
                            ? successColor.withOpacity(0.3)
                            : warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.verificationStatus == 'verified'
                              ? Icons.verified
                              : Icons.pending,
                          size: 16,
                          color: user.verificationStatus == 'verified'
                              ? successColor
                              : warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.verificationStatus == 'verified'
                              ? 'Verified'
                              : 'Pending Verification',
                          style: TextStyle(
                            color: user.verificationStatus == 'verified'
                                ? successColor
                                : warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Verification Status Details Card
                if (user.verificationStatus != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: user.verificationStatus == 'verified'
                            ? [
                                successColor.withOpacity(0.1),
                                successColor.withOpacity(0.05)
                              ]
                            : user.verificationStatus == 'rejected'
                                ? [
                                    errorColor.withOpacity(0.1),
                                    errorColor.withOpacity(0.05)
                                  ]
                                : [
                                    warningColor.withOpacity(0.1),
                                    warningColor.withOpacity(0.05)
                                  ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: user.verificationStatus == 'verified'
                            ? successColor.withOpacity(0.3)
                            : user.verificationStatus == 'rejected'
                                ? errorColor.withOpacity(0.3)
                                : warningColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              user.verificationStatus == 'verified'
                                  ? Icons.check_circle
                                  : user.verificationStatus == 'rejected'
                                      ? Icons.cancel
                                      : Icons.hourglass_empty,
                              color: user.verificationStatus == 'verified'
                                  ? successColor
                                  : user.verificationStatus == 'rejected'
                                      ? errorColor
                                      : warningColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.verificationStatus == 'verified'
                                        ? 'Company Verified ✓'
                                        : user.verificationStatus == 'rejected'
                                            ? 'Verification Rejected'
                                            : 'Verification Pending',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          user.verificationStatus == 'verified'
                                              ? successColor
                                              : user.verificationStatus ==
                                                      'rejected'
                                                  ? errorColor
                                                  : warningColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.verificationStatus == 'verified'
                                        ? 'Your company profile has been verified by the administrator.'
                                        : user.verificationStatus == 'rejected'
                                            ? 'Your verification request was rejected. Please contact support.'
                                            : 'Your company profile is under review by our team.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (user.verificationStatus == 'pending') ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 20, color: warningColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'What happens next?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _VerificationStep(
                            number: '1',
                            text: 'Our team reviews your company information',
                          ),
                          _VerificationStep(
                            number: '2',
                            text: 'Verification usually takes 24-48 hours',
                          ),
                          _VerificationStep(
                            number: '3',
                            text:
                                'You\'ll be notified once your profile is verified',
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: warningColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 18, color: warningColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Limited features available until verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (user.verificationStatus == 'verified') ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.stars, size: 20, color: successColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Benefits of Verification',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _BenefitItem(
                              icon: Icons.check,
                              text: 'Increased trust from job seekers'),
                          _BenefitItem(
                              icon: Icons.check,
                              text: 'Priority in search results'),
                          _BenefitItem(
                              icon: Icons.check,
                              text: 'Verified badge on all job postings'),
                        ],
                        if (user.verificationStatus == 'rejected') ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.help_outline,
                                        size: 20, color: errorColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Need Help?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please contact our support team at support@tiromangaung.co.za for more information about your verification status.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Company Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: user.email,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: user.phoneNumber,
                      ),
                      if (user.industryType != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.category,
                          label: 'Industry',
                          value: user.industryType!,
                        ),
                      ],
                      if (user.companySize != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.people,
                          label: 'Company Size',
                          value: user.companySize!,
                        ),
                      ],
                      if (user.website != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.language,
                          label: 'Website',
                          value: user.website!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (user.companyDescription != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.companyDescription!),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [errorColor, Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await authProvider.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign Out'),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color textSecondary = Color(0xFF757575);

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryOrange.withOpacity(0.2),
                primaryOrange.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: primaryOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
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
    );
  }
}

// Helper widget for verification steps
class _VerificationStep extends StatelessWidget {
  final String number;
  final String text;

  const _VerificationStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for benefit items
class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
