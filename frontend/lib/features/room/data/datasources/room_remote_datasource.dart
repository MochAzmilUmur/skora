import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/models.dart';

abstract class RoomRemoteDataSource {
  Future<List<RoomModel>> getRooms();
  Future<List<RoomModel>> getRoomsByUser(int userId);
  Future<RoomModel> getRoomById(String id);
  Future<RoomModel> getRoomByCode(String code);
  Future<RoomModel> createRoom(Map<String, dynamic> data);
  Future<RoomModel> updateRoom(String id, Map<String, dynamic> data);
  Future<void> deleteRoom(String id);
  Future<Map<String, dynamic>> joinRoom(String roomCode, int userId);
  Future<List<RoomParticipantModel>> getRoomParticipants(String roomId);
  Future<RoomParticipantModel> addParticipant({required String roomId, required int userId, required ParticipantRole role});
  Future<void> removeParticipant(String roomId, int participantId);
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  @override
  Future<List<RoomModel>> getRooms() async {
    final response = await ApiClient.get('/rooms');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RoomModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load rooms: ${response.statusCode}');
  }

  @override
  Future<List<RoomModel>> getRoomsByUser(int userId) async {
    final response = await ApiClient.get('/rooms/user/$userId');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RoomModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load rooms: ${response.statusCode}');
  }

  @override
  Future<RoomModel> getRoomById(String id) async {
    final response = await ApiClient.get('/rooms/$id');
    if (response.statusCode == 200) return RoomModel.fromJson(jsonDecode(response.body));
    throw Exception('Failed to load room: ${response.statusCode}');
  }

  @override
  Future<RoomModel> getRoomByCode(String code) async {
    final response = await ApiClient.get('/rooms/code/$code');
    if (response.statusCode == 200) return RoomModel.fromJson(jsonDecode(response.body));
    throw Exception('Room not found');
  }

  @override
  Future<RoomModel> createRoom(Map<String, dynamic> data) async {
    AppLogger.log('Creating room: ${data['room_name']}', tag: 'RoomDataSource');
    final response = await ApiClient.post('/rooms', data);
    if (response.statusCode == 201) return RoomModel.fromJson(jsonDecode(response.body));
    throw Exception('Failed to create room: ${response.statusCode}');
  }

  @override
  Future<RoomModel> updateRoom(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/rooms/$id', data);
    if (response.statusCode == 200) return RoomModel.fromJson(jsonDecode(response.body));
    throw Exception('Failed to update room: ${response.statusCode}');
  }

  @override
  Future<void> deleteRoom(String id) async {
    final response = await ApiClient.delete('/rooms/$id');
    if (response.statusCode != 200) throw Exception('Failed to delete room: ${response.statusCode}');
  }

  @override
  Future<Map<String, dynamic>> joinRoom(String roomCode, int userId) async {
    final response = await ApiClient.post('/rooms/join', {
      'room_code': roomCode,
      'user_id': userId,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final error = jsonDecode(response.body)['error'] ?? 'Failed to join room';
    throw Exception(error);
  }

  @override
  Future<List<RoomParticipantModel>> getRoomParticipants(String roomId) async {
    final response = await ApiClient.get('/rooms/$roomId/participants');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RoomParticipantModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load participants: ${response.statusCode}');
  }

  @override
  Future<RoomParticipantModel> addParticipant({
    required String roomId,
    required int userId,
    required ParticipantRole role,
  }) async {
    final response = await ApiClient.post('/rooms/$roomId/participants', {
      'user_id': userId,
      'role': role.toJson(),
    });
    if (response.statusCode == 201) return RoomParticipantModel.fromJson(jsonDecode(response.body));
    throw Exception('Failed to add participant: ${response.statusCode}');
  }

  @override
  Future<void> removeParticipant(String roomId, int participantId) async {
    final response = await ApiClient.delete('/rooms/$roomId/participants/$participantId');
    if (response.statusCode != 200) throw Exception('Failed to remove participant: ${response.statusCode}');
  }
}
