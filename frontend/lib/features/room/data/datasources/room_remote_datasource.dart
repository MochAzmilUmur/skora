import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/models.dart';

abstract class RoomRemoteDataSource {
  Future<RoomModel> createRoom({
    required String roomName,
    required int durasi,
    required String createdBy,
  });

  Future<List<RoomModel>> getRooms();
  Future<RoomModel> getRoomById(String id);
  Future<RoomModel> updateRoom(String id, Map<String, dynamic> data);
  Future<void> deleteRoom(String id);

  Future<List<RoomParticipantModel>> getRoomParticipants(String roomId);
  Future<RoomParticipantModel> addParticipant({
    required String roomId,
    required int userId,
    required ParticipantRole role,
  });
  Future<void> removeParticipant(int participantId);
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  @override
  Future<RoomModel> createRoom({
    required String roomName,
    required int durasi,
    required String createdBy,
  }) async {
    try {
      AppLogger.log('Creating room: $roomName', tag: 'RoomDataSource');
      
      final response = await ApiClient.post('/rooms', {
        'room_name': roomName,
        'durasi': durasi,
        'created_by': createdBy,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.log('Room created successfully: ${data['id_room']}', tag: 'RoomDataSource');
        return RoomModel.fromJson(data);
      }
      
      throw Exception('Failed to create room: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error creating room', tag: 'RoomDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<List<RoomModel>> getRooms() async {
    try {
      AppLogger.log('Fetching all rooms', tag: 'RoomDataSource');
      
      final response = await ApiClient.get('/rooms');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final rooms = data.map((json) => RoomModel.fromJson(json)).toList();
        AppLogger.log('Fetched ${rooms.length} rooms', tag: 'RoomDataSource');
        return rooms;
      }
      
      throw Exception('Failed to load rooms: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error fetching rooms', tag: 'RoomDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<RoomModel> getRoomById(String id) async {
    try {
      AppLogger.log('Fetching room: $id', tag: 'RoomDataSource');
      
      final response = await ApiClient.get('/rooms/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log('Room fetched successfully', tag: 'RoomDataSource');
        return RoomModel.fromJson(data);
      }
      
      throw Exception('Failed to load room: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error fetching room', tag: 'RoomDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<RoomModel> updateRoom(String id, Map<String, dynamic> data) async {
    try {
      AppLogger.log('Updating room: $id', tag: 'RoomDataSource');
      
      final response = await ApiClient.put('/rooms/$id', data);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        AppLogger.log('Room updated successfully', tag: 'RoomDataSource');
        return RoomModel.fromJson(responseData);
      }
      
      throw Exception('Failed to update room: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error updating room', tag: 'RoomDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteRoom(String id) async {
    try {
      AppLogger.log('Deleting room: $id', tag: 'RoomDataSource');

      final response = await ApiClient.delete('/rooms/$id');

      if (response.statusCode == 200) {
        AppLogger.log('Room deleted successfully', tag: 'RoomDataSource');
        return;
      }

      throw Exception('Failed to delete room: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error deleting room', tag: 'RoomDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<List<RoomParticipantModel>> getRoomParticipants(String roomId) async {
    try {
      AppLogger.log('Fetching participants for room: $roomId', tag: 'RoomDataSource');

      final response = await ApiClient.get('/rooms/$roomId/participants');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RoomParticipantModel.fromJson(json)).toList();
      }

      throw Exception('Failed to load participants: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error fetching participants', tag: 'RoomDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<RoomParticipantModel> addParticipant({
    required String roomId,
    required int userId,
    required ParticipantRole role,
  }) async {
    try {
      AppLogger.log('Adding participant to room: $roomId', tag: 'RoomDataSource');

      final response = await ApiClient.post('/rooms/$roomId/participants', {
        'user_id': userId,
        'role': role.toJson(),
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RoomParticipantModel.fromJson(data);
      }

      throw Exception('Failed to add participant: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error adding participant', tag: 'RoomDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> removeParticipant(int participantId) async {
    try {
      AppLogger.log('Removing participant: $participantId', tag: 'RoomDataSource');

      final response = await ApiClient.delete('/participants/$participantId');

      if (response.statusCode == 200) {
        AppLogger.log('Participant removed successfully', tag: 'RoomDataSource');
        return;
      }

      throw Exception('Failed to remove participant: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error removing participant', tag: 'RoomDataSource', error: e);
      rethrow;
    }
  }
}
