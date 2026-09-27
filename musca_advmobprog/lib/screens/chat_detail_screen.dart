import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;
  String? _pendingText;

  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
    _currentUserIdFuture.then((currentUserId) {
      final otherUserId = (widget.tappedUser['uid'] ?? '').toString();
      if (currentUserId.isNotEmpty && otherUserId.isNotEmpty) {
        _chatService
            .markConversationRead(currentUserId, otherUserId)
            .catchError(
              (e) => debugPrint('markConversationRead (initState) failed: $e'),
            );
      }
    });
  }

  Future<String> _getCurrentUserId() async {
    final userData = await _userService.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
      _pendingText = text;
    });
    _msgCtrl.clear();

    try {
      await _chatService.sendMessage(receiverId, text);
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
          _pendingText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserFirstName = (widget.tappedUser['firstName'] ?? '')
        .toString();
    final tappedUserUsername = (widget.tappedUser['username'] ?? '')
        .toString();
    final tappedUserEmail = (widget.tappedUser['email'] ?? '').toString();
    // Falls back to username (what Profile lets you edit) when no firstName.
    final tappedUserName = tappedUserFirstName.isNotEmpty
        ? tappedUserFirstName
        : tappedUserUsername;
    final otherInitial = tappedUserName.isNotEmpty
        ? tappedUserName[0].toUpperCase()
        : (tappedUserEmail.isNotEmpty ? tappedUserEmail[0].toUpperCase() : '?');

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: CustomText(text: tappedUserName, fontSize: 20.sp),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                        ),
                      );
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    // Find the other person's most recent reply: any of my
                    // messages sent before that timestamp must have been seen.
                    Timestamp? latestIncomingTime;
                    QueryDocumentSnapshot? latestIncoming;
                    for (final d in docs) {
                      final data = d.data() as Map<String, dynamic>;
                      if ((data['senderId'] ?? '').toString() !=
                          currentUserId) {
                        latestIncoming = d;
                        final ts = data['timestamp'];
                        if (ts is Timestamp) latestIncomingTime = ts;
                        break;
                      }
                    }
                    if (latestIncoming != null) {
                      _chatService
                          .markConversationRead(currentUserId, tappedUserId)
                          .catchError((_) {});
                    }

                    // Hide my just-sent messages until the delay completes
                    // (the pending bubble below stands in for it).
                    if (_isSending && _sendingStartedAt != null) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final senderId = (data['senderId'] ?? '').toString();
                        final ts = data['timestamp'];
                        if (senderId != currentUserId) return true;
                        if (ts is Timestamp) {
                          return ts.compareTo(_sendingStartedAt!) < 0;
                        }
                        return true;
                      }).toList();
                    }

                    final showPending = _isSending && _pendingText != null;

                    if (docs.isEmpty && !showPending) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: docs.length + (showPending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (showPending && index == 0) {
                          return _AnimatedMessageIn(
                            child: _buildBubble(
                              context,
                              text: _pendingText!,
                              isMe: true,
                              otherInitial: otherInitial,
                              statusWidget: _buildStatus(sending: true),
                            ),
                          );
                        }

                        final dataIndex = showPending ? index - 1 : index;
                        final data =
                            docs[dataIndex].data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final ts = data['timestamp'];

                        Widget? statusWidget;
                        if (isMe) {
                          // Seen once the other person has replied to it.
                          final seen =
                              latestIncomingTime != null &&
                              ts is Timestamp &&
                              ts.compareTo(latestIncomingTime) <= 0;
                          statusWidget = _buildStatus(
                            sending: false,
                            seen: seen,
                          );
                        }

                        return _AnimatedMessageIn(
                          child: _buildBubble(
                            context,
                            text: msgText,
                            isMe: isMe,
                            otherInitial: otherInitial,
                            statusWidget: statusWidget,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Composer
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => !_isSending
                              ? _send(currentUserId, tappedUserId)
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Type a message…',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    _send(currentUserId, tappedUserId),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Builds one chat bubble, with an avatar for the other person and an
  // optional status row (sending/sent/seen) under my own messages.
  Widget _buildBubble(
    BuildContext context, {
    required String text,
    required bool isMe,
    required String otherInitial,
    Widget? statusWidget,
  }) {
    final bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          DefaultTextStyle.merge(
            style: TextStyle(color: isMe ? Colors.white : null),
            child: CustomText(
              text: text.isNotEmpty ? text : '[empty]',
              fontSize: 15.sp,
              fontWeight: FontWeight.normal,
              textAlign: TextAlign.left,
            ),
          ),
          if (statusWidget != null) ...[
            SizedBox(height: 4.h),
            statusWidget,
          ],
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              child: Text(otherInitial, style: const TextStyle(fontSize: 12)),
            ),
            SizedBox(width: 6.w),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }

  // Sending shows a spinner + label; sent/seen show single/double checkmarks.
  Widget _buildStatus({required bool sending, bool seen = false}) {
    if (sending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white70,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            'Sending...',
            style: TextStyle(fontSize: 10.sp, color: Colors.white70),
          ),
        ],
      );
    }
    return Icon(
      seen ? Icons.done_all : Icons.done,
      size: 14,
      color: seen ? Colors.lightBlueAccent : Colors.white70,
    );
  }
}

// Fades and slides each bubble in as it's built, for a subtle message
// transition animation.
class _AnimatedMessageIn extends StatefulWidget {
  const _AnimatedMessageIn({required this.child});

  final Widget child;

  @override
  State<_AnimatedMessageIn> createState() => _AnimatedMessageInState();
}

class _AnimatedMessageInState extends State<_AnimatedMessageIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

