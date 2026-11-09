import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'statement_doc.dart';

/// A4 in logical pixels. The pages are drawn by Flutter itself (so Gujarati is shaped
/// correctly) and then turned into pictures for the PDF.
const kPageW = 595.0;
const kPageH = 842.0;
const _pad = 28.0;
const _footerH = 26.0;
const _contentH = kPageH - 2 * _pad - _footerH;

const _titleH = 34.0;
const _headH = 28.0;
const _rowH = 30.0;
const _gapH = 12.0;

class _Block {
  const _Block(
    this.height,
    this.widget, {
    this.keepWithNext = false,
    this.table,
    this.isRow = false,
  });
  final double height;
  final Widget widget;
  final bool keepWithNext;
  final DocTable?
  table; // for rows: the table whose header can be repeated on a new page
  final bool isRow;
}

TextStyle _text(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = AppColors.ink,
}) => TextStyle(
  fontFamily: AppTheme.fontFamily,
  fontSize: size,
  fontWeight: w,
  color: c,
  height: 1.2,
);

Widget _cells(
  DocTable table,
  List<Object?> values, {
  bool bold = false,
  Color? bg,
  double h = _rowH,
}) {
  return Container(
    height: h,
    color: bg,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: bg == null
        ? const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          )
        : null,
    child: Row(
      children: [
        for (var i = 0; i < table.columns.length; i++)
          Expanded(
            flex: (table.columns[i].flex * 100).round(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                formatCell(values[i], table.columns[i].kind),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: table.columns[i].right
                    ? TextAlign.right
                    : TextAlign.left,
                style: _text(12.5, w: bold ? FontWeight.w700 : FontWeight.w400),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _headerRow(DocTable table) => Container(
  height: _headH,
  color: AppColors.ink,
  padding: const EdgeInsets.symmetric(horizontal: 6),
  child: Row(
    children: [
      for (final c in table.columns)
        Expanded(
          flex: (c.flex * 100).round(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              c.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: c.right ? TextAlign.right : TextAlign.left,
              style: _text(11.5, w: FontWeight.w600, c: Colors.white),
            ),
          ),
        ),
    ],
  ),
);

Color _tone(Tone t) => switch (t) {
  Tone.neutral => AppColors.ink,
  Tone.income => AppColors.income,
  Tone.expense => AppColors.expense,
};

List<_Block> _blocks(StatementDoc doc, String generatedOn) {
  final out = <_Block>[];
  out.add(
    _Block(
      78,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'વાહન ખાતા  ·  Vahan Khata',
            style: _text(11, w: FontWeight.w600, c: AppColors.gold),
          ),
          const SizedBox(height: 4),
          Text(doc.title, style: _text(22, w: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            doc.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(14, c: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(generatedOn, style: _text(10.5, c: AppColors.muted)),
        ],
      ),
      keepWithNext: true,
    ),
  );
  if (doc.summary.isNotEmpty) {
    out.add(
      _Block(
        70,
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              for (final s in doc.summary)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(10.5, c: AppColors.muted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.value is num
                              ? formatCell(s.value, CellKind.money)
                              : '${s.value}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            16,
                            w: FontWeight.w700,
                            c: _tone(s.tone),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  for (final table in doc.tables) {
    if (table.rows.isEmpty) continue;
    out.add(
      _Block(
        _gapH + _titleH,
        Padding(
          padding: const EdgeInsets.only(top: _gapH),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(table.title, style: _text(15, w: FontWeight.w700)),
          ),
        ),
        keepWithNext: true,
      ),
    );
    out.add(_Block(_headH, _headerRow(table), keepWithNext: true));
    for (var i = 0; i < table.rows.length; i++) {
      out.add(
        _Block(_rowH, _cells(table, table.rows[i]), table: table, isRow: true),
      );
    }
    if (table.totals != null) {
      out.add(
        _Block(
          _rowH,
          _cells(table, table.totals!, bold: true, bg: AppColors.goldSoft),
          table: table,
        ),
      );
    }
  }
  return out;
}

/// Splits the document into page-sized lists of widgets. A title never ends a page alone,
/// and a table that continues on a new page gets its header row again.
List<List<Widget>> paginate(StatementDoc doc, {String generatedOn = ''}) {
  final blocks = _blocks(doc, generatedOn);
  final pages = <List<Widget>>[[]];
  var used = 0.0;
  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    // height of this block plus the blocks glued to it (title + header + first row)
    var need = b.height;
    var j = i;
    while (blocks[j].keepWithNext && j + 1 < blocks.length) {
      j++;
      need += blocks[j].height;
    }
    final pageIsEmpty = pages.last.isEmpty;
    if (!pageIsEmpty && used + need > _contentH) {
      pages.add([]);
      used = 0;
      if (b.table != null) {
        // continuing a table: repeat its header
        pages.last.add(_headerRow(b.table!));
        used += _headH;
      }
    }
    pages.last.add(b.widget);
    used += b.height;
  }
  return pages;
}

/// One page, ready to be drawn.
Widget buildPage(List<Widget> blocks, int n, int total, String footerText) {
  return SizedBox(
    width: kPageW,
    height: kPageH,
    child: ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(_pad),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: blocks,
              ),
            ),
            SizedBox(
              height: _footerH,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(footerText, style: _text(10, c: AppColors.muted)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
