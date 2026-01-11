import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../models/message.dart';

class StorageService {
  static const String _contactsKey = 'saved_partners';
  static const String _messagesKey = 'chat_history';

  Future<void> savePartner(Contact contact) async {
    final prefs = await SharedPreferences.getInstance();
    // For a couple app, we only save ONE partner to ensure privacy
    final List<Contact> singlePartnerList = [contact];
    
    final data = singlePartnerList.map((c) => c.toJson()).toList();
    await prefs.setString(_contactsKey, jsonEncode(data));
  }

  Future<List<Contact>> loadPartners() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_contactsKey);
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((c) => Contact.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contactsKey);
    await prefs.remove(_messagesKey);
  }

  Future<void> saveMessages(String chatId, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final data = messages.map((m) => m.toJson()).toList();
    await prefs.setString('${_messagesKey}_$chatId', jsonEncode(data));
  }

  Future<List<Message>> loadMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_messagesKey}_$chatId');
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((m) => Message.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }
}
