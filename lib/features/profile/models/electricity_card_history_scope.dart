import '../../mobile_prepaid/models/latest_transaction.dart';
import 'transaction_history_entry.dart';

/// Clearly-scoped Electricity Card-Scoped View History mode.
///
/// This scope is ONLY for View History opened from an Electricity Saved
/// Biller card (3 dots -> View History). It must never affect the generic /
/// main Transaction History behavior.
///
/// Contract:
/// - [service] is always the canonical `'Electricity'`.
/// - [serviceNoFull] is the EXACT dynamic `service_no_full` read from the
///   selected card. Never hardcoded, never derived from `service_no`,
///   `masked_identifier`, `customer_mobile`, `customer_params` or last-4
///   digits.
/// - Every API page for this scope uses
///   `service=Electricity` + `service_no_full=<selected value>`.
class ElectricityCardHistoryScope {
  const ElectricityCardHistoryScope({required this.serviceNoFull});

  /// Canonical service name used in the API request for this scoped flow.
  static const String serviceName = 'Electricity';

  /// The selected card's exact `service_no_full` (trimmed, non-empty).
  final String serviceNoFull;

  bool get isValid => serviceNoFull.trim().isNotEmpty;

  /// Selected card's full number with whitespace stripped (comparison key).
  String get normalizedServiceNoFull =>
      serviceNoFull.trim().replaceAll(RegExp(r'\s+'), '');

  /// Strict card-scoped result rule (used for EVERY merged API page):
  /// - a row that explicitly carries a DIFFERENT full consumer number is
  ///   removed (normalized exact equality only — never contains/last-4),
  /// - a row that is definitely another service (FASTag/Mobile/Tuition/...)
  ///   is removed,
  /// - everything else (the selected card's rows, including rows that carry
  ///   no explicit full number) is kept, so valid records are never reduced.
  bool includesEntry(TransactionHistoryEntry entry) {
    if (entry.explicitlyBelongsToDifferentCard(normalizedServiceNoFull)) {
      return false;
    }
    if (entry.isDefinitelyOtherService) return false;
    return true;
  }

  /// Reads the EXACT `service_no_full` from the selected saved-biller card.
  ///
  /// Uses only [LatestTransaction.serviceNoFull] (the raw API field). Falls
  /// back to nothing: `service_no`, masked identifiers and customer params
  /// must never become the scope. Returns null when the card carries no
  /// usable full consumer number.
  static ElectricityCardHistoryScope? fromTransaction(
    LatestTransaction txn, {
    String? serviceCategory,
  }) {
    final rawFull = txn.serviceNoFull?.trim() ?? '';
    if (rawFull.isEmpty || rawFull.toLowerCase() == 'null') return null;
    return ElectricityCardHistoryScope(serviceNoFull: rawFull);
  }

  /// True only for the Electricity saved-biller View History entry point.
  static bool isElectricityCategory(String? serviceCategory) {
    final normalized = (serviceCategory ?? '').trim().toLowerCase();
    return normalized.contains('electric');
  }

  /// Builds the navigation extra for the scoped View History flow.
  Map<String, dynamic> toNavigationExtra() => <String, dynamic>{
        'service': serviceName,
        'consumerId': serviceNoFull,
        'serviceNoFull': serviceNoFull,
        'electricityCardScoped': true,
      };

  /// Parses the scoped mode back out of router `extra` (null when generic).
  static ElectricityCardHistoryScope? fromNavigationExtra(Object? extra) {
    if (extra is! Map) return null;
    final map = extra.map((key, value) => MapEntry(key.toString(), value));
    final scoped = map['electricityCardScoped'] == true ||
        map['scope'] == 'electricity-card';
    if (!scoped) return null;
    final raw = (map['serviceNoFull'] ?? map['consumerId'] ?? '')
        .toString()
        .trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
    final service = (map['service'] ?? '').toString().trim().toLowerCase();
    if (service.isNotEmpty &&
        !service.contains('electric') &&
        service != 'electricity') {
      return null;
    }
    return ElectricityCardHistoryScope(serviceNoFull: raw);
  }

  /// Back navigation for the scoped flow: pop back to the Electricity
  /// Fetch Your Provider screen when possible; otherwise fall back to
  /// opening it via the biller-listing route.
  static const String backFallbackCategory = 'Electricity';

  @override
  bool operator ==(Object other) =>
      other is ElectricityCardHistoryScope &&
      other.serviceNoFull.trim() == serviceNoFull.trim();

  @override
  int get hashCode => serviceNoFull.trim().hashCode;
}
