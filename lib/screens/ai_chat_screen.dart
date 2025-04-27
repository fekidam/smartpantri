import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSending = false;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final text = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _isSending = true;
    });

    try {
      await _sendToAI(text);
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

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc('ai-chat')
          .collection(_auth.currentUser!.uid)
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
            final text = data['content'] ?? '';
            final sender = data['sender'] ?? '';
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
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Chat'),
            backgroundColor: themeProvider.primaryColor, // Use theme's primaryColor
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false, // No back arrow here
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
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}