import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAIChat = false;

  /// Üzenet küldése
  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && widget.groupId.isNotEmpty) {
      final messageContent = _messageController.text.trim();
      _messageController.clear();

      try {
        if (_isAIChat) {
          // AI chat üzenet mentése
          await _firestore.collection('/chats/ai-chat/messages').add({
            'sender': _auth.currentUser?.email ?? 'Guest',
            'text': messageContent,
            'timestamp': FieldValue.serverTimestamp(),
          });

          // Mock AI válasz
          await Future.delayed(const Duration(seconds: 1));
          await _firestore.collection('/chats/ai-chat/messages').add({
            'sender': 'AI',
            'text': 'Ez egy AI válasz erre: "$messageContent"',
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          // Csoportos chat üzenet mentése
          await _firestore.collection('/chats/${widget.groupId}/messages').add({
            'sender': _auth.currentUser?.email ?? 'Guest',
            'text': messageContent,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print('Error saving message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chat stream kiválasztása
    final chatStream = _isAIChat
        ? _firestore
        .collection('/chats/ai-chat/messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        : _firestore
        .collection('/chats/${widget.groupId}/messages')
        .orderBy('timestamp', descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAIChat ? 'AI Chat' : 'Group Chat'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isAIChat ? Icons.group : Icons.smart_toy),
            onPressed: () {
              setState(() {
                _isAIChat = !_isAIChat; // Átváltás AI/csoportos chat között
              });
            },
            tooltip: _isAIChat ? 'Switch to Group Chat' : 'Switch to AI Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Üzenetlista
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages.'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                    messages[index].data() as Map<String, dynamic>;
                    final sender = message['sender'] as String;
                    final text = message['text'] as String;

                    return ListTile(
                      title: Text(
                        sender,
                        style: TextStyle(
                          fontWeight: sender == 'AI'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: sender == 'AI' ? Colors.blue : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        text,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Üzenetküldő mező
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isAIChat
                          ? 'Ask the AI...'
                          : 'Enter your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
