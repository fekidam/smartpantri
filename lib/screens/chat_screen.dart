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

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && widget.groupId.isNotEmpty) {
      final messageContent = _messageController.text.trim();
      _messageController.clear();

      try {
        await _firestore
            .collection('chats')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'sender': _auth.currentUser?.email ?? 'Guest',
          'text': messageContent,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving message: $e');
      }
    }
  }

  void _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(widget.groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _editMessage(String messageId, String currentText) async {
    final TextEditingController editController =
    TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: 'Edit your message'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection('chats')
                      .doc(widget.groupId)
                      .collection('messages')
                      .doc(messageId)
                      .update({'text': editController.text});
                  Navigator.pop(context);
                } catch (e) {
                  print('Error editing message: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Chat'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              Navigator.pushNamed(context, '/ai-chat');
            },
            tooltip: 'Switch to AI Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
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
                    final sender = message['sender'] ?? 'Unknown';
                    final text = message['text'] ?? '';
                    final messageId = messages[index].id;

                    final isMe = sender == _auth.currentUser?.email;

                    return GestureDetector(
                      onLongPress: isMe
                          ? () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _editMessage(messageId, text);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: const Text('Delete'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteMessage(messageId);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                          : null,
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                            isMe ? Colors.green[100] : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isMe
                                  ? const Radius.circular(12)
                                  : const Radius.circular(0),
                              bottomRight: isMe
                                  ? const Radius.circular(0)
                                  : const Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sender,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isMe
                                      ? Colors.green[700]
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                text,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
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
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
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
