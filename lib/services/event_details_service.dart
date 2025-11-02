// lib/services/event_details_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:baby_tracker/models/sleep_details.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/models/diaper_details.dart';
import 'package:baby_tracker/models/medicine_details.dart';

/// Сервис для работы с деталями событий
class EventDetailsService {
  final FirebaseFirestore _firestore;

  EventDetailsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // Sleep Details
  // ============================================================================

  Future<SleepDetails?> getSleepDetails(String eventId) async {
    try {
      final doc =
          await _firestore.collection('sleep_details').doc(eventId).get();
      if (doc.exists) {
        return SleepDetails.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting sleep details: $e');
      return null;
    }
  }

  Future<String?> createSleepDetails(SleepDetails details) async {
    try {
      await _firestore
          .collection('sleep_details')
          .doc(details.eventId)
          .set(details.toFirestore());
      return details.eventId;
    } catch (e) {
      debugPrint('Error creating sleep details: $e');
      return null;
    }
  }

  Future<bool> updateSleepDetails(String eventId, SleepDetails details) async {
    try {
      await _firestore.collection('sleep_details').doc(eventId).set({
        ...details.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error updating sleep details: $e');
      return false;
    }
  }

  Future<bool> deleteSleepDetails(String eventId) async {
    try {
      await _firestore.collection('sleep_details').doc(eventId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting sleep details: $e');
      return false;
    }
  }

  // ============================================================================
  // Feeding Details
  // ============================================================================

  Future<FeedingDetails?> getFeedingDetails(String eventId) async {
    try {
      final doc =
          await _firestore.collection('feeding_details').doc(eventId).get();
      if (doc.exists) {
        return FeedingDetails.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting feeding details: $e');
      return null;
    }
  }

  Stream<FeedingDetails?> getFeedingDetailsStream(String eventId) {
    return _firestore
        .collection('feeding_details')
        .doc(eventId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return FeedingDetails.fromFirestore(doc);
      }
      return null;
    }).handleError((error) {
      debugPrint('Error in getFeedingDetailsStream: $error');
      return null;
    });
  }

  Future<String?> createFeedingDetails(FeedingDetails details) async {
    try {
      await _firestore
          .collection('feeding_details')
          .doc(details.eventId)
          .set(details.toFirestore());
      return details.eventId;
    } catch (e) {
      debugPrint('Error creating feeding details: $e');
      return null;
    }
  }

  Future<bool> updateFeedingDetails(
      String eventId, FeedingDetails details) async {
    try {
      await _firestore.collection('feeding_details').doc(eventId).set({
        ...details.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error updating feeding details: $e');
      return false;
    }
  }

  Future<bool> deleteFeedingDetails(String eventId) async {
    try {
      await _firestore.collection('feeding_details').doc(eventId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting feeding details: $e');
      return false;
    }
  }

  // ============================================================================
  // Diaper Details
  // ============================================================================

  Future<DiaperDetails?> getDiaperDetails(String eventId) async {
    try {
      final doc =
          await _firestore.collection('diaper_details').doc(eventId).get();
      if (doc.exists) {
        return DiaperDetails.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting diaper details: $e');
      return null;
    }
  }

  Future<String?> createDiaperDetails(DiaperDetails details) async {
    try {
      await _firestore
          .collection('diaper_details')
          .doc(details.eventId)
          .set(details.toFirestore());
      return details.eventId;
    } catch (e) {
      debugPrint('Error creating diaper details: $e');
      return null;
    }
  }

  Future<bool> updateDiaperDetails(
      String eventId, DiaperDetails details) async {
    try {
      await _firestore.collection('diaper_details').doc(eventId).update({
        ...details.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating diaper details: $e');
      return false;
    }
  }

  Future<bool> deleteDiaperDetails(String eventId) async {
    try {
      await _firestore.collection('diaper_details').doc(eventId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting diaper details: $e');
      return false;
    }
  }

  // ============================================================================
  // Medicine Details
  // ============================================================================

  Future<MedicineDetails?> getMedicineDetails(String eventId) async {
    try {
      final doc =
          await _firestore.collection('medicine_details').doc(eventId).get();
      if (doc.exists) {
        return MedicineDetails.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting medicine details: $e');
      return null;
    }
  }

  Future<String?> createMedicineDetails(MedicineDetails details) async {
    try {
      await _firestore
          .collection('medicine_details')
          .doc(details.eventId)
          .set(details.toFirestore());
      return details.eventId;
    } catch (e) {
      debugPrint('Error creating medicine details: $e');
      return null;
    }
  }

  Future<bool> updateMedicineDetails(
      String eventId, MedicineDetails details) async {
    try {
      await _firestore.collection('medicine_details').doc(eventId).set({
        ...details.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error updating medicine details: $e');
      return false;
    }
  }

  Future<bool> deleteMedicineDetails(String eventId) async {
    try {
      await _firestore.collection('medicine_details').doc(eventId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting medicine details: $e');
      return false;
    }
  }
}
