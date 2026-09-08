import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/settlement.dart';
import '../model/settlement_receipt.dart';
import 'group_expense_repository_exception.dart';
import 'receipt_mutation_workflow.dart';
import 'receipt_storage_service.dart';
import 'settlement_repository.dart';

class SupabaseSettlementRepository implements SettlementRepository {
  const SupabaseSettlementRepository(this.client, this.receipts);
  final SupabaseClient client;
  final ReceiptStorageService receipts;

  @override
  Future<List<Settlement>> getSettlementsForTrip(String tripId) =>
      _guard(() async {
        final rows = await client
            .from('settlements')
            .select()
            .eq('trip_id', tripId)
            .order('created_at', ascending: false);
        return rows.map(_settlement).toList(growable: false);
      });
  @override
  Future<List<Settlement>> getCompletedSettlements(String tripId) =>
      _status(tripId, 'completed');
  @override
  Future<List<Settlement>> getPendingSettlements(String tripId) =>
      _status(tripId, 'pending');
  Future<List<Settlement>> _status(String tripId, String status) =>
      _guard(() async {
        final rows = await client
            .from('settlements')
            .select()
            .eq('trip_id', tripId)
            .eq('status', status);
        return rows.map(_settlement).toList(growable: false);
      });

  @override
  Future<String> createSettlement(Settlement value,
          {SettlementReceipt? receipt}) =>
      _guard(() async {
        final row = await client
            .from('settlements')
            .insert(_write(value))
            .select()
            .single();
        final id = row['id'] as String;
        if (receipt != null) {
          String? objectPath;
          try {
            objectPath = await receipts.uploadSettlementReceipt(
                tripId: value.tripId,
                settlementId: id,
                sourcePath: receipt.imagePath);
            await upsertReceipt(id, objectPath);
          } catch (_) {
            if (objectPath != null) {
              await receipts.deleteReceipt(objectPath);
            }
            await client.from('settlements').delete().eq('id', id);
            rethrow;
          }
        }
        return id;
      });

  @override
  Future<void> updateSettlement(Settlement value,
          {SettlementReceipt? receipt, bool removeReceipt = false}) =>
      _guard(() async {
        final id = value.settlementId!;
        if (value.status != SettlementStatus.pending) {
          await client.rpc('group_expense_transition_settlement',
              params: {'p_settlement_id': id, 'p_status': value.status.name});
        }
        final old = await getReceipt(value.tripId, id);
        if (removeReceipt) {
          if (old != null) {
            await ReceiptMutationWorkflow.remove(
              objectPath: old.imagePath,
              deleteObject: receipts.deleteReceipt,
              deleteMetadata: () => client
                  .from('settlement_receipts')
                  .delete()
                  .eq('settlement_id', id),
            );
          }
        }
        if (receipt != null) {
          await ReceiptMutationWorkflow.replace(
            oldObjectPath: old?.imagePath,
            upload: () => receipts.uploadSettlementReceipt(
              tripId: value.tripId,
              settlementId: id,
              sourcePath: receipt.imagePath,
            ),
            updateMetadata: (path) => upsertReceipt(id, path),
            deleteObject: receipts.deleteReceipt,
          );
        }
      });

  Future<void> upsertReceipt(String settlementId, String objectPath) =>
      _guard(() async {
        await client.from('settlement_receipts').upsert(
            {'settlement_id': settlementId, 'object_path': objectPath},
            onConflict: 'settlement_id');
      });

  @override
  Future<void> deleteSettlement(String tripId, String settlementId) =>
      _guard(() async {
        final receipt = await getReceipt(tripId, settlementId);
        if (receipt != null) await receipts.deleteReceipt(receipt.imagePath);
        final deletedRows = await client
            .from('settlements')
            .delete()
            .eq('trip_id', tripId)
            .eq('id', settlementId)
            .select('id');
        requireDeletedSettlement(deletedRows);
      });

  static void requireDeletedSettlement(List<dynamic> deletedRows) {
    if (deletedRows.isEmpty) {
      throw const GroupExpenseRepositoryException(
        'The settlement was not deleted. Refresh and try again.',
        code: 'delete_failed',
      );
    }
  }
  @override
  Future<SettlementReceipt?> getReceipt(String tripId, String settlementId) =>
      _guard(() async {
        final settlement = await client
            .from('settlements')
            .select('id')
            .eq('trip_id', tripId)
            .eq('id', settlementId)
            .maybeSingle();
        if (settlement == null) return null;
        final row = await client
            .from('settlement_receipts')
            .select()
            .eq('settlement_id', settlementId)
            .maybeSingle();
        return row == null ? null : _receipt(row);
      });
  @override
  Future<Map<String, SettlementReceipt>> getReceiptsForTrip(String tripId) =>
      _guard(() async {
        final settlements = await getSettlementsForTrip(tripId);
        final ids = settlements.map((e) => e.settlementId!).toList();
        if (ids.isEmpty) return {};
        final rows = await client
            .from('settlement_receipts')
            .select()
            .inFilter('settlement_id', ids);
        return {
          for (final row in rows) row['settlement_id'] as String: _receipt(row)
        };
      });

  Map<String, Object?> _write(Settlement s) => {
        'trip_id': s.tripId,
        'payer_id': s.payerId,
        'payee_id': s.payeeId,
        'amount': s.amount,
        'payment_method': s.paymentMethod,
        'settlement_date': s.settlementDate.toIso8601String().substring(0, 10),
        'status': 'pending',
        'notes': s.notes
      };
  Settlement _settlement(Map<String, dynamic> r) => Settlement(
      settlementId: r['id'] as String,
      tripId: r['trip_id'] as String,
      payerId: r['payer_id'] as String,
      payeeId: r['payee_id'] as String,
      amount: (r['amount'] as num).toDouble(),
      paymentMethod: r['payment_method'] as String,
      settlementDate: DateTime.parse(r['settlement_date'] as String),
      status: SettlementStatus.values.byName(r['status'] as String),
      notes: r['notes'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String));
  SettlementReceipt _receipt(Map<String, dynamic> r) => SettlementReceipt(
      receiptId: r['id'] as String,
      settlementId: r['settlement_id'] as String,
      imagePath: r['object_path'] as String,
      uploadedAt: DateTime.parse(r['uploaded_at'] as String));
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      groupExpenseFailure(error);
    }
  }
}
