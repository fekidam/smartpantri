import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Időbélyeg formázáshoz

class GroupAndAIChatScreen extends StatefulWidget {
  final String groupId;
  final bool isGuest;
  final bool isShared;
  final Color groupColor; // Csoport színe

  const GroupAndAIChatScreen({
    Key? key,
    required this.groupId,
    required this.isGuest,
    required this.isShared,
    required this.groupColor,
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
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isShared) {
      _isAIChat = true; // Alapértelmezett AI csevegés nem megosztott csoportokban
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final text = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _isSending = true;
    });

    try {
      if (_isAIChat) {
        await _sendToAI(text);
      } else {
        await _sendToGroup(text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
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
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _toggleChat() {
    if (!widget.isShared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature is only available in shared groups.')),
      );
      return;
    }
    setState(() {
      _isAIChat = !_isAIChat;
    });
  }

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: _isAIChat
          ? _firestore
          .collection('chats')
          .doc('ai-chat')
          .collection(_auth.currentUser!.uid)
          .orderBy('timestamp')
          .snapshots()
          : _firestore
          .collection('chats')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        return ListView.builder(
          controller: _scrollController,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final text = _isAIChat ? data['content'] ?? '' : data['text'] ?? '';
            final sender = data['sender'] ?? '';
            final timestamp = data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now(); // Visszaesés az aktuális időre, ha az időbélyeg null
            final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
            final isMe = sender == _auth.currentUser?.email;

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.green[700] : Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!_isAIChat) // Küldő és időbélyeg csak csoportos csevegésben
                      Text(
                        sender,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      text,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (!_isAIChat) // Időbélyeg csak csoportos csevegésben
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAIChat ? 'AI Chat' : 'Group Chat'),
        backgroundColor: widget.groupColor, // Csoport színe az AppBar-hoz
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Nincs vissza nyíl
        actions: [
          if (widget.isShared) // Toggle ikon csak megosztott csoportoknál
            IconButton(
              icon: Icon(
                _isAIChat ? Icons.message : Icons.smart_toy,
                color: Colors.white,
              ),
              onPressed: _toggleChat,
              tooltip: 'Switch Chat',
            ),
        ],
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
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _isSending ? Colors.grey : Colors.greenAccent,
                  ),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}