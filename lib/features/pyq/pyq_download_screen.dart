import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// PYQ Downloads Screen - Download NEET Previous Year Papers (2006-2024)
class PyqDownloadScreen extends ConsumerStatefulWidget {
  const PyqDownloadScreen({super.key});

  @override
  ConsumerState<PyqDownloadScreen> createState() => _PyqDownloadScreenState();
}

class _PyqDownloadScreenState extends ConsumerState<PyqDownloadScreen> {
  String _selectedSubject = 'All';
  final Set<String> _downloadingYears = {};
  final Map<String, double> _downloadProgress = {};

  final List<String> _subjects = ['All', 'Physics', 'Chemistry', 'Biology'];
  final List<int> _years = List.generate(19, (i) => 2024 - i); // 2024 down to 2006

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PYQ Downloads'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDownloads,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info Card
          _buildHeaderCard(context, theme),
          
          // Subject Filter
          _buildSubjectFilter(context, theme),
          
          // Year List
          Expanded(child: _buildYearList(context, theme)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEET Previous Year Papers',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Download and practice from 19 years of NEET question papers (2006-2024)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(context, '19 Years', Icons.calendar_today),
              const SizedBox(width: 24),
              _buildStatItem(context, '3 Subjects', Icons.science),
              const SizedBox(width: 24),
              _buildStatItem(context, 'Offline Access', Icons.download_done),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectFilter(BuildContext context, ThemeData theme) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final isSelected = _selectedSubject == subject;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(subject),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedSubject = subject);
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _years.length,
      itemBuilder: (context, index) {
        final year = _years[index];
        final isDownloading = _downloadingYears.contains('$year');
        final progress = _downloadProgress['$year'] ?? 0.0;
        final isDownloaded = _isYearDownloaded(year);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Year Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDownloaded 
                            ? Colors.green.withOpacity(0.1)
                            : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDownloaded 
                              ? Colors.green.withOpacity(0.3)
                              : theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDownloaded ? Colors.green : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEET $year',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getYearDescription(year),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDownloaded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Downloaded',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Download Progress
                if (isDownloading) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Downloading...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ] else if (!isDownloaded) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadYear(year, 'physics'),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Physics'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadYear(year, 'chemistry'),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Chemistry'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadYear(year, 'biology'),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Biology'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _downloadAllSubjects(year),
                      icon: const Icon(Icons.cloud_download, size: 18),
                      label: const Text('Download All Subjects'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDownloadedPdf(year, 'physics'),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Open Physics'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDownloadedPdf(year, 'chemistry'),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Open Chemistry'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDownloadedPdf(year, 'biology'),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Open Biology'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getYearDescription(int year) {
    if (year >= 2020) {
      return 'Latest pattern • NTA conducted';
    } else if (year >= 2013) {
      return 'NEET Phase I & II available';
    } else {
      return 'AIPMT era • Classic questions';
    }
  }

  bool _isYearDownloaded(int year) {
    // Check if all subjects for this year are downloaded
    // For now, return false - in real implementation, check local storage
    return false;
  }

  Future<void> _downloadYear(int year, String subject) async {
    final key = '$year';
    setState(() {
      _downloadingYears.add(key);
      _downloadProgress[key] = 0.0;
    });

    try {
      // Simulate download with progress updates
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _downloadProgress[key] = i / 10;
          });
        }
      }
      
      // Actual download would go here:
      // await _pyqService.downloadPyqPdf(year: year, subject: subject);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded NEET $year $subject paper'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingYears.remove(key);
          _downloadProgress.remove(key);
        });
      }
    }
  }

  Future<void> _downloadAllSubjects(int year) async {
    final key = '$year-all';
    setState(() {
      _downloadingYears.add(key);
      _downloadProgress[key] = 0.0;
    });

    try {
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          setState(() {
            _downloadProgress[key] = i / 10;
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded all subjects for NEET $year'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingYears.remove(key);
          _downloadProgress.remove(key);
        });
      }
    }
  }

  void _openDownloadedPdf(int year, String subject) {
    // Open the downloaded PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening NEET $year $subject paper...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _refreshDownloads() {
    setState(() {
      // Refresh download status from local storage
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing download status...')),
    );
  }
}