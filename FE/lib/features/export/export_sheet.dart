import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/keypad.dart';
import '../../l10n/app_localizations.dart';
import 'export_service.dart';
import 'exporters.dart';
import 'statement_doc.dart';

/// Bottom sheet with two choices, PDF or Excel. [build] makes the document when one is chosen.
Future<void> showExportSheet(
  BuildContext context,
  Future<StatementDoc> Function() build,
) {
  return showAppSheet<void>(context, (_) => _ExportSheet(build: build));
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({required this.build});
  final Future<StatementDoc> Function() build;

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _run(bool pdf) async {
    final t = AppL10n.of(context);
    final nav = Navigator.of(context);
    final service = ref.read(exportServiceProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final doc = await widget.build();
      if (pdf) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        final pictures = await renderPages(
          context,
          doc,
          t,
          t.generatedOn(formatDay(DateTime.now())),
        );
        final bytes = await buildPdf(pictures);
        await service.shareBytes(
          bytes: bytes,
          fileName: '${doc.fileName}.pdf',
          mimeType: 'application/pdf',
          text: '${doc.title} · ${doc.subtitle}',
        );
      } else {
        final bytes = buildXlsx(doc, t.sheetSummary);
        await service.shareBytes(
          bytes: bytes,
          fileName: '${doc.fileName}.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          text: '${doc.title} · ${doc.subtitle}',
        );
      }
      if (mounted) nav.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = t.exportFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 10),
          Text(
            t.exportTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          if (_busy)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.gold),
                  const SizedBox(height: 14),
                  Text(
                    t.exporting,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _Choice(
              icon: Icons.picture_as_pdf_rounded,
              title: t.exportPdf,
              help: t.exportPdfHelp,
              onTap: () => _run(true),
            ),
            const SizedBox(height: 10),
            _Choice(
              icon: Icons.table_chart_rounded,
              title: t.exportExcel,
              help: t.exportExcelHelp,
              onTap: () => _run(false),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.help,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String help;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.line),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    help,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.share_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
