import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import 'dart:math';

class ConnectionService {
  final _database = FirebaseDatabase.instance.ref();
  static const String _deviceIdKey = 'local_device_id';
  static const String _connectionCodeKey = 'local_connection_code';

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = 'dev_${Random().nextInt(1000000)}';
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  Future<String> getConnectionCode() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString(_connectionCodeKey);
    
    if (code == null) {
      code = 'COUPLE-${Random().nextInt(9000) + 1000}';
      await prefs.setString(_connectionCodeKey, code);
    }
    
    // Always ensure it's registered in Firebase
    // Don't await the registration to prevent blocking the UI
    _registerCodeInFirebase(code).catchError((e) {
      print('Error registering code in background: $e');
    });
    
    return code;
  }

  Future<void> _registerCodeInFirebase(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await getDeviceId();
    final phoneNumber = prefs.getString('user_phone_number');
    final userName = prefs.getString('user_name') ?? 'Partner';

    await _database.child('codes/$code').set({
      'deviceId': deviceId,
      'name': userName,
      'phoneNumber': phoneNumber,
      'status': 'available',
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<Contact?> searchPartner(String code) async {
    final snapshot = await _database.child('codes/$code').get();
    final value = snapshot.value;
    if (snapshot.exists && value is Map) {
      final data = Map<String, dynamic>.from(value);
      return Contact(
        id: data['deviceId'] ?? '',
        name: data['name'] ?? 'Partner ($code)',
        phoneNumber: data['phoneNumber'],
        status: 'Online',
        isOnline: true,
        encryptionKey: 'enc_${Random().nextInt(1000000)}', // Generated for this connection
      );
    }
    return null;
  }

  Future<void> sendRequest(Contact partner, String myCode) async {
    final myId = await getDeviceId();
    await _database.child('requests/${partner.id}/$myId').set({
      'fromId': myId,
      'fromCode': myCode,
      'encryptionKey': partner.encryptionKey,
      'status': 'pending',
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<List<Map<String, dynamic>>> listenForRequests() async* {
    final myId = await getDeviceId();
    yield* _database.child('requests/$myId').onValue.map((event) {
      final requests = <Map<String, dynamic>>[];
      final value = event.snapshot.value;
      if (value is Map) {
        value.forEach((key, val) {
          if (val is Map) {
            requests.add(Map<String, dynamic>.from(val));
          }
        });
      }
      return requests;
    });
  }

  Stream<String?> listenForRequestStatus(String partnerId) async* {
    final myId = await getDeviceId();
    yield* _database.child('requests/$partnerId/$myId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return value['status'] as String?;
      }
      return null;
    });
  }

  Future<void> acceptRequest(Map<String, dynamic> request) async {
    final myId = await getDeviceId();
    final partnerId = request['fromId'] as String?;
    
    if (partnerId == null) return;
    
    // 1. Create the chat session
    final chatId = 'chat_${<String>[myId, partnerId].sorted().join("_")}';
    
    // 2. Notify partner by updating status
    await _database.child('requests/$myId/$partnerId').update({
      'status': 'accepted',
      'chatId': chatId,
    });
  }

  // --- Call Functionality ---

  Future<void> sendCallNotification({
    required String partnerId,
    required String chatId,
    required bool isVideo,
    required String callerName,
  }) async {
    final myId = await getDeviceId();
    await _database.child('calls/$partnerId').set({
      'callerId': myId,
      'callerName': callerName,
      'chatId': chatId,
      'isVideo': isVideo,
      'status': 'ringing',
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<Map<String, dynamic>?> listenForIncomingCalls() async* {
    final myId = await getDeviceId();
    yield* _database.child('calls/$myId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    });
  }

  Future<void> endCall(String partnerId) async {
    final myId = await getDeviceId();
    await _database.child('calls/$myId').remove();
    await _database.child('calls/$partnerId').remove();
  }

  Future<void> updateCallStatus(String partnerId, String status) async {
    await _database.child('calls/$partnerId').update({
      'status': status,
    });
  }

  Future<void> clearRequest(String partnerId) async {
    final myId = await getDeviceId();
    await _database.child('requests/$myId/$partnerId').remove();
    await _database.child('requests/$partnerId/$myId').remove();
  }
}

extension on List<String> {
  List<String> sorted() {
    final copy = List<String>.from(this);
    copy.sort();
    return copy;
  }
}
