class MyNumberInfo {
  const MyNumberInfo({
    required this.number,
    this.operatorName,
    this.operatorIcon,
    this.lastOn,
    this.dueLabel,
    this.dueDate,
    this.dueStatus,
    this.dueAmount,
  });

  final String number;
  final String? operatorName;
  final String? operatorIcon;
  final String? lastOn;
  final String? dueLabel;
  final String? dueDate;
  final String? dueStatus;
  final String? dueAmount;

  factory MyNumberInfo.fromJson(Map<String, dynamic> json) {
    final nested = _asMap(json['customer']) ??
        _asMap(json['info']) ??
        _asMap(json['my_number']) ??
        _asMap(json['recharge']);
    final source = nested == null ? json : {...json, ...nested};

    final number = (source['customer_mobile'] ??
            source['service_no'] ??
            source['serviceNo'] ??
            source['number'] ??
            source['mobile'] ??
            '')
        .toString();

    final duesSource = _asMap(source['dues']) ??
        _asMap(source['due']) ??
        _asMap(source['due_info']) ??
        source;

    final dueDateRaw = duesSource['due_date'] ??
        duesSource['dueDate'] ??
        duesSource['next_due'] ??
        duesSource['nextDue'] ??
        source['due_date'] ??
        source['dueDate'] ??
        source['next_due'] ??
        source['nextDue'] ??
        source['expires_at'] ??
        source['expiry_date'] ??
        source['expire_date'] ??
        source['valid_till'] ??
        source['validity_date'];
    final dueStatusRaw = duesSource['status'] ??
        duesSource['due_status'] ??
        duesSource['dueStatus'] ??
        source['due_status'] ??
        source['dueStatus'];
    final dueAmountRaw = duesSource['due_amount'] ??
        duesSource['amount'] ??
        duesSource['outstanding_amount'] ??
        source['due_amount'] ??
        source['dueAmount'] ??
        source['outstanding_amount'];
    final daysLeft = _parseDaysLeft(
      duesSource['days_left'] ??
          duesSource['daysLeft'] ??
          source['days_left'] ??
          source['daysLeft'],
    );

    final dueDate = _formatDisplayDate(dueDateRaw);
    final dueStatus = _clean(dueStatusRaw);
    final dueAmount = _formatAmount(dueAmountRaw);
    final dueLabel = _clean(
          source['due_label'] ?? source['dueLabel'] ?? source['expiry_label'],
        ) ??
        _composeDueLabel(
          daysLeft: daysLeft,
          dateRaw: dueDateRaw,
          displayDate: dueDate,
          status: dueStatus,
          amount: dueAmount,
        );

    return MyNumberInfo(
      number: number,
      operatorName: (source['biller_name'] ??
              source['operator'] ??
              source['operator_name'] ??
              source['operatorName'])
          ?.toString(),
      operatorIcon:
          (source['icon'] ?? source['operator_icon'] ?? source['operatorIcon'])
              ?.toString(),
      lastOn: _formatLastOn(
        source['transaction_time'] ??
            source['last_on'] ??
            source['lastOn'] ??
            source['last_recharge_date'] ??
            source['last_recharge_on'],
      ),
      dueLabel: dueLabel,
      dueDate: dueDate,
      dueStatus: dueStatus,
      dueAmount: dueAmount,
    );
  }

  String? get dueBadgeText {
    final raw = dueLabel?.trim();
    if (raw == null || raw.isEmpty) return null;
    final first = raw.split(' • ').first.trim();
    return first.isEmpty ? raw : first;
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  static String? _clean(Object? value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
    return raw;
  }

  static String? _formatAmount(Object? value) {
    final raw = _clean(value);
    if (raw == null) return null;
    final parsed = num.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return raw;
    if (parsed == parsed.roundToDouble()) return parsed.round().toString();
    return parsed.toString();
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String? _formatDisplayDate(Object? value) {
    final raw = _clean(value);
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final local = parsed.toLocal();
      return '${local.day} ${_months[local.month - 1]} ${local.year}';
    }
    final commaIndex = raw.indexOf(',');
    if (commaIndex > 0) return raw.substring(0, commaIndex).trim();
    return raw;
  }

  static String? _formatLastOn(Object? value) => _formatDisplayDate(value);

  static int? _parseDaysLeft(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString().trim());
  }

  static String? _composeDueLabel({
    required int? daysLeft,
    required Object? dateRaw,
    required String? displayDate,
    required String? status,
    required String? amount,
  }) {
    final parts = <String>[];
    final relative = _relativeFromDays(daysLeft) ?? _relativeDueLabel(dateRaw);
    if (relative != null) {
      parts.add(relative);
    } else if (displayDate != null) {
      parts.add('Due $displayDate');
    }
    if (status != null &&
        status.toLowerCase() != 'null' &&
        !parts.any((part) => part.toLowerCase().contains(status.toLowerCase()))) {
      parts.add(status);
    }
    if (amount != null) {
      parts.add('₹$amount');
    }
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  static DateTime? _parseDate(Object? value) {
    final raw = _clean(value);
    if (raw == null) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.toLocal();
    final slash = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$');
    final match = slash.firstMatch(raw);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      var year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      return DateTime(year, month, day);
    }
    final n = int.tryParse(raw);
    if (n != null) {
      if (n > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true).toLocal();
      }
      if (n > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true)
            .toLocal();
      }
    }
    return null;
  }

  static String? _relativeFromDays(int? days) {
    if (days == null) return null;
    if (days <= 0) return 'Due Today';
    if (days == 1) return 'Due In 1 Day';
    return 'Due In $days Days';
  }

  static String? _relativeDueLabel(Object? value) {
    final parsed = _parseDate(value);
    if (parsed == null) return null;
    final now = DateTime.now();
    final days =
        parsed.difference(DateTime(now.year, now.month, now.day)).inDays;
    return _relativeFromDays(days);
  }
}
