enum CallType { voice, video }
enum CallStatus { missed, received, outgoing }

class CallRecord {
  final String id;
  final String partnerId;
  final String partnerName;
  final CallType type;
  final CallStatus status;
  final DateTime timestamp;
  final Duration? duration;

  CallRecord({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.type,
    required this.status,
    required this.timestamp,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'type': type.index,
      'status': status.index,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration?.inSeconds,
    };
  }

  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id'],
      partnerId: map['partnerId'],
      partnerName: map['partnerName'],
      type: CallType.values[map['type']],
      status: CallStatus.values[map['status']],
      timestamp: DateTime.parse(map['timestamp']),
      duration: map['duration'] != null ? Duration(seconds: map['duration']) : null,
    );
  }
}
