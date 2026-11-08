import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/place.dart';
import '../data/place_repository.dart';

final _gujaratiRe = RegExp(r'[઀-૿]');

String _titleCase(String s) => s
    .trim()
    .split(RegExp(r'\s+'))
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
    .join(' ');

/// Bottom sheet to pick a place by searching in English or Gujarati.
/// Returns the chosen (or newly added) place, or null if dismissed.
Future<Place?> showPlacePicker(BuildContext context, {required String title}) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => PlacePickerSheet(title: title),
  );
}

class PlacePickerSheet extends ConsumerStatefulWidget {
  const PlacePickerSheet({super.key, required this.title});
  final String title;

  @override
  ConsumerState<PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends ConsumerState<PlacePickerSheet> {
  final _query = TextEditingController();
  final _gujarati = TextEditingController();
  Timer? _searchTimer;
  Timer? _translitTimer;
  int _searchSeq = 0;
  int _translitSeq = 0;
  List<Place> _results = const [];
  List<String> _suggestions = const [];
  bool _loaded = false;
  bool _checking = false;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _translitTimer?.cancel();
    _query.dispose();
    _gujarati.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _searchTimer?.cancel();
    _translitTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () => _runSearch(q));
    setState(() {
      _suggestions = const [];
      _checking = false;
    });
    final text = q.trim();
    if (text.isNotEmpty && !_gujaratiRe.hasMatch(text)) {
      _translitTimer = Timer(const Duration(milliseconds: 500), () => _runTranslit(text));
    }
  }

  Future<void> _runSearch(String q) async {
    final seq = ++_searchSeq;
    try {
      final r = await ref.read(placeRepositoryProvider).search(q);
      if (mounted && seq == _searchSeq) {
        setState(() {
          _results = r;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted && seq == _searchSeq) setState(() => _loaded = true);
    }
  }

  Future<void> _runTranslit(String text) async {
    final seq = ++_translitSeq;
    setState(() => _checking = true);
    final s = await ref.read(placeRepositoryProvider).transliterate(text);
    if (mounted && seq == _translitSeq) {
      setState(() {
        _suggestions = s;
        _checking = false;
      });
    }
  }

  Future<void> _add(String nameEn, String nameGu) async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final place = await ref.read(placeRepositoryProvider).create(nameEn: nameEn, nameGu: nameGu);
      if (mounted) Navigator.pop(context, place);
    } catch (_) {
      if (mounted) setState(() => _adding = false);
    }
  }

  bool get _hasExactMatch {
    final q = _query.text.trim().toLowerCase();
    return _results.any((p) => p.nameEn.toLowerCase() == q || p.nameGu == _query.text.trim());
  }

  Widget _addCard(AppL10n t) {
    final q = _query.text.trim();
    final isGujarati = _gujaratiRe.hasMatch(q);
    final nameEn = isGujarati ? q : _titleCase(q);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        border: Border.all(color: AppColors.goldLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_location_alt_outlined, color: AppColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t.placeAdd(nameEn),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isGujarati)
            AppChip(label: q, selected: false, onTap: () => _add(q, q))
          else if (_checking)
            Text(t.placeChecking, style: const TextStyle(color: AppColors.muted, fontSize: 15))
          else if (_suggestions.isNotEmpty) ...[
            Text(t.placeAddHint, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _suggestions.take(3))
                  AppChip(label: s, selected: false, onTap: () => _add(nameEn, s)),
              ],
            ),
          ] else ...[
            Text(t.placeTypeGujarati, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gujarati,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.ink),
                  color: AppColors.gold,
                  icon: const Icon(Icons.check_rounded),
                  onPressed: _gujarati.text.trim().isEmpty
                      ? null
                      : () => _add(nameEn, _gujarati.text.trim()),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final q = _query.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.fieldLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              TextField(
                controller: _query,
                autofocus: true,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: t.placeSearchHint,
                  hintStyle: const TextStyle(color: AppColors.muted, fontSize: 16),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _query.clear();
                            _onChanged('');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.ivory,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.fieldLine, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.ink, width: 2),
                  ),
                ),
              ),
              if (q.isEmpty && _loaded && _results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(t.placePopular,
                      style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    for (final p in _results)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: const Icon(Icons.location_on_outlined, color: AppColors.gold),
                        title: Text(p.nameFor(lang), style: const TextStyle(fontSize: 19)),
                        subtitle: Text(p.otherNameFor(lang),
                            style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                        onTap: () => Navigator.pop(context, p),
                      ),
                    if (q.isNotEmpty && !_hasExactMatch) _addCard(t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
