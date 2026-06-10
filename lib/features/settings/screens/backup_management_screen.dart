import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../models/backup_metadata.dart';

class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  final BackupService _backupService = GetIt.instance<BackupService>();
  List<BackupInfo> _backups = [];
  bool _isLoading = true;
  bool _isCreatingBackup = false;
  bool _isRestoringBackup = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final backups = await _backupService.listBackups();
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to load backups: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    if (_isCreatingBackup) return;

    setState(() {
      _isCreatingBackup = true;
    });

    try {
      final result = await _backupService.createBackup();
      
      if (result.isSuccess) {
        if (mounted) {
          AppSnackbar.showSuccess(
            context, 
            result.successMessage ?? 'Backup created successfully'
          );
        }
        await _loadBackups();
      } else {
        if (mounted) {
          AppSnackbar.showError(
            context, 
            result.errorMessage ?? 'Failed to create backup'
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Error creating backup: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
        });
      }
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    if (_isRestoringBackup) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to restore this backup?', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('File: ${backup.fileName}'),
            Text('Date: ${backup.metadata.createdAt.toLocal().toString().split(' ')[0]}'),
            Text('DB Version: ${backup.metadata.databaseVersion}'),
            Text('Size: ${backup.displaySize}'),
            const SizedBox(height: 16),
            const Text(
              '⚠️ This will replace your current database with the backup.',
              style: TextStyle(color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            const Text(
              'A temporary backup of your current data will be created automatically.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isRestoringBackup = true;
    });

    try {
      final result = await _backupService.restoreBackup(backup.path);
      
      if (result.isSuccess) {
        if (mounted) {
          // Show success dialog with restart instructions
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Backup Restored'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Database has been successfully restored.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ You need to restart the application for changes to take effect.',
                    style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Original backup saved at: ${result.originalBackupPath ?? 'Not available'}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        
        // Reload backups list
        await _loadBackups();
      } else {
        if (mounted) {
          AppSnackbar.showError(
            context, 
            result.errorMessage ?? 'Failed to restore backup'
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Error restoring backup: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringBackup = false;
        });
      }
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this backup?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('File: ${backup.fileName}'),
            Text('Date: ${backup.metadata.createdAt.toLocal().toString().split(' ')[0]}'),
            Text('Size: ${backup.displaySize}'),
            const SizedBox(height: 16),
            const Text(
              '⚠️ This action cannot be undone.',
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final deleted = await _backupService.deleteBackup(backup.path);
      
      if (deleted) {
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Backup deleted successfully');
        }
        await _loadBackups();
      } else {
        if (mounted) {
          AppSnackbar.showError(context, 'Failed to delete backup');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Error deleting backup: $e');
      }
    }
  }

  Future<void> _validateBackup(BackupInfo backup) async {
    try {
      final validation = await _backupService.validateBackupFile(backup.path);
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Validation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: ${backup.fileName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      validation.isValid ? Icons.check_circle : Icons.error,
                      color: validation.isValid ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      validation.isValid ? 'Valid Backup' : 'Invalid Backup',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: validation.isValid ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (validation.isValid && validation.metadata != null) ...[
                  _metadataRow('App Name', validation.metadata!.app),
                  _metadataRow('Backup Version', 'v${validation.metadata!.backupVersion}'),
                  _metadataRow('DB Version', 'v${validation.metadata!.databaseVersion}'),
                  _metadataRow('Created', validation.metadata!.createdAt.toLocal().toString().split('.')[0]),
                  _metadataRow('Checksum', validation.metadata!.checksum.split(':')[0]),
                  const SizedBox(height: 8),
                  const Text('Record Counts:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...validation.metadata!.recordCounts.entries
                      .where((entry) => entry.value > 0)
                      .take(5)
                      .map((entry) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                        child: Text('${entry.key}: ${entry.value}'),
                      )),
                ],
                if (!validation.isValid) ...[
                  const SizedBox(height: 8),
                  Text('Error: ${validation.error}', style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Error validating backup: $e');
      }
    }
  }

  Widget _metadataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBackups,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Backup Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_backups.length} backup${_backups.length == 1 ? '' : 's'} available',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _isCreatingBackup ? null : _createBackup,
                          icon: _isCreatingBackup
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.backup, size: 20),
                          label: Text(_isCreatingBackup ? 'Creating...' : 'Create Backup'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Backups list
                Expanded(
                  child: _backups.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.backup, size: 64, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                'No Backups Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create your first backup to protect your data',
                                style: TextStyle(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _backups.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final backup = _backups[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                leading: const Icon(Icons.backup, color: AppColors.primary),
                                title: Text(
                                  path.basenameWithoutExtension(backup.fileName),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Created: ${backup.metadata.createdAt.toLocal().toString().split(' ')[0]} ${backup.metadata.createdAt.toLocal().toString().split(' ')[1].substring(0, 5)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'DB Version: ${backup.metadata.databaseVersion} | Size: ${backup.displaySize}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (backup.metadata.notes?.isNotEmpty == true)
                                      Text(
                                        'Notes: ${backup.metadata.notes!}',
                                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'restore':
                                        _restoreBackup(backup);
                                        break;
                                      case 'validate':
                                        _validateBackup(backup);
                                        break;
                                      case 'delete':
                                        _deleteBackup(backup);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<String>(
                                      value: 'restore',
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore, size: 20, color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Text('Restore'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'validate',
                                      child: Row(
                                        children: [
                                          Icon(Icons.verified, size: 20, color: AppColors.success),
                                          SizedBox(width: 8),
                                          Text('Validate'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _validateBackup(backup),
                              ),
                            );
                          },
                        ),
                ),

                // Instructions
                if (_backups.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surfaceVariant,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backup Instructions:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Backups are automatically encrypted',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Files are stored in app documents directory',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Restoring will replace current database',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Always validate backups before restoring',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: _isCreatingBackup
          ? null
          : FloatingActionButton.extended(
              onPressed: _createBackup,
              icon: const Icon(Icons.backup),
              label: const Text('Create Backup'),
              backgroundColor: AppColors.primary,
            ),
    );
  }
}