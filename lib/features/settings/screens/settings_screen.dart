import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _info;
  bool _loadingInfo = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInfo());
  }

  Future<void> _loadInfo() async {
    final info = await context.read<SettingsService>().getAppInfo();
    if (mounted) setState(() { _info = info; _loadingInfo = false; });
  }

  Future<void> _exportDb() async {
    try {
      await context.read<SettingsService>().exportDatabase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      await context.read<SettingsService>().exportMedicinesCsv();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export failed: $e')),
        );
      }
    }
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all medicines, sales, customers, suppliers, '
          'purchase orders, returns, and transactions. Users and categories will be preserved. '
          'This cannot be undone!',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SettingsService>().clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: _loadingInfo
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_pharmacy, size: 40, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_info!['appName'] as String,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('v${_info!['appVersion']} | DB v${_info!['dbVersion']}',
                                    style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Database Statistics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _statRow('Medicines', '${_info!['medicines']}', Icons.medication),
                      _statRow('Sales', '${_info!['sales']}', Icons.receipt),
                      _statRow('Suppliers', '${_info!['suppliers']}', Icons.people),
                      _statRow('Customers', '${_info!['customers']}', Icons.person),
                      _statRow('Users', '${_info!['users']}', Icons.security),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Data Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.backup, color: AppColors.primary),
                        title: const Text('Export Database'),
                        subtitle: const Text('Share a backup of the entire database'),
                        trailing: settings.isProcessing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chevron_right),
                        onTap: settings.isProcessing ? null : _exportDb,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.table_chart, color: AppColors.accent),
                        title: const Text('Export Medicines as CSV'),
                        subtitle: const Text('Share medicine catalog as spreadsheet'),
                        trailing: settings.isProcessing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chevron_right),
                        onTap: settings.isProcessing ? null : _exportCsv,
                      ),
                      if (auth.isAdmin) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: AppColors.error),
                          title: const Text('Clear All Data'),
                          subtitle: const Text('Remove all records (admin only)'),
                          onTap: _clearData,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'MediOS Pharmacy Management System',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statRow(String label, String value, IconData icon) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: AppColors.textSecondary),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
