import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smartpantri/generated/l10n.dart';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final Color groupColor;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupColor,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;
  bool _sending = false;

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    await _fs
        .collection('chats')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'sender': _auth.currentUser?.email ?? 'Guest',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    setState(() => _sending = false);
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessage(Map<String, dynamic> d) {
    final theme = Provider.of<ThemeProvider>(context);
    final fontSizeScale = theme.fontSizeScale;
    final sender = d['sender'] as String? ?? '';
    final text = d['text'] as String? ?? '';
    final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final time = DateFormat('HH:mm').format(ts);
    final isMe = sender == _auth.currentUser?.email;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? widget.groupColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12 * fontSizeScale,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14 * fontSizeScale,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 10 * fontSizeScale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.groupColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.groupChat,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: widget.groupColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.groupColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _fs
                    .collection('chats')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return Center(child: CircularProgressIndicator(color: widget.groupColor));
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: docs.length,
                    itemBuilder: (_, i) => _buildMessage(docs[i].data()! as Map<String, dynamic>),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: InputDecoration(
                          hintText: l10n.typeAMessage,
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14 * fontSizeScale,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: widget.groupColor,
                    child: IconButton(
                      icon: Icon(
                        iconStyle == 'filled' ? Icons.send : Icons.send_outlined,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}