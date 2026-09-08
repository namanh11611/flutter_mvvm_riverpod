import '../../model/settlement.dart';
import '../../model/settlement_filter.dart';
import '../../model/settlement_receipt.dart';
import '../../model/settlement_suggestion.dart';
import '../../model/traveller.dart';

class SettlementState {
  const SettlementState({
    required this.tripId,
    required this.currency,
    required this.currentUserId,
    this.travellers = const [],
    this.settlements = const [],
    this.receipts = const {},
    this.suggestions = const [],
    this.filter = SettlementFilter.all,
    this.query = '',
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
  });

  final String tripId;
  final String currency;
  final String currentUserId;
  final List<Traveller> travellers;
  final List<Settlement> settlements;
  final Map<String, SettlementReceipt> receipts;
  final List<SettlementSuggestion> suggestions;
  final SettlementFilter filter;
  final String query;
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;

  String travellerName(String userId) {
    for (final traveller in travellers) {
      if (traveller.userId == userId) return traveller.displayName;
    }
    return 'Traveller';
  }

  double outstandingFor(String payerId, String payeeId) {
    var suggestedAmount = 0.0;
    for (final suggestion in suggestions) {
      if (suggestion.payerId == payerId && suggestion.payeeId == payeeId) {
        suggestedAmount = suggestion.amount;
        break;
      }
    }
    final pendingAmount = settlements
        .where((settlement) =>
            settlement.status == SettlementStatus.pending &&
            settlement.payerId == payerId &&
            settlement.payeeId == payeeId)
        .fold<double>(0, (sum, settlement) => sum + settlement.amount);
    final available = suggestedAmount - pendingAmount;
    return available > 0 ? available : 0;
  }

  List<Settlement> get filteredSettlements => SettlementFilterHelper.apply(
        settlements: settlements,
        filter: filter,
        query: query,
        travellerName: travellerName,
      );

  SettlementState copyWith({
    List<Settlement>? settlements,
    Map<String, SettlementReceipt>? receipts,
    List<SettlementSuggestion>? suggestions,
    SettlementFilter? filter,
    String? query,
    bool? isSaving,
    String? successMessage,
    String? errorMessage,
    bool clearSuccess = false,
    bool clearError = false,
  }) =>
      SettlementState(
        tripId: tripId,
        currency: currency,
        currentUserId: currentUserId,
        travellers: travellers,
        settlements: settlements ?? this.settlements,
        receipts: receipts ?? this.receipts,
        suggestions: suggestions ?? this.suggestions,
        filter: filter ?? this.filter,
        query: query ?? this.query,
        isSaving: isSaving ?? this.isSaving,
        successMessage:
            clearSuccess ? null : successMessage ?? this.successMessage,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}
