import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/connection.dart';
import '../domain/connection_repository.dart';
import '../domain/connection_request.dart';

class SupabaseConnectionRepository implements ConnectionRepository {
  const SupabaseConnectionRepository(this.client);
  final SupabaseClient client;
  String _user(String requested) {
    final id = client.auth.currentUser?.id;
    if (id == null || id != requested)
      throw StateError('Authentication required');
    return id;
  }

  ConnectionRequest _request(Map<String, dynamic> r) => ConnectionRequest(
    id: r['id'] as String,
    senderUserId: r['sender_user_id'] as String,
    recipientUserId: r['recipient_user_id'] as String,
    encounterId: r['encounter_id'] as String,
    createdAt: DateTime.parse(r['created_at'] as String),
    status: ConnectionRequestStatus.values.byName(r['status'] as String),
    contextId: r['context_id'] as String?,
  );
  Connection _connection(Map<String, dynamic> r) => Connection(
    id: r['id'] as String,
    userAId: r['user_a_id'] as String,
    userBId: r['user_b_id'] as String,
    encounterId: r['encounter_id'] as String,
    connectedAt: DateTime.parse(r['connected_at'] as String),
    contextId: r['context_id'] as String?,
  );
  @override
  Future<ConnectionRequest?> getRelationship({
    required String userAId,
    required String userBId,
    required String encounterId,
    String? contextId,
  }) async {
    final me = _user(userAId);
    final row = await client
        .from('connection_requests')
        .select()
        .or('sender_user_id.eq.$me,recipient_user_id.eq.$me')
        .eq('encounter_id', encounterId)
        .maybeSingle();
    return row == null ? null : _request(row);
  }

  @override
  Future<ConnectionRequest> sendRequest({
    required String senderUserId,
    required String recipientUserId,
    required String encounterId,
    String? contextId,
  }) async {
    _user(senderUserId);
    final row = await client.rpc(
      'send_connection_request',
      params: {
        'p_other_user_id': recipientUserId,
        'p_encounter_id': encounterId,
      },
    );
    return _request(row as Map<String, dynamic>);
  }

  @override
  Future<ConnectionRequest> acceptRequest({
    required String requestId,
    required String recipientUserId,
  }) async {
    _user(recipientUserId);
    return _request(
      (await client.rpc(
            'accept_connection_request',
            params: {'p_request_id': requestId},
          ))
          as Map<String, dynamic>,
    );
  }

  @override
  Future<ConnectionRequest> declineRequest({
    required String requestId,
    required String recipientUserId,
  }) async {
    _user(recipientUserId);
    return _request(
      (await client.rpc(
            'decline_connection_request',
            params: {'p_request_id': requestId},
          ))
          as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ConnectionRequest>> getIncomingRequests(String userId) async {
    final me = _user(userId);
    final rows = await client
        .from('connection_requests')
        .select()
        .eq('recipient_user_id', me)
        .order('created_at', ascending: false);
    return [for (final r in rows) _request(r)];
  }

  @override
  Future<List<ConnectionRequest>> getOutgoingRequests(String userId) async {
    final me = _user(userId);
    final rows = await client
        .from('connection_requests')
        .select()
        .eq('sender_user_id', me)
        .order('created_at', ascending: false);
    return [for (final r in rows) _request(r)];
  }

  @override
  Future<List<Connection>> getConnections(String userId) async {
    final me = _user(userId);
    final rows = await client
        .from('connections')
        .select()
        .or('user_a_id.eq.$me,user_b_id.eq.$me');
    return [for (final r in rows) _connection(r)];
  }

  @override
  Future<void> removeConnection({
    required String connectionId,
    required String userId,
  }) async {
    _user(userId);
    await client.rpc(
      'remove_connection',
      params: {'p_connection_id': connectionId},
    );
  }

  @override
  Future<RelationshipState> getRelationshipState({
    required String userAId,
    required String userBId,
    String? contextId,
    String? encounterId,
  }) async {
    _user(userAId);
    final row = await client.rpc(
      'get_relationship_state',
      params: {'p_other_user_id': userBId, 'p_encounter_id': encounterId},
    );
    return RelationshipState.values.byName(row as String);
  }
}
