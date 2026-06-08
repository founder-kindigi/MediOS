import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/biometric_auth_service.dart';

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
    final biometric = BiometricAuthService();

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
                if (!kIsWeb) ...[
                  const SizedBox(height: 16),
                  const Text('Security',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: FutureBuilder<bool>(
                      future: biometric.isEnabled(),
                      builder: (ctx, snap) {
                        final enabled = snap.data ?? false;
                        return SwitchListTile(
                          secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                          title: const Text('Biometric Login'),
                          subtitle: Text(enabled ? 'Enabled' : 'Disabled'),
                          value: enabled,
                          onChanged: (v) async {
                            if (v) {
                              final authed = await biometric.authenticate();
                              if (authed && mounted) {
                                await biometric.enable(auth.currentUser?.username ?? '');
                                setState(() {});
                              }
                            } else {
                              await biometric.disable();
                              if (mounted) setState(() {});
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Sync & Backup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download, color: AppColors.primary),
                        title: const Text('Import Database'),
                        subtitle: const Text('Restore from a .db file'),
                        trailing: settings.isProcessing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chevron_right),
                        onTap: settings.isProcessing ? null : () async {
                          try {
                            await settings.importDatabase();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Database imported. Restart app to apply.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Import failed: $e')),
                              );
                            }
                          }
                        },
                      ),
                      const Divider(height: 1),
                      FutureBuilder<String?>(
                        future: settings.getLastSyncTime(),
                        builder: (ctx, snap) {
                          final lastSync = snap.data;
                          return ListTile(
                            leading: const Icon(Icons.sync, color: AppColors.accent),
                            title: const Text('Last Sync'),
                            subtitle: Text(lastSync != null
                                ? DateTime.parse(lastSync).toLocal().toString().substring(0, 19)
                                : 'Never'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Billing',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      FutureBuilder<double>(
                        future: settings.getDefaultTaxRate(),
                        builder: (ctx, snap) {
                          final rate = snap.data ?? 0;
                          return ListTile(
                            leading: const Icon(Icons.percent, color: AppColors.primary),
                            title: const Text('Default Tax Rate'),
                            subtitle: Text('$rate%'),
                            trailing: const Icon(Icons.edit),
                            onTap: () async {
                              final ctrl = TextEditingController(text: rate.toString());
                              final result = await showDialog<double>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Default Tax Rate'),
                                  content: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () {
                                      final v = double.tryParse(ctrl.text);
                                      Navigator.pop(ctx, v);
                                    }, child: const Text('Save')),
                                  ],
                                ),
                              );
                              if (result != null && mounted) {
                                await settings.setDefaultTaxRate(result);
                                setState(() {});
                              }
                            },
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _CouponSection(settings: settings),
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

class _CouponSection extends StatefulWidget {
  final SettingsService settings;
  const _CouponSection({required this.settings});

  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  List<Map<String, dynamic>> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await widget.settings.getCoupons();
    if (mounted) setState(() { _coupons = c; _loading = false; });
  }

  Future<void> _add() async {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '10');
    final minCtrl = TextEditingController(text: '0');
    String type = 'percentage';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Coupon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Coupon Code'), autofocus: true),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                  DropdownMenuItem(value: 'flat', child: Text('Flat Amount')),
                ],
                onChanged: (v) => setDialogState(() => type = v ?? 'percentage'),
              ),
              const SizedBox(height: 8),
              TextField(controller: valueCtrl, decoration: InputDecoration(labelText: type == 'percentage' ? 'Discount %' : 'Discount Amount'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: minCtrl, decoration: const InputDecoration(labelText: 'Min Purchase'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result == true && codeCtrl.text.trim().isNotEmpty) {
      await widget.settings.addCoupon({
        'code': codeCtrl.text.trim().toUpperCase(),
        'type': type,
        'value': double.tryParse(valueCtrl.text) ?? 10,
        'min_purchase': double.tryParse(minCtrl.text) ?? 0,
        'is_active': true,
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox();
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.local_offer, color: AppColors.accent),
          title: Text('Coupons (${_coupons.length})'),
          subtitle: const Text('Manage discount coupons'),
          trailing: IconButton(icon: const Icon(Icons.add_circle), onPressed: _add),
        ),
        if (_coupons.isNotEmpty)
          ..._coupons.map((c) => ListTile(
            dense: true,
            title: Text(c['code'] as String),
            subtitle: Text(c['type'] == 'percentage' ? '${c['value']}% off' : '${Helpers.formatCurrency((c['value'] as num).toDouble())} off'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
              onPressed: () {
                widget.settings.removeCoupon(c['code'] as String);
                _load();
              },
            ),
          )),
      ],
    );
  }
}
