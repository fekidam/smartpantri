import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupAndAIChatScreen extends StatefulWidget {
  final String groupId;
  final bool isGuest;
  final bool isShared;

  const GroupAndAIChatScreen({
    Key? key,
    required this.groupId,
    required this.isGuest,
    required this.isShared,
  }) : super(key: key);

  @override
  State<GroupAndAIChatScreen> createState() => _GroupAndAIChatScreenState();
}

class _GroupAndAIChatScreenState extends State<GroupAndAIChatScreen> {
  bool _isAIChat = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    if (_isAIChat) {
      await _sendToAI(text);
    } else {
      await _sendToGroup(text);
    }

    _scrollToBottom();
  }

  Future<void> _sendToGroup(String text) async {
    await _firestore
        .collection('chats')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'sender': _auth.currentUser?.email ?? 'Guest',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendToAI(String text) async {
    await _firestore
        .collection('chats')
        .doc('ai-chat')
        .collection(_auth.currentUser!.uid)
        .add({
      'sender': _auth.currentUser?.email ?? 'Guest',
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Ide lehet AI választ is kérni, de most az AI válasz implementáció maradjon a jelenlegi AIChatScreen kódodban.
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessages() {
    if (_isAIChat) {
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .doc('ai-chat')
            .collection(_auth.currentUser!.uid)
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          return ListView.builder(
            controller: _scrollController,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final sender = data['sender'] ?? '';
              final text = data['content'] ?? '';

              final isMe = sender == _auth.currentUser?.email;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.green[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(text),
                ),
              );
            },
          );
        },
      );
    } else {
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .doc(widget.groupId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          return ListView.builder(
            controller: _scrollController,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final sender = data['sender'] ?? '';
              final text = data['text'] ?? '';

              final isMe = sender == _auth.currentUser?.email;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.green[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(text),
                ),
              );
            },
          );
        },
      );
    }
  }

  void _toggleChat() {
    if (!widget.isShared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need a shared group to use this feature.')),
      );
      return;
    }

    setState(() {
      _isAIChat = !_isAIChat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isShared
            ? (_isAIChat ? 'AI Chat' : 'Group Chat')
            : 'AI Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Theme.of(context).primaryColor.withOpacity(0.9),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      _isAIChat ? 'AI Chat' : 'Group Chat',
                      style: textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleChat,
                  icon: const Icon(Icons.smart_toy),
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
