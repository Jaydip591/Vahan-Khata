import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'doc_pages.dart';
import 'statement_doc.dart';

/// Draws every page with Flutter (correct Gujarati) and returns them as PNG pictures.
Future<List<Uint8List>> renderPages(
  BuildContext context,
  StatementDoc doc,
  AppL10n t,
  String generatedOn,
) async {
  final pages = paginate(doc, generatedOn: generatedOn);
  final controller = ScreenshotController();
  final images = <Uint8List>[];
  for (var i = 0; i < pages.length; i++) {
    final page = buildPage(
      pages[i],
      i + 1,
      pages.length,
      t.pageOf(i + 1, pages.length),
    );
    images.add(
      await controller.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(kPageW, kPageH)),
            child: Theme(
              data: AppTheme.light(),
              child: Material(color: Colors.white, child: page),
            ),
          ),
        ),
        pixelRatio: 2.4,
        targetSize: const Size(kPageW, kPageH),
        delay: const Duration(milliseconds: 30),
      ),
    );
  }
  return images;
}

/// A PDF with one A4 page per picture.
Future<Uint8List> buildPdf(List<Uint8List> pagePictures) async {
  final pdf = pw.Document();
  for (final png in pagePictures) {
    final image = pw.MemoryImage(png);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
  }
  return pdf.save();
}

String _sheetName(String title, Set<String> used) {
  var base = title.replaceAll(RegExp(r'[\[\]\*\?/\\:]'), ' ').trim();
  if (base.isEmpty) base = 'Sheet';
  if (base.length > 28) base = base.substring(0, 28);
  var name = base;
  var n = 2;
  while (used.contains(name)) {
    name = '$base $n';
    n++;
  }
  used.add(name);
  return name;
}

CellValue _value(Object? v, CellKind kind) {
  if (v == null) return TextCellValue('');
  switch (kind) {
    case CellKind.money:
      return v is num ? DoubleCellValue(v.toDouble()) : TextCellValue('$v');
    case CellKind.number:
      return v is num ? IntCellValue(v.round()) : TextCellValue('$v');
    case CellKind.date:
    case CellKind.text:
      return TextCellValue(formatCell(v, kind));
  }
}

/// An .xlsx with a summary sheet and one sheet per table. Amounts are real numbers.
Uint8List buildXlsx(StatementDoc doc, String summarySheetName) {
  final excel = Excel.createExcel();
  final used = <String>{};
  final first = excel.getDefaultSheet() ?? 'Sheet1';
  final summaryName = _sheetName(summarySheetName, used);
  excel.rename(first, summaryName);
  final summary = excel[summaryName];
  summary.appendRow([TextCellValue(doc.title)]);
  summary.appendRow([TextCellValue(doc.subtitle)]);
  summary.appendRow([TextCellValue('')]);
  for (final s in doc.summary) {
    summary.appendRow([
      TextCellValue(s.label),
      s.value is num
          ? DoubleCellValue((s.value as num).toDouble())
          : TextCellValue('${s.value}'),
    ]);
  }
  for (final table in doc.tables) {
    final sheet = excel[_sheetName(table.title, used)];
    sheet.appendRow([for (final c in table.columns) TextCellValue(c.title)]);
    for (final row in table.rows) {
      sheet.appendRow([
        for (var i = 0; i < row.length; i++)
          _value(row[i], table.columns[i].kind),
      ]);
    }
    if (table.totals != null && table.rows.isNotEmpty) {
      sheet.appendRow([
        for (var i = 0; i < table.totals!.length; i++)
          _value(table.totals![i], table.columns[i].kind),
      ]);
    }
  }
  return Uint8List.fromList(excel.save() ?? const []);
}
