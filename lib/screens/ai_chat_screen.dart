import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage(String text) async {
    if (text.isNotEmpty) {
      // Felhasználói üzenet mentése
      await _firestore.collection('chats').doc('ai-chat').collection('messages').add({
        'sender': _auth.currentUser!.email,
        'content': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // AI válasz generálása
      final aiResponse = await _getAIResponse(text);

      // AI válasz mentése
      await _firestore.collection('chats').doc('ai-chat').collection('messages').add({
        'sender': 'AI',
        'content': aiResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> _getAIResponse(String prompt) async {
    // Itt illeszd be az OpenAI API hívást
    // Visszaad egy példaválaszt a teszteléshez
    await Future.delayed(const Duration(seconds: 2)); // Szimulált késleltetés
    return "Ez az AI válasza a \"$prompt\" kérdésre.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc('ai-chat')
                  .collection('messages')
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
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final sender = message['sender'];
                    final content = message['content'];

                    return ListTile(
                      title: Text(sender),
                      subtitle: Text(content),
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
                    ),
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
