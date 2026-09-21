import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/cost/data/models/cost_category_model.dart';
import 'package:aanda/src/features/cost/data/models/cost_model.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

class CostRemoteDatasource {
  CostRemoteDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  String get _currentUserId =>
      _supabase.auth.currentUser?.id ?? (throw Exception('Not authenticated'));

  static const _selectQuery = '''
    id,
    house_id,
    cycle_id,
    paid_by,
    category_id,
    name,
    amount,
    cost_type,
    cost_scope,
    note,
    purchase_date,
    created_at,
    profiles (
      username,
      full_name
    ),
    cost_categories (
      name,
      icon
    )
  ''';

  Future<List<Cost>> getCosts({
    String? houseId,
    CostScope? scope,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final startStr = startDate != null
        ? '${startDate.year.toString().padLeft(4, '0')}-'
              '${startDate.month.toString().padLeft(2, '0')}-'
              '${startDate.day.toString().padLeft(2, '0')}'
        : null;

    final endStr = endDate != null
        ? '${endDate.year.toString().padLeft(4, '0')}-'
              '${endDate.month.toString().padLeft(2, '0')}-'
              '${endDate.day.toString().padLeft(2, '0')}'
        : null;

    // 1. Try Edge Function endpoint first
    try {
      final res = await _supabase.functions.invoke(
        'costs',
        body: {
          'action': 'list',
          if (scope != null) 'scope': scope.name,
          if (houseId != null) 'house_id': houseId,
          if (startStr != null) 'start_date': startStr,
          if (endStr != null) 'end_date': endStr,
        },
      );

      if (res.status == 200 &&
          res.data is Map &&
          (res.data as Map)['success'] == true) {
        final list = (res.data['data'] as List);
        return list
            .map((r) => CostModel.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fall back to direct query if edge function is not deployed yet
    }

    // 2. Direct query fallback
    var query = _supabase.from('costs').select(_selectQuery);

    if (scope != null) {
      query = query.eq('cost_scope', scope.name);
    }

    if (houseId != null) {
      query = query.eq('house_id', houseId);
    }

    if (startStr != null) {
      query = query.gte('purchase_date', startStr);
    }

    if (endStr != null) {
      query = query.lte('purchase_date', endStr);
    }

    final rows = await query
        .order('purchase_date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => CostModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Cost> addCost(CreateCostData data) async {
    final isCustomCategory =
        data.categoryId != null && !data.categoryId!.startsWith('predefined_');

    final dateStr =
        '${data.purchaseDate.year.toString().padLeft(4, '0')}-'
        '${data.purchaseDate.month.toString().padLeft(2, '0')}-'
        '${data.purchaseDate.day.toString().padLeft(2, '0')}';

    // 1. Try Edge Function endpoint
    try {
      final res = await _supabase.functions.invoke(
        'costs',
        body: {
          'action': 'create',
          'name': data.name,
          'amount': data.amount,
          'cost_type': data.costType.name,
          'cost_scope': data.costScope.name,
          'purchase_date': dateStr,
          if (data.houseId != null && data.houseId!.isNotEmpty)
            'house_id': data.houseId,
          if (data.cycleId != null && data.cycleId!.isNotEmpty)
            'cycle_id': data.cycleId,
          if (isCustomCategory &&
              data.categoryId != null &&
              data.categoryId!.isNotEmpty)
            'category_id': data.categoryId,
          if (data.note != null && data.note!.isNotEmpty) 'note': data.note,
          if (data.paidBy != null && data.paidBy!.isNotEmpty)
            'paid_by': data.paidBy,
        },
      );

      if (res.status == 200 &&
          res.data is Map &&
          (res.data as Map)['success'] == true) {
        return CostModel.fromJson(res.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback
    }

    // 2. Direct insert fallback
    final payload = {
      'name': data.name,
      'amount': data.amount,
      'cost_type': data.costType.name,
      'cost_scope': data.costScope.name,
      'paid_by': (data.paidBy != null && data.paidBy!.isNotEmpty)
          ? data.paidBy!
          : _currentUserId,
      'purchase_date': dateStr,
      if (data.houseId != null && data.houseId!.isNotEmpty)
        'house_id': data.houseId,
      if (data.cycleId != null && data.cycleId!.isNotEmpty)
        'cycle_id': data.cycleId,
      if (isCustomCategory &&
          data.categoryId != null &&
          data.categoryId!.isNotEmpty)
        'category_id': data.categoryId,
      if (data.note != null && data.note!.isNotEmpty) 'note': data.note,
    };

    final row = await _supabase
        .from('costs')
        .insert(payload)
        .select(_selectQuery)
        .single();

    return CostModel.fromJson(row);
  }

  Future<Cost> updateCost(UpdateCostData data) async {
    final isCustomCategory =
        data.categoryId != null && !data.categoryId!.startsWith('predefined_');

    final dateStr =
        '${data.purchaseDate.year.toString().padLeft(4, '0')}-'
        '${data.purchaseDate.month.toString().padLeft(2, '0')}-'
        '${data.purchaseDate.day.toString().padLeft(2, '0')}';

    // 1. Try Edge Function endpoint
    try {
      final res = await _supabase.functions.invoke(
        'costs',
        body: {
          'action': 'update',
          'id': data.id,
          'name': data.name,
          'amount': data.amount,
          'cost_type': data.costType.name,
          'cost_scope': data.costScope.name,
          'purchase_date': dateStr,
          'house_id': (data.houseId != null && data.houseId!.isNotEmpty)
              ? data.houseId
              : null,
          'cycle_id': (data.cycleId != null && data.cycleId!.isNotEmpty)
              ? data.cycleId
              : null,
          'category_id': (isCustomCategory &&
                  data.categoryId != null &&
                  data.categoryId!.isNotEmpty)
              ? data.categoryId
              : null,
          'note': data.note,
          if (data.paidBy != null && data.paidBy!.isNotEmpty)
            'paid_by': data.paidBy,
        },
      );

      if (res.status == 200 &&
          res.data is Map &&
          (res.data as Map)['success'] == true) {
        return CostModel.fromJson(res.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback
    }

    // 2. Direct update fallback
    final payload = {
      'name': data.name,
      'amount': data.amount,
      'cost_type': data.costType.name,
      'cost_scope': data.costScope.name,
      'purchase_date': dateStr,
      'house_id': (data.houseId != null && data.houseId!.isNotEmpty)
          ? data.houseId
          : null,
      'cycle_id': (data.cycleId != null && data.cycleId!.isNotEmpty)
          ? data.cycleId
          : null,
      'category_id': (isCustomCategory &&
              data.categoryId != null &&
              data.categoryId!.isNotEmpty)
          ? data.categoryId
          : null,
      'note': data.note,
      if (data.paidBy != null && data.paidBy!.isNotEmpty)
        'paid_by': data.paidBy,
    };

    final row = await _supabase
        .from('costs')
        .update(payload)
        .eq('id', data.id)
        .select(_selectQuery)
        .single();

    return CostModel.fromJson(row);
  }

  Future<void> deleteCost({required String costId}) async {
    // 1. Try Edge Function endpoint
    try {
      final res = await _supabase.functions.invoke(
        'costs',
        body: {'action': 'delete', 'cost_id': costId},
      );
      if (res.status == 200 &&
          res.data is Map &&
          (res.data as Map)['success'] == true) {
        return;
      }
    } catch (_) {
      // Fallback
    }

    // 2. Direct delete fallback
    await _supabase.from('costs').delete().eq('id', costId);
  }

  Future<List<CostCategory>> getCategories({String? houseId}) async {
    if (houseId != null) {
      // 1. Try Edge Function endpoint
      try {
        final res = await _supabase.functions.invoke(
          'costs',
          body: {'action': 'categories', 'house_id': houseId},
        );
        if (res.status == 200 &&
            res.data is Map &&
            (res.data as Map)['success'] == true) {
          final rows = res.data['data'] as List;
          return rows
              .map((r) => CostCategoryModel.fromJson(r as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // Fallback
      }

      // 2. Direct query fallback
      try {
        final rows = await _supabase
            .from('cost_categories')
            .select()
            .eq('house_id', houseId)
            .order('name');

        return (rows as List)
            .map((r) => CostCategoryModel.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }

    try {
      final rows = await _supabase
          .from('cost_categories')
          .select()
          .order('name');

      return (rows as List)
          .map((r) => CostCategoryModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CostCategory> createCategory(CreateCostCategoryData data) async {
    // Variable costs must never have default amount setup
    final defaultAmt = data.costNature == 'variable'
        ? null
        : data.defaultAmount;

    final payload = {
      'name': data.name,
      'icon': data.icon,
      'is_food': data.isFood,
      if (data.houseId != null) 'house_id': data.houseId,
      if (defaultAmt != null) 'default_amount': defaultAmt,
      'cost_nature': data.costNature,
    };

    try {
      final res = await _supabase
          .from('cost_categories')
          .insert(payload)
          .select()
          .single();
      return CostCategoryModel.fromJson(res);
    } catch (_) {
      // Fallback: return local entity
      return CostCategory(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: data.name,
        icon: data.icon,
        isFood: data.isFood,
        houseId: data.houseId,
        defaultAmount: defaultAmt,
        costNature: data.costNature,
      );
    }
  }
}
