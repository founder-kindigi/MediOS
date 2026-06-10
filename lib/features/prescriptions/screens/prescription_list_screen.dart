import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prescription_service.dart';
import '../../../core/constants/app_colors.dart';

import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../routes/app_router.dart';
import '../../../models/prescription_model.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionService>().loadPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PrescriptionService>();
    final filtered = _filter == 'all'
        ? service.prescriptions
        : service.prescriptions.where((p) => p.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/prescriptions/new').then((_) {
              service.loadPrescriptions();
            }),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _chip('All', 'all'),
                const SizedBox(width: 8),
                _chip('Active', 'active'),
                const SizedBox(width: 8),
                _chip('Completed', 'completed'),
                const SizedBox(width: 8),
                _chip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          Expanded(
            child: service.isLoading
                ? const ShimmerList()
                : filtered.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.description_rounded,
                        title: 'No prescriptions found',
                        subtitle: _filter != 'all' ? 'No prescriptions with status "$_filter"' : 'Create your first prescription',
                        actionLabel: _filter != 'all' ? null : 'New Prescription',
                        onAction: _filter != 'all' ? null : () => Navigator.pushNamed(context, '/prescriptions/new').then((_) {
                          if (mounted) {
                            context.read<PrescriptionService>().loadPrescriptions();
                          }
                        }),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(p.status).withValues(alpha: 0.2),
                                child: Icon(Icons.description, color: _statusColor(p.status)),
                              ),
                              title: Text(p.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${p.doctorName != null ? 'Dr. ${p.doctorName} · ' : ''}'
                                '${p.items?.length ?? 0} items',
                              ),
                              trailing: Chip(
                                label: Text(p.isExpired && p.status == 'active' ? 'expired' : p.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: p.isExpired && p.status == 'active' ? Colors.redAccent : _statusColor(p.status),
                                visualDensity: VisualDensity.compact,
                              ),
                              onTap: p.id == null ? null : () => _showDetail(p),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppColors.primary;
      case 'completed': return Colors.green;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  void _showDetail(PrescriptionModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PrescriptionDetailSheet(prescription: p, service: context.read<PrescriptionService>()),
    );
  }
}

class _PrescriptionDetailSheet extends StatelessWidget {
  final PrescriptionModel prescription;
  final PrescriptionService service;

  const _PrescriptionDetailSheet({required this.prescription, required this.service});

  @override
  Widget build(BuildContext context) {
    final items = prescription.items ?? [];
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: scrollController,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Prescription #${prescription.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _field('Patient', prescription.patientName),
            if (prescription.patientPhone != null) _field('Phone', prescription.patientPhone!),
            if (prescription.doctorName != null) _field('Doctor', prescription.doctorName!),
            _field('Date', '${prescription.prescriptionDate.day}/${prescription.prescriptionDate.month}/${prescription.prescriptionDate.year}'),
            _field('Status', prescription.isExpired && prescription.status == 'active' ? 'active (Expired)' : prescription.status),
            if (prescription.notes != null) _field('Notes', prescription.notes!),
            const Divider(),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.medicineName)),
                  Expanded(flex: 1, child: Text('x${item.quantity}', textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('${item.dosage ?? ''} ${item.frequency ?? ''}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                ],
              ),
            )),
            const SizedBox(height: 16),
            if (prescription.status == 'active')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: prescription.isExpired
                          ? () {
                              AppSnackbar.showError(ctx, 'Cannot create sale from an expired prescription');
                            }
                          : () {
                              Navigator.pop(ctx);
                              _createSaleFromPrescription(context);
                            },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Create Sale'),
                      style: prescription.isExpired
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (prescription.id == null) return;
                        try {
                          await service.updateStatus(prescription.id!, 'completed');
                          if (ctx.mounted) {
                            AppSnackbar.showSuccess(ctx, 'Prescription marked completed');
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            AppSnackbar.showError(ctx, 'Failed to complete prescription: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Completed'),
                    ),
                  ),
                ],
              ),
            if (prescription.status == 'active')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () async {
                    if (prescription.id == null) return;
                    try {
                      await service.updateStatus(prescription.id!, 'cancelled');
                      if (ctx.mounted) {
                        AppSnackbar.showWarning(ctx, 'Prescription cancelled');
                        Navigator.pop(ctx);
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        AppSnackbar.showError(ctx, 'Failed to cancel prescription: $e');
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel, color: AppColors.error),
                  label: const Text('Cancel Prescription', style: TextStyle(color: AppColors.error)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _createSaleFromPrescription(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRouter.newSale,
      arguments: prescription,
    );
  }
}
