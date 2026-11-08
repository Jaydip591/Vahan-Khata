const _gu = [
  'જાન્યુઆરી', 'ફેબ્રુઆરી', 'માર્ચ', 'એપ્રિલ', 'મે', 'જૂન',
  'જુલાઈ', 'ઓગસ્ટ', 'સપ્ટેમ્બર', 'ઓક્ટોબર', 'નવેમ્બર', 'ડિસેમ્બર',
];
const _en = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "નવેમ્બર 2026" / "November 2026"
String monthLabel(String languageCode, DateTime d) =>
    '${(languageCode == 'en' ? _en : _gu)[d.month - 1]} ${d.year}';
