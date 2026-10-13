/// The daily break budget and hard schedule, as reported by native.
///
/// "Unblocking" is a timed break that eats into a fixed daily budget; once it is spent
/// (or during the hard window) no further break is possible. All values come from the
/// native side, which is the single source of truth.
class UnblockInfo {
  const UnblockInfo({
    required this.budgetMs,
    required this.usedMs,
    required this.remainingMs,
    required this.sessions,
    required this.active,
    required this.hardWindow,
    required this.activeSince,
  });

  /// Total budget for the day (1h30m).
  final int budgetMs;

  /// Spent today, including a running break.
  final int usedMs;

  /// Budget left today.
  final int remainingMs;

  /// Number of breaks started today.
  final int sessions;

  /// Whether a break is running right now.
  final bool active;

  /// Whether the hard schedule (12am–10am) currently forbids breaks.
  final bool hardWindow;

  /// Epoch ms the running break started, or 0.
  final int activeSince;

  bool get canStart => !active && !hardWindow && remainingMs > 0;

  double get usedFraction =>
      budgetMs == 0 ? 0 : (usedMs / budgetMs).clamp(0.0, 1.0);

  factory UnblockInfo.fromMap(Map<dynamic, dynamic> map) => UnblockInfo(
        budgetMs: (map['budgetMs'] as num).toInt(),
        usedMs: (map['usedMs'] as num).toInt(),
        remainingMs: (map['remainingMs'] as num).toInt(),
        sessions: (map['sessions'] as num).toInt(),
        active: map['active'] as bool,
        hardWindow: map['hardWindow'] as bool,
        activeSince: (map['activeSince'] as num?)?.toInt() ?? 0,
      );

  /// Fallback used by tests and by any older native payload.
  static const UnblockInfo empty = UnblockInfo(
    budgetMs: 90 * 60 * 1000,
    usedMs: 0,
    remainingMs: 90 * 60 * 1000,
    sessions: 0,
    active: false,
    hardWindow: false,
    activeSince: 0,
  );
}
