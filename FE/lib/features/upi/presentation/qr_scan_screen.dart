import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';
import '../data/payee.dart';

/// Camera screen that returns the first UPI QR it sees.
Future<UpiQr?> scanUpiQr(BuildContext context) =>
    Navigator.of(context).push<UpiQr>(MaterialPageRoute(builder: (_) => const QrScanScreen()));

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _done = false;
  DateTime _lastWarn = DateTime(2000);

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final qr = UpiQr.parse(b.rawValue ?? '');
      if (qr != null) {
        _done = true;
        Navigator.of(context).pop(qr);
        return;
      }
    }
    if (DateTime.now().difference(_lastWarn).inSeconds > 2) {
      _lastWarn = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppL10n.of(context).notUpiQr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(
        children: [
          InkHeader(
            title: t.scanQr,
            leading: IconButton(
              color: AppColors.gold,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(onDetect: _onDetect),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold, width: 3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Text(t.scanHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
