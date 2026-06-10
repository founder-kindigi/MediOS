import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/return_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/utils/helpers.dart';

class ReturnsHistoryScreen extends StatefulWidget {
  const ReturnsHistoryScreen({super.key});

  @override
  State<ReturnsHistoryScreen> createState() => _ReturnsHistoryScreenState();
}

class _ReturnsHistoryScreenState extends State<ReturnsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReturnService>().loadReturns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final retService = context.watch<ReturnService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Returns History')),
      body: retService.isLoading
          ? const ShimmerList()
          : retService.returns.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.replay_rounded,
                  title: 'No returns processed yet',
                  subtitle: 'Process a return from the sales screen',
                )
              : RefreshIndicator(
                  onRefresh: () => retService.loadReturns(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: retService.returns.length,
                    itemBuilder: (context, index) {
                      final ret = retService.returns[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.error.withValues(alpha: 0.1),
                            child: const Icon(Icons.replay, color: AppColors.error),
                          ),
                          title: Text(ret.returnNumber,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${ret.billNumber ?? ''} | ${Helpers.formatDate(ret.returnDate)}\n${ret.reason.replaceAll('_', ' ').toUpperCase()}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(Helpers.formatCurrency(ret.totalRefund),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                            ],
                          ),
                          onTap: ret.id == null ? null : () => _showReturnDetail(ret.id!),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showReturnDetail(int returnId) async {
    final retService = context.read<ReturnService>();
    final ret = await retService.getReturnWithItems(returnId);
    if (!mounted || ret == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ret.returnNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Original Bill: ${ret.billNumber ?? 'N/A'}'),
            Text('Date: ${Helpers.formatDate(ret.returnDate)}'),
            Text('Reason: ${ret.reason.replaceAll('_', ' ').toUpperCase()}'),
            const SizedBox(height: 8),
            const Text('Items Returned:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...ret.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('${item.medicineName ?? 'Item'} x${item.quantity} = ${Helpers.formatCurrency(item.totalRefund)}'),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Refund:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(Helpers.formatCurrency(ret.totalRefund), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}
