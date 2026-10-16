import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client wrapper for the authenticated Supabase emergency workflow.
/// SOS creation, cancellation and acceptance are performed by Edge Functions;
/// the Flutter client never receives a service-role key.
class SosRepository {
  SosRepository._();
  static final SosRepository instance = SosRepository._();

  bool get configured => const String.fromEnvironment('SUPABASE_URL').isNotEmpty &&
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isNotEmpty;
  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> createRequest({
    required String category,
    required String emergencyType,
    required String instructions,
    required bool doNotCall,
    required String bloodGroup,
    required bool audioRequested,
    required double? latitude,
    required double? longitude,
    required double? accuracyMeters,
    bool highAlert = false,
  }) async {
    if (_client.auth.currentSession == null) throw const AuthException('Please sign in to send an SOS.');
    final response = await _client.functions.invoke('dispatch-sos', body: {
      'client_request_id': '${DateTime.now().microsecondsSinceEpoch}-${_client.auth.currentUser!.id}',
      'category': _normalizeCategory(category),
      'emergency_type': emergencyType,
      'priority': highAlert ? 'high_alert' : 'normal',
      'instructions': instructions.trim(),
      'do_not_call': doNotCall,
      'blood_group': bloodGroup,
      'audio_requested': audioRequested,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
    });
    if (response.status < 200 || response.status >= 300) {
      throw Exception('SOS dispatch failed (${response.status}).');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['id'] == null) throw Exception('Server did not confirm an emergency ID.');
    return data;
  }

  Future<String?> getAcceptedEmergencyAudioUrl(String emergencyId) async {
    final rows = await _client.from('emergency_audio_recordings')
        .select('storage_path')
        .eq('emergency_id', emergencyId)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final path = rows.first['storage_path'] as String;
    return _client.storage.from('emergency-audio').createSignedUrl(path, 300);
  }

  Future<void> uploadEmergencyAudio(String emergencyId, Uint8List bytes) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in to upload emergency audio.');
    final storagePath = '$emergencyId/${user.id}/${DateTime.now().millisecondsSinceEpoch}.aac';
    await _client.storage.from('emergency-audio').uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(contentType: 'audio/aac', upsert: false),
    );
    await _client.from('emergency_audio_recordings').insert({
      'emergency_id': emergencyId,
      'requester_id': user.id,
      'storage_path': storagePath,
      'mime_type': 'audio/aac',
    });
  }

  Future<void> cancelRequest(String id) async {
    final response = await _client.functions.invoke('cancel-sos', body: {'emergency_id': id});
    if (response.status < 200 || response.status >= 300) throw Exception('Cancellation failed.');
  }

  Future<void> acceptRequest(String id) async {
    final response = await _client.functions.invoke('accept-sos', body: {'emergency_id': id});
    if (response.status < 200 || response.status >= 300) throw Exception('Acceptance failed.');
  }

  /// RLS must restrict rows to the signed-in verified responder's assignments.
  /// Do not broaden this to an unrestricted subscription of all emergencies.
  Stream<List<Map<String, dynamic>>> watchActiveRequests() {
    final user = _client.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _client.from('responder_assignments').stream(primaryKey: ['id'])
      .eq('responder_id', user.id)
      .map((rows) => rows.where((row) => row['status'] != 'declined' && row['status'] != 'resolved').map((row) => Map<String, dynamic>.from(row)).toList());
  }

  String _normalizeCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('women')) return 'women';
    if (value.contains('child')) return 'child';
    return 'general';
  }
}
