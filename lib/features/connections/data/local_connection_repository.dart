import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../domain/connection.dart';
import '../domain/connection_repository.dart';
import '../domain/connection_request.dart';

class LocalConnectionRepository implements ConnectionRepository {
  const LocalConnectionRepository(this.storage, {this.now = _defaultNow});
  final LocalStorage storage;
  final DateTime Function() now;
  static DateTime _defaultNow() => DateTime.now().toUtc();
  static const key = 'local_connections.v1';

  Future<Map<String, dynamic>> _read() async {
    final raw = await storage.getString(key);
    if (raw == null) return {'requests': <dynamic>[], 'connections': <dynamic>[]};
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return {'requests': <dynamic>[], 'connections': <dynamic>[]};
      return {
        'requests': value['requests'] is List ? value['requests'] : <dynamic>[],
        'connections': value['connections'] is List ? value['connections'] : <dynamic>[],
      };
    } on FormatException { return {'requests': <dynamic>[], 'connections': <dynamic>[]}; }
  }
  Future<void> _write(Map<String, dynamic> value) => storage.setString(key, jsonEncode(value));
  ConnectionRequest? _tryRequest(Object? raw) { if (raw is! Map || raw['id'] is! String || raw['sender'] is! String || raw['recipient'] is! String || raw['encounter'] is! String || raw['createdAt'] is! String || raw['status'] is! String) return null; final date = DateTime.tryParse(raw['createdAt'] as String); final status = ConnectionRequestStatus.values.where((s) => s.name == raw['status']).firstOrNull; if (date == null || status == null) return null; return ConnectionRequest(id: raw['id'] as String, senderUserId: raw['sender'] as String, recipientUserId: raw['recipient'] as String, encounterId: raw['encounter'] as String, createdAt: date, status: status); }
  Map<String, dynamic> _requestJson(ConnectionRequest r) => {'id': r.id, 'sender': r.senderUserId, 'recipient': r.recipientUserId, 'encounter': r.encounterId, 'createdAt': r.createdAt.toIso8601String(), 'status': r.status.name};
  Connection? _tryConnection(Object? raw) { if (raw is! Map || raw['id'] is! String || raw['a'] is! String || raw['b'] is! String || raw['encounter'] is! String || raw['connectedAt'] is! String) return null; final date = DateTime.tryParse(raw['connectedAt'] as String); if (date == null) return null; return Connection(id: raw['id'] as String, userAId: raw['a'] as String, userBId: raw['b'] as String, encounterId: raw['encounter'] as String, connectedAt: date); }
  @override Future<ConnectionRequest?> getRelationship({required String userAId, required String userBId, required String encounterId}) async { for (final raw in (await _read())['requests'] as List) { final r = _request(raw as Map); if (r.encounterId == encounterId && ((r.senderUserId == userAId && r.recipientUserId == userBId) || (r.senderUserId == userBId && r.recipientUserId == userAId))) return r; } return null; }
  @override Future<ConnectionRequest> sendRequest({required String senderUserId, required String recipientUserId, required String encounterId}) async { if (senderUserId == recipientUserId || encounterId.isEmpty) throw ArgumentError('Invalid connection request'); final data = await _read(); final requests = (data['requests'] as List).map((value) => _request(value as Map)).toList(); final existing = requests.where((r) => r.encounterId == encounterId && ((r.senderUserId == senderUserId && r.recipientUserId == recipientUserId) || (r.senderUserId == recipientUserId && r.recipientUserId == senderUserId))).firstOrNull; if (existing != null) return existing; final r = ConnectionRequest(id: '$senderUserId-$recipientUserId-$encounterId', senderUserId: senderUserId, recipientUserId: recipientUserId, encounterId: encounterId, createdAt: DateTime.now().toUtc(), status: ConnectionRequestStatus.pending); requests.add(r); data['requests'] = requests.map(_requestJson).toList(); await _write(data); return r; }
  Future<List<ConnectionRequest>> _requests() async => (await _read())['requests'] as List<dynamic>? ?? const [];
  @override Future<List<ConnectionRequest>> getIncomingRequests(String id) async => (await _requests()).map(_tryRequest).whereType<ConnectionRequest>().where((r) => r.recipientUserId == id && r.status == ConnectionRequestStatus.pending).toList();
  @override Future<List<ConnectionRequest>> getOutgoingRequests(String id) async => (await _requests()).map(_tryRequest).whereType<ConnectionRequest>().where((r) => r.senderUserId == id).toList();
  Future<ConnectionRequest> _change(String id, String user, ConnectionRequestStatus status) async { final data = await _read(); final list = (data['requests'] as List).map((value) => _request(value as Map)).toList(); final i = list.indexWhere((r) => r.id == id && r.recipientUserId == user && r.status == ConnectionRequestStatus.pending); if (i < 0) throw StateError('Request is not actionable'); final updated = ConnectionRequest(id: list[i].id, senderUserId: list[i].senderUserId, recipientUserId: list[i].recipientUserId, encounterId: list[i].encounterId, createdAt: list[i].createdAt, status: status); list[i] = updated; data['requests'] = list.map(_requestJson).toList(); if (status == ConnectionRequestStatus.accepted) { final connections = ((data['connections'] as List?) ?? []).map((value) => _connection(value as Map)).toList(); final a = updated.senderUserId.compareTo(updated.recipientUserId) < 0 ? updated.senderUserId : updated.recipientUserId; final b = a == updated.senderUserId ? updated.recipientUserId : updated.senderUserId; if (!connections.any((c) => c.userAId == a && c.userBId == b)) { connections.add(Connection(id: '$a-$b', userAId: a, userBId: b, encounterId: updated.encounterId, connectedAt: DateTime.now().toUtc())); } data['connections'] = connections.map((c) => {'id': c.id, 'a': c.userAId, 'b': c.userBId, 'encounter': c.encounterId, 'connectedAt': c.connectedAt.toIso8601String()}).toList(); } await _write(data); return updated; }
  @override Future<ConnectionRequest> acceptRequest({required String requestId, required String recipientUserId}) => _change(requestId, recipientUserId, ConnectionRequestStatus.accepted);
  @override Future<ConnectionRequest> declineRequest({required String requestId, required String recipientUserId}) => _change(requestId, recipientUserId, ConnectionRequestStatus.declined);
  @override Future<List<Connection>> getConnections(String id) async => ((await _read())['connections'] as List? ?? []).map(_tryConnection).whereType<Connection>().where((c) => c.userAId == id || c.userBId == id).toList();
  @override Future<RelationshipState> getRelationshipState({required String userAId, required String userBId}) async { final connections = await getConnections(userAId); if (connections.any((c) => (c.userAId == userAId && c.userBId == userBId) || (c.userAId == userBId && c.userBId == userAId))) return RelationshipState.connected; final requests = (await _requests()).map(_tryRequest).whereType<ConnectionRequest>().where((r) => (r.senderUserId == userAId && r.recipientUserId == userBId) || (r.senderUserId == userBId && r.recipientUserId == userAId)).toList(); final pending = requests.where((r) => r.status == ConnectionRequestStatus.pending).firstOrNull; if (pending != null) return pending.senderUserId == userAId ? RelationshipState.outgoingPending : RelationshipState.incomingPending; if (requests.any((r) => r.status == ConnectionRequestStatus.declined)) return RelationshipState.declined; return RelationshipState.none; }
}
