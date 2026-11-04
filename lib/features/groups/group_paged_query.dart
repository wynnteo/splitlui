import 'package:supabase_flutter/supabase_flutter.dart';

/// Read all group rows instead of silently accepting PostgREST's default
/// row cap. Stable ordering makes page boundaries deterministic.
class GroupPagedQuery {
  const GroupPagedQuery(this.db);
  final SupabaseClient db;

  Future<List<Map<String,dynamic>>> read({
    required String table,
    required String columns,
    required String groupId,
    String orderBy='created_at',
    String? secondOrder='id',
    String? filterColumn,
    String? filterValue,
    bool ascending=false,
  }) async {
    const pageSize=500;
    final all=<Map<String,dynamic>>[];
    var offset=0;
    while(true) {
      var query=db.from(table).select(columns).eq('group_id',groupId);
      if(filterColumn!=null && filterValue!=null) {
        query=query.eq(filterColumn,filterValue);
      }
      var ordered=query.order(orderBy,ascending:ascending);
      if(secondOrder!=null && secondOrder!=orderBy) {
        ordered=ordered.order(secondOrder,ascending:ascending);
      }
      final page=await ordered.range(offset,offset+pageSize-1);
      all.addAll(page.map((r)=>Map<String,dynamic>.from(r)));
      if(page.length<pageSize) break;
      offset+=pageSize;
    }
    return all;
  }
}
