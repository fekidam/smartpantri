import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(String text) async {
    final user = _auth.currentUser;
    if (text.isNotEmpty && user != null) {
      _messageController.clear();

      await _firestore.collection('chats').doc('ai-chat').collection(user.uid).add({
        'sender': user.email,
        'content': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final aiResponse = await _getAIResponse(text);

      await _firestore.collection('chats').doc('ai-chat').collection(user.uid).add({
        'sender': 'AI',
        'content': aiResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _scrollToBottom();
    }
  }

  Future<String> _getAIResponse(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    try {
      // Automatikus nyelvérzékelés az üzenet alapján
      final isEnglish = RegExp(r'^[a-zA-Z0-9 .,!?]*\$').hasMatch(prompt);
      final systemMessage = isEnglish
          ? 'You are a helpful assistant that provides support regarding the application usage and recipe suggestions.'
          : 'Te egy segítőkész asszisztens vagy, aki kizárólag az applikáció használatával és receptajánlásokkal kapcsolatban válaszol.';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemMessage},
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse = data['choices'][0]['message']['content'];
        return aiResponse;
      } else {
        print('Error: ${response.statusCode}, ${response.body}');
        return 'An error occurred while fetching the AI response.';
      }
    } catch (e) {
      print('Exception: $e');
      return 'Failed to receive a response from the AI.';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Switch to Group Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc('ai-chat')
                  .collection(_auth.currentUser!.uid)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final sender = message['sender'] ?? 'Unknown';
                    final content = message['content'] ?? '';
                    final isMe = sender == _auth.currentUser?.email;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[100] : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft:
                            isMe ? const Radius.circular(12) : const Radius.circular(0),
                            bottomRight:
                            isMe ? const Radius.circular(0) : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sender,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.green[700] : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              content,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask something...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}