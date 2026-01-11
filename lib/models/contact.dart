
class Contact {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? profilePic;
  final String status;
  final bool isOnline;
  final String? encryptionKey;

  Contact({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.profilePic,
    this.status = "Available",
    this.isOnline = false,
    this.encryptionKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'profilePic': profilePic,
        'status': status,
        'isOnline': isOnline,
        'encryptionKey': encryptionKey,
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'],
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        profilePic: json['profilePic'],
        status: json['status'],
        isOnline: json['isOnline'],
        encryptionKey: json['encryptionKey'],
      );
}
