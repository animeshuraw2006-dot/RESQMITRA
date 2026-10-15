import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firestore-backed SOS storage. Documents contain only the minimum information
/// needed for dispatch. Do not put secrets or private responder credentials here.
class SosRepository {
  SosRepository._();
  static final SosRepository instance = SosRepository._();

  bool get available => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _sos =>
      FirebaseFirestore.instance.collection('sosRequests');

  /// Creates a server-visible request. The authenticated UID should be supplied
  /// by Firebase Auth in production; requesterId is intentionally not trusted
  /// by security rules unless it matches request.auth.uid.
  Future<String?> createRequest({
    required String category,
    required String emergencyType,
    required String instructions,
    required bool doNotCall,
    required String bloodGroup,
    required bool audioRequested,
    required double? latitude,
    required double? longitude,
    required double? accuracyMeters,
    required String requesterId,
  }) async {
    if (!available) return null;
    final now = FieldValue.serverTimestamp();
    final doc = await _sos.add({
      'requesterId': requesterId,
      'category': category,
      'emergencyType': emergencyType,
      'urgency': _urgency(category, emergencyType),
      'instructions': instructions,
      'doNotCall': doNotCall,
      'bloodGroup': bloodGroup,
      // This is only a flag. Audio bytes are not recorded or uploaded by this starter.
      'audioRequested': audioRequested,
      'audioObjectPath': null,
      'location': latitude == null || longitude == null
          ? null
          : {
              'latitude': latitude,
              'longitude': longitude,
              'accuracyMeters': accuracyMeters,
              'capturedAt': Timestamp.now(),
            },
      'status': 'pending',
      'acceptedResponderIds': <String>[],
      'createdAt': now,
      'updatedAt': now,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
      'schemaVersion': 1,
    });
    return doc.id;
  }

  /// Only active requests are shown in responder queue. Production rules must
  /// restrict this query to verified responder accounts.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveRequests() {
    return _sos
        .where('status', whereIn: ['pending', 'accepted', 'en_route'])
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> updateStatus(String id, String status) async {
    if (!available) return;
    const allowed = {'accepted', 'en_route', 'arrived', 'cancelled', 'safe'};
    if (!allowed.contains(status)) throw ArgumentError('Invalid SOS status');
    await _sos.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _urgency(String category, String emergencyType) {
    if (emergencyType.toLowerCase().contains('danger') ||
        emergencyType.toLowerCase().contains('medical') ||
        emergencyType.toLowerCase().contains('blood') ||
        emergencyType.toLowerCase().contains('fire') ||
        emergencyType.toLowerCase().contains('accident')) {
      return 'critical';
    }
    return category == 'Child SOS' || category == 'Women SOS' ? 'high' : 'normal';
  }
}
