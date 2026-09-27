import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';
import 'home_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  String? _currentUserEmail;
  String? _currentUserUid;
  String? _currentUserImage;
  String? _currentUserName;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userData = await _userService.getUserData();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userData['email'];
      _currentUserUid = userData['uid'];
      _currentUserImage = userData['image'];
      final firstName = (userData['firstName'] ?? '').toString();
      final username = (userData['username'] ?? '').toString();
      _currentUserName = firstName.isNotEmpty ? firstName : username;
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  // Prefers firstName, then falls back to username (what Profile lets you
  // edit) so a username change actually shows up in the chat list.
  String _displayName(Map<String, dynamic> user) {
    final firstName = (user['firstName'] ?? '').toString();
    if (firstName.isNotEmpty) return firstName;
    final username = (user['username'] ?? '').toString();
    if (username.isNotEmpty) return username;
    return '';
  }

  // Falls back to the email's initial when there's no name yet.
  String _avatarInitial(Map<String, dynamic> user) {
    final name = _displayName(user);
    if (name.isNotEmpty) return name[0].toUpperCase();
    final email = (user['email'] ?? '').toString();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  // Shows the user's real profile photo when they have one, otherwise an initial.
  Widget _userAvatar(Map<String, dynamic> user) {
    final image = (user['image'] ?? '').toString();
    if (image.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(image));
    }
    return CircleAvatar(
      child: CustomText(
        text: _avatarInitial(user),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 64.h,
          child: Row(
            children: [
              Expanded(
                child: _NavAction(
                  icon: Icons.work_outline,
                  onTap: () => _goHome(0),
                ),
              ),
              Expanded(
                child: _NavAction(
                  icon: Icons.shopping_cart_checkout,
                  onTap: () => _goHome(1),
                ),
              ),
              Expanded(
                child: _NavAction(
                  icon: Icons.person,
                  imageUrl: _currentUserImage,
                  fallbackInitial: _currentUserName,
                  onTap: () => _goHome(2),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 23.w),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search chat...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_searchChatController.text.isNotEmpty)
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Users Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error loading users',
                      fontSize: 16.sp,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: CustomText(text: 'No users found', fontSize: 16.sp),
                  );
                }

                // Hide the signed-in user from the directory.
                final allUsers = snapshot.data!.where((u) {
                  final uid = (u['uid'] ?? '').toString();
                  return _currentUserUid == null || uid != _currentUserUid;
                }).toList();

                // Sort by recency + track unread counts per conversation.
                return StreamBuilder<QuerySnapshot>(
                  stream: _currentUserUid != null && _currentUserUid!.isNotEmpty
                      ? _chatService.getRecentChatRoomsStream(_currentUserUid!)
                      : const Stream.empty(),
                  builder: (context, roomsSnapshot) {
                    final lastMessageTimes = <String, Timestamp>{};
                    final lastMessages = <String, String>{};
                    final unreadCounts = <String, int>{};
                    if (roomsSnapshot.hasData) {
                      for (final doc in roomsSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final participants = List<String>.from(
                          data['participants'] ?? [],
                        );
                        final otherId = participants.firstWhere(
                          (id) => id != _currentUserUid,
                          orElse: () => '',
                        );
                        if (otherId.isEmpty) continue;

                        final ts = data['lastMessageTime'];
                        if (ts is Timestamp) {
                          lastMessageTimes[otherId] = ts;
                        }

                        final lastMessage = data['lastMessage'];
                        if (lastMessage is String && lastMessage.isNotEmpty) {
                          lastMessages[otherId] = lastMessage;
                        }

                        final unreadMap = Map<String, dynamic>.from(
                          data['unreadCounts'] ?? {},
                        );
                        final myUnread = unreadMap[_currentUserUid];
                        if (myUnread is int && myUnread > 0) {
                          unreadCounts[otherId] = myUnread;
                        }
                      }
                    }

                    // Full directory, search-filtered, most recent conversations first.
                    final directoryUsers =
                        allUsers.where((u) {
                            if (_searchText.isEmpty) return true;
                            final name = _displayName(u).toLowerCase();
                            final email = (u['email'] ?? '')
                                .toString()
                                .toLowerCase();
                            return name.contains(_searchText) ||
                                email.contains(_searchText);
                          }).toList()
                          ..sort((a, b) {
                            final aTime =
                                lastMessageTimes[(a['uid'] ?? '').toString()];
                            final bTime =
                                lastMessageTimes[(b['uid'] ?? '').toString()];
                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return bTime.compareTo(aTime);
                          });

                    return ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        if (directoryUsers.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: Center(
                              child: CustomText(
                                text: 'No messages found...',
                                fontSize: 16.sp,
                              ),
                            ),
                          )
                        else
                          ...directoryUsers.map((user) {
                            final uid = (user['uid'] ?? '').toString();
                            final unread = unreadCounts[uid] ?? 0;
                            return GestureDetector(
                              onTap: () => _openChat(user),
                              child: Card(
                                color: unread > 0
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withValues(alpha: 0.08)
                                    : null,
                                child: ListTile(
                                  leading: _userAvatar(user),
                                  title: CustomText(
                                    text: _displayName(user).isNotEmpty
                                        ? _displayName(user)
                                        : 'Unknown',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  subtitle: CustomText(
                                    text:
                                        lastMessages[uid] ??
                                        (user['email'] ?? 'No email'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 12,
                                    fontWeight: unread > 0
                                        ? FontWeight.bold
                                        : FontWeight.w300,
                                  ),
                                  trailing: unread > 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$unread',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          currentUserEmail: _currentUserEmail ?? '',
          tappedUser: user,
        ),
      ),
    );
  }

  void _goHome(int tabIndex) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(initialIndex: tabIndex),
      ),
      (route) => false,
    );
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.icon,
    required this.onTap,
    this.imageUrl,
    this.fallbackInitial,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? fallbackInitial;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = CircleAvatar(radius: 12.sp, backgroundImage: NetworkImage(imageUrl!));
    } else if (fallbackInitial != null && fallbackInitial!.isNotEmpty) {
      child = CircleAvatar(
        radius: 12.sp,
        child: Text(
          fallbackInitial![0].toUpperCase(),
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      child = Icon(icon, size: 24.sp);
    }

    return InkWell(onTap: onTap, child: Center(child: child));
  }
}

