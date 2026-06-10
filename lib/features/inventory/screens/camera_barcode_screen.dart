import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_router.dart';

class CameraBarcodeScreen extends StatefulWidget {
  const CameraBarcodeScreen({super.key});

  @override
  State<CameraBarcodeScreen> createState() => _CameraBarcodeScreenState();
}

class _CameraBarcodeScreenState extends State<CameraBarcodeScreen> {
  MobileScannerController? _controller;
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanning = false;
    final code = barcode!.rawValue!;
    final inv = context.read<InventoryService>();
    final matched = inv.medicines.where((m) =>
      m.barcode != null && m.barcode!.toLowerCase() == code.toLowerCase()
    ).toList();
    if (matched.isNotEmpty) {
      final m = matched.first;
      Navigator.pushNamed(context, '${AppRouter.inventory}/add', arguments: m).then((_) {
        if (mounted) {
          setState(() {
            _scanning = true;
          });
        }
      });
    } else {
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller?.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller?.switchCamera(),
          ),
        ],
      ),
      body: kIsWeb
          ? _buildWebFallback()
          : _buildMobileScanner(),
    );
  }

  Widget _buildMobileScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller!,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Camera error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _controller?.dispose();
                      _controller = MobileScannerController();
                      _scanning = true;
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Point camera at barcode',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Camera scanning is not available on web.\nUse the manual barcode entry instead.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
