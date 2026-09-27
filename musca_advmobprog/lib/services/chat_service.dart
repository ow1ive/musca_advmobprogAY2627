import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();
    final MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    final List<String> ids = [currentUserId, receiverId];
    ids.sort();
    final String chatRoomID = ids.join('_');

    // Track participants + last message so the chat list can sort by recency,
    // and bump the receiver's unread count for that room.
    await _firestore.collection('chat_rooms').doc(chatRoomID).set({
      'participants': ids,
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'unreadCounts.$receiverId': FieldValue.increment(1),
      'unreadCounts.$currentUserId': 0,
    }, SetOptions(merge: true));

    // add new message to database
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // Resets the current user's unread count and records when they last read
  // this conversation, so the sender can show a "seen" checkmark.
  Future<void> markConversationRead(
    String currentUserId,
    String otherUserId,
  ) async {
    final List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    final String chatRoomID = ids.join('_');

    await _firestore.collection('chat_rooms').doc(chatRoomID).set({
      'unreadCounts.$currentUserId': 0,
      'lastRead.$currentUserId': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Watches the chat room doc itself (for lastRead / read-receipt lookups).
  Stream<DocumentSnapshot<Map<String, dynamic>>> getRoomStream(
    String userId,
    String otherUserId,
  ) {
    final List<String> ids = [userId, otherUserId];
    ids.sort();
    final String chatRoomID = ids.join('_');

    return _firestore.collection('chat_rooms').doc(chatRoomID).snapshots();
  }

  // get chat rooms the current user is part of (sorted client-side by
  // lastMessageTime to avoid requiring a composite Firestore index)
  Stream<QuerySnapshot> getRecentChatRoomsStream(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots();
  }

  // get message
  Stream<QuerySnapshot> getMessage(String userID, String otherUserID) {
    // construct chat room ID for the two users (sorted to ensure uniqueness)
    final List<String> ids = [userID, otherUserID];
    ids.sort();
    final String chatRoomID = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    // Ensure your Users doc actually stores the Firebase Auth UID in a field `uid`
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}
