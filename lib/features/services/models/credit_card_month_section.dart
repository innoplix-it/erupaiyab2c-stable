import 'credit_card_transaction.dart';

class CreditCardMonthSection {
  const CreditCardMonthSection({
    required this.title,
    required this.month,
    required this.year,
    required this.count,
    required this.items,
  });

  final String title;
  final int month;
  final int year;
  final int count;
  final List<CreditCardTransaction> items;
}

DateTime? parseCreditCardTxnDate(String raw) {
  final key = raw.trim();
  if (key.isEmpty) return null;

  // Direct ISO-8601 or standard datetime 'YYYY-MM-DD HH:mm:ss'
  final direct = DateTime.tryParse(
    key.contains(' ') && !key.contains(',') ? key.replaceFirst(' ', 'T') : key,
  );
  if (direct != null) return direct;

  // Match: '24 Sep 2026, 7:45am' or '24 Sep 2026, 07:45 am'
  final match = RegExp(
    r'(\d{1,2})\s+([A-Za-z]{3,})(?:\s+(\d{4}))?,\s*(\d{1,2}):(\d{2})\s*(am|pm|AM|PM)?',
  ).firstMatch(key);
  if (match != null) {
    final day = int.parse(match.group(1)!);
    final monthRaw = match.group(2)!.toLowerCase();
    final year = match.group(3) != null
        ? int.parse(match.group(3)!)
        : DateTime.now().year;
    var hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final ampm = match.group(6)?.toLowerCase();

    if (ampm == 'pm' && hour < 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;

    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec'
    ];
    final monthIndex = months.indexWhere((m) => monthRaw.startsWith(m));
    if (monthIndex != -1) {
      return DateTime(year, monthIndex + 1, day, hour, minute);
    }
  }

  // Match: 'YYYY-MM-DD'
  final dateOnlyMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(key);
  if (dateOnlyMatch != null) {
    return DateTime(
      int.parse(dateOnlyMatch.group(1)!),
      int.parse(dateOnlyMatch.group(2)!),
      int.parse(dateOnlyMatch.group(3)!),
    );
  }

  // Match: 'DD-MM-YYYY' or 'DD/MM/YYYY'
  final dmyMatch =
      RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(key);
  if (dmyMatch != null) {
    return DateTime(
      int.parse(dmyMatch.group(3)!),
      int.parse(dmyMatch.group(2)!),
      int.parse(dmyMatch.group(1)!),
    );
  }

  return null;
}

List<CreditCardMonthSection> groupCreditCardTransactionsByMonth(
  List<CreditCardTransaction> items,
) {
  if (items.isEmpty) return const [];

  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final Map<
      String,
      ({
        int year,
        int month,
        String title,
        List<CreditCardTransaction> items
      })> groups = {};

  for (final item in items) {
    final parsed = parseCreditCardTxnDate(item.transactionTime);
    if (parsed != null) {
      final key = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}';
      final title = '${monthNames[parsed.month - 1]} ${parsed.year}';
      if (!groups.containsKey(key)) {
        groups[key] = (
          year: parsed.year,
          month: parsed.month,
          title: title,
          items: <CreditCardTransaction>[],
        );
      }
      groups[key]!.items.add(item);
    } else {
      const key = 'undated';
      const title = 'Transactions';
      if (!groups.containsKey(key)) {
        groups[key] = (
          year: 0,
          month: 0,
          title: title,
          items: <CreditCardTransaction>[],
        );
      }
      groups[key]!.items.add(item);
    }
  }

  final sortedEntries = groups.entries.toList()
    ..sort((a, b) {
      if (a.key == 'undated') return 1;
      if (b.key == 'undated') return -1;
      final valA = a.value.year * 100 + a.value.month;
      final valB = b.value.year * 100 + b.value.month;
      return valB.compareTo(valA); // Newest month first
    });

  return sortedEntries.map((e) {
    return CreditCardMonthSection(
      title: e.value.title,
      month: e.value.month,
      year: e.value.year,
      count: e.value.items.length,
      items: e.value.items,
    );
  }).toList();
}
