import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../domain/connection.dart';
import '../domain/connection_repository.dart';
import '../domain/connection_request.dart';

class LocalConnectionRepository implements ConnectionRepository {
  const LocalConnectionRepository(this.storage);
  final LocalStorage storage;
  static const key = 'local_connections.v1';

  Future<Map<String, dynamic>> _read() async {
    final raw = await storage.getString(key);
    if (raw == null) return {'requests': <dynamic>[], 'connections': <dynamic>[]};
    try { final value = jsonDecode(raw); return value is Map<String, dynamic> ? value : {'requests': <dynamic>[], 'connections': <dynamic>[]}; } on FormatException { return {'requests': <dynamic>[], 'connections': <dynamic>[]}; }
  }
  Future<void> _write(Map<String, dynamic> value) => storage.setString(key, jsonEncode(value));
  ConnectionRequest _request(Map value) => ConnectionRequest(id: value['id'] as String, senderUserId: value['sender'] as String, recipientUserId: value['recipient'] as String, encounterId: value['encounter'] as String, createdAt: DateTime.parse(value['createdAt'] as String), status: ConnectionRequestStatus.values.byName(value['status'] as String));
  Map<String, dynamic> _requestJson(ConnectionRequest r) => {'id': r.id, 'sender': r.senderUserId, 'recipient': r.recipientUserId, 'encounter': r.encounterId, 'createdAt': r.createdAt.toIso8601String(), 'status': r.status.name};
  Connection _connection(Map value) => Connection(id: value['id'] as String, userAId: value['a'] as String, userBId: value['b'] as String, encounterId: value['encounter'] as String, connectedAt: DateTime.parse(value['connectedAt'] as String));
  @override Future<ConnectionRequest?> getRelationship({required String userAId, required String userBId, required String encounterId}) async { for (final raw in (await _read())['requests'] as List) { final r = _request(raw); if (r.encounterId == encounterId && ((r.senderUserId == userAId && r.recipientUserId == userBId) || (r.senderUserId == userBId && r.recipientUserId == userAId))) return r; } return null; }
  @override Future<ConnectionRequest> sendRequest({required String senderUserId, required String recipientUserId, required String encounterId}) async { if (senderUserId == recipientUserId || encounterId.isEmpty) throw ArgumentError('Invalid connection request'); final data = await _read(); final requests = (data['requests'] as List).map(_request).toList(); final existing = requests.where((r) => r.encounterId == encounterId && ((r.senderUserId == senderUserId && r.recipientUserId == recipientUserId) || (r.senderUserId == recipientUserId && r.recipientUserId == senderUserId))).firstOrNull; if (existing != null) { if (existing.status == ConnectionRequestStatus.pending || existing.status == ConnectionRequestStatus.declined || existing.status == ConnectionRequestStatus.accepted) return existing; } final r = ConnectionRequest(id: '$senderUserId-$recipientUserId-$encounterId', senderUserId: senderUserId, recipientUserId: recipientUserId, encounterId: encounterId, createdAt: DateTime.now().toUtc(), status: ConnectionRequestStatus.pending); requests.add(r); data['requests'] = requests.map(_requestJson).toList(); await _write(data); return r; }
  @override Future<List<ConnectionRequest>> getIncomingRequests(String id) async => (await _read())['requests'] is List ? ((await _read())['requests'] as List).map(_request).where((r) => r.recipientUserId == id && r.status == ConnectionRequestStatus.pending).toList() : [];
  @override Future<List<ConnectionRequest>> getOutgoingRequests(String id) async => ((await _read())['requests'] as List).map(_request).where((r) => r.senderUserId == id).toList();
  Future<ConnectionRequest> _change(String id, String user, ConnectionRequestStatus status) async { final data = await _read(); final list = (data['requests'] as List).map(_request).toList(); final i = list.indexWhere((r) => r.id == id && r.recipientUserId == user && r.status == ConnectionRequestStatus.pending); if (i < 0) throw StateError('Request is not actionable'); final updated = ConnectionRequest(id: list[i].id, senderUserId: list[i].senderUserId, recipientUserId: list[i].recipientUserId, encounterId: list[i].encounterId, createdAt: list[i].createdAt, status: status); list[i] = updated; data['requests'] = list.map(_requestJson).toList(); if (status == ConnectionRequestStatus.accepted) { final connections = ((data['connections'] as List?) ?? []).map(_connection).toList(); final a = updated.senderUserId.compareTo(updated.recipientUserId) < 0 ? updated.senderUserId : updated.recipientUserId; final b = a == updated.senderUserId ? updated.recipientUserId : updated.senderUserId; if (!connections.any((c) => c.userAId == a && c.userBId == b)) { connections.add(Connection(id: '$a-$b', userAId: a, userBId: b, encounterId: updated.encounterId, connectedAt: DateTime.now().toUtc())); } data['connections'] = connections.map((c) => {'id': c.id, 'a': c.userAId, 'b': c.userBId, 'encounter': c.encounterId, 'connectedAt': c.connectedAt.toIso8601String()}).toList(); } await _write(data); return updated; }
  @override Future<ConnectionRequest> acceptRequest({required String requestId, required String recipientUserId}) => _change(requestId, recipientUserId, ConnectionRequestStatus.accepted);
  @override Future<ConnectionRequest> declineRequest({required String requestId, required String recipientUserId}) => _change(requestId, recipientUserId, ConnectionRequestStatus.declined);
  @override Future<List<Connection>> getConnections(String id) async => ((await _read())['connections'] as List? ?? []).map(_connection).where((c) => c.userAId == id || c.userBId == id).toList();
}
