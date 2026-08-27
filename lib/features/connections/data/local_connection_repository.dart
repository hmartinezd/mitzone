import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../domain/connection.dart';
import '../domain/connection_repository.dart';
import '../domain/connection_request.dart';

class LocalConnectionRepository implements ConnectionRepository {
  const LocalConnectionRepository(this.storage, {this.now = _defaultNow});
  final LocalStorage storage;
  final DateTime Function() now;
  static const key = 'local_connections.v1';
  static DateTime _defaultNow() => DateTime.now().toUtc();
  static Map<String, dynamic> _empty() => {
    'requests': <dynamic>[],
    'connections': <dynamic>[],
  };

  Future<Map<String, dynamic>> _read() async {
    final raw = await storage.getString(key);
    if (raw == null) return _empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _empty();
      return {
        'requests': decoded['requests'] is List
            ? decoded['requests']
            : <dynamic>[],
        'connections': decoded['connections'] is List
            ? decoded['connections']
            : <dynamic>[],
      };
    } on FormatException {
      return _empty();
    }
  }

  Future<void> _write(Map<String, dynamic> data) =>
      storage.setString(key, jsonEncode(data));
  ConnectionRequest? _tryRequest(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['sender'] is! String ||
        raw['recipient'] is! String ||
        raw['encounter'] is! String ||
        raw['createdAt'] is! String ||
        raw['status'] is! String) {
      return null;
    }
    final date = DateTime.tryParse(raw['createdAt'] as String);
    final status = ConnectionRequestStatus.values
        .where((s) => s.name == raw['status'])
        .firstOrNull;
    if (date == null || status == null) return null;
    return ConnectionRequest(
      id: raw['id'] as String,
      senderUserId: raw['sender'] as String,
      recipientUserId: raw['recipient'] as String,
      encounterId: raw['encounter'] as String,
      contextId: raw['context'] is String ? raw['context'] as String : null,
      createdAt: date,
      status: status,
    );
  }

  Connection? _tryConnection(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['a'] is! String ||
        raw['b'] is! String ||
        raw['encounter'] is! String ||
        raw['connectedAt'] is! String) {
      return null;
    }
    final date = DateTime.tryParse(raw['connectedAt'] as String);
    if (date == null) return null;
    return Connection(
      id: raw['id'] as String,
      userAId: raw['a'] as String,
      userBId: raw['b'] as String,
      encounterId: raw['encounter'] as String,
      connectedAt: date,
    );
  }

  List<ConnectionRequest> _parseRequests(Object? raw) => raw is List
      ? raw.map(_tryRequest).whereType<ConnectionRequest>().toList()
      : [];
  List<Connection> _parseConnections(Object? raw) => raw is List
      ? raw.map(_tryConnection).whereType<Connection>().toList()
      : [];
  Map<String, dynamic> _requestJson(ConnectionRequest r) => {
    'id': r.id,
    'sender': r.senderUserId,
    'recipient': r.recipientUserId,
    'encounter': r.encounterId,
    if (r.contextId != null) 'context': r.contextId,
    'createdAt': r.createdAt.toIso8601String(),
    'status': r.status.name,
  };
  @override
  Future<ConnectionRequest?> getRelationship({
    required String userAId,
    required String userBId,
    required String encounterId,
  }) async => _parseRequests((await _read())['requests'])
      .where(
        (r) =>
            r.encounterId == encounterId &&
            ((r.senderUserId == userAId && r.recipientUserId == userBId) ||
                (r.senderUserId == userBId && r.recipientUserId == userAId)),
      )
      .firstOrNull;
  @override
  Future<ConnectionRequest> sendRequest({
    required String senderUserId,
    required String recipientUserId,
    required String encounterId,
    String? contextId,
  }) async {
    if (senderUserId == recipientUserId || encounterId.isEmpty) {
      throw ArgumentError('Invalid connection request');
    }
    final data = await _read();
    final requests = _parseRequests(data['requests']);
    final context = contextId ?? encounterId;
    final existing = requests
        .where(
          (r) =>
              ((r.senderUserId == senderUserId &&
                      r.recipientUserId == recipientUserId) ||
                  (r.senderUserId == recipientUserId &&
                      r.recipientUserId == senderUserId)) &&
              (r.contextId ?? r.encounterId) == context,
        )
        .firstOrNull;
    if (existing != null) return existing;
    final request = ConnectionRequest(
      id: '$senderUserId-$recipientUserId-$context',
      senderUserId: senderUserId,
      recipientUserId: recipientUserId,
      encounterId: encounterId,
      contextId: context,
      createdAt: now().toUtc(),
      status: ConnectionRequestStatus.pending,
    );
    requests.add(request);
    data['requests'] = requests.map(_requestJson).toList();
    await _write(data);
    return request;
  }

  @override
  Future<List<ConnectionRequest>> getIncomingRequests(String id) async =>
      _parseRequests((await _read())['requests'])
          .where(
            (r) =>
                r.recipientUserId == id &&
                r.status == ConnectionRequestStatus.pending,
          )
          .toList();
  @override
  Future<List<ConnectionRequest>> getOutgoingRequests(String id) async =>
      _parseRequests(
        (await _read())['requests'],
      ).where((r) => r.senderUserId == id).toList();
  Future<ConnectionRequest> _change(
    String id,
    String user,
    ConnectionRequestStatus status,
  ) async {
    final data = await _read();
    final requests = _parseRequests(data['requests']);
    final index = requests.indexWhere(
      (r) =>
          r.id == id &&
          r.recipientUserId == user &&
          r.status == ConnectionRequestStatus.pending,
    );
    if (index < 0) throw StateError('Request is not actionable');
    final old = requests[index];
    final updated = ConnectionRequest(
      id: old.id,
      senderUserId: old.senderUserId,
      recipientUserId: old.recipientUserId,
      encounterId: old.encounterId,
      contextId: old.contextId,
      createdAt: old.createdAt,
      status: status,
    );
    requests[index] = updated;
    data['requests'] = requests.map(_requestJson).toList();
    if (status == ConnectionRequestStatus.accepted) {
      final a = old.senderUserId.compareTo(old.recipientUserId) < 0
          ? old.senderUserId
          : old.recipientUserId;
      final b = a == old.senderUserId ? old.recipientUserId : old.senderUserId;
      final connections = _parseConnections(data['connections']);
      if (!connections.any((c) => c.userAId == a && c.userBId == b)) {
        connections.add(
          Connection(
            id: '$a-$b',
            userAId: a,
            userBId: b,
            encounterId: old.encounterId,
            connectedAt: now().toUtc(),
          ),
        );
      }
      data['connections'] = connections
          .map(
            (c) => {
              'id': c.id,
              'a': c.userAId,
              'b': c.userBId,
              'encounter': c.encounterId,
              'connectedAt': c.connectedAt.toIso8601String(),
            },
          )
          .toList();
    }
    await _write(data);
    return updated;
  }

  @override
  Future<ConnectionRequest> acceptRequest({
    required String requestId,
    required String recipientUserId,
  }) => _change(requestId, recipientUserId, ConnectionRequestStatus.accepted);
  @override
  Future<ConnectionRequest> declineRequest({
    required String requestId,
    required String recipientUserId,
  }) => _change(requestId, recipientUserId, ConnectionRequestStatus.declined);
  @override
  Future<List<Connection>> getConnections(String id) async => _parseConnections(
    (await _read())['connections'],
  ).where((c) => c.userAId == id || c.userBId == id).toList();
  @override
  Future<RelationshipState> getRelationshipState({
    required String userAId,
    required String userBId,
  }) async {
    final connections = await getConnections(userAId);
    if (connections.any(
      (c) =>
          (c.userAId == userAId && c.userBId == userBId) ||
          (c.userAId == userBId && c.userBId == userAId),
    )) {
      return RelationshipState.connected;
    }
    final requests = _parseRequests((await _read())['requests']).where(
      (r) =>
          (r.senderUserId == userAId && r.recipientUserId == userBId) ||
          (r.senderUserId == userBId && r.recipientUserId == userAId),
    );
    final pending = requests
        .where((r) => r.status == ConnectionRequestStatus.pending)
        .firstOrNull;
    if (pending != null) {
      return pending.senderUserId == userAId
          ? RelationshipState.outgoingPending
          : RelationshipState.incomingPending;
    }
    if (requests.any((r) => r.status == ConnectionRequestStatus.declined)) {
      return RelationshipState.declined;
    }
    return RelationshipState.none;
  }
}
