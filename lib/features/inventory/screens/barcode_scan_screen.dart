import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_router.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _barcodeCtrl = TextEditingController();
  List<dynamic>? _results;
  String? _notFound;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryService>().loadMedicines();
    });
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    final inv = context.read<InventoryService>();
    final q = query.trim();
    if (q.isEmpty) {
      setState(() { _results = null; _notFound = null; });
      return;
    }
    final matched = inv.medicines.where((m) =>
      (m.barcode != null && m.barcode!.toLowerCase() == q.toLowerCase()) ||
      m.name.toLowerCase().contains(q)
    ).toList();

    setState(() {
      _results = matched;
      _notFound = matched.isEmpty ? 'No medicine found for "$q"' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Camera scan',
              onPressed: () async {
                final result = await Navigator.pushNamed(context, AppRouter.cameraScan);
                if (result != null && result is String) {
                  _barcodeCtrl.text = result;
                  _search(result);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _barcodeCtrl,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'Enter or scan barcode',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: _barcodeCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () { _barcodeCtrl.clear(); _search(''); },
                              )
                            : null,
                      ),
                      onChanged: _search,
                      onSubmitted: _search,
                    ),
                  ],
                ),
              ),
            ),
            if (_notFound != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_notFound!, style: const TextStyle(color: AppColors.error)),
              ),
            if (_results != null && _results!.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final m = _results![index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.medication, color: AppColors.primary),
                        ),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${m.barcode != null ? "${m.barcode} | " : ""}${Helpers.formatCurrency(m.sellingPrice)} | Stock: ${m.stockQuantity}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '${AppRouter.inventory}/add',
                          arguments: m,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_results != null && _results!.isEmpty && _notFound == null)
              const Expanded(
                child: Center(child: Text('Scan or type a barcode to search')),
              ),
          ],
        ),
      ),
    );
  }
}
