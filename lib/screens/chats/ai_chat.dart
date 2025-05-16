import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart';

class AIChatScreen extends StatefulWidget {
  final bool fromGroupScreen;
  final Color groupColor;

  const AIChatScreen({
    super.key,
    required this.fromGroupScreen,
    required this.groupColor,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true, _isSending = false, _isInSharedGroup = false;
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _checkGroup().then((_) {
      setState(() => _isLoading = false);
    });
  }

  Future<void> _checkGroup() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final snap = await _firestore
        .collection('groups')
        .where('sharedWith', arrayContains: u.uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      _isInSharedGroup = true;
      _groupId = snap.docs.first.id;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    _messageController.clear();
    setState(() => _isSending = true);

    final uid = _auth.currentUser!.uid;
    final base = _firestore.collection('chats').doc('ai-chat').collection(uid);

    await base.add({
      'sender': _auth.currentUser!.email ?? 'Guest',
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final ai = await _getAIResponse(text);
    await base.add({
      'sender': 'AI',
      'content': ai,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _isSending = false);
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _getAIResponse(String prompt) async {
    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (key.isEmpty) return AppLocalizations.of(context)!.apiKeyMissing;

    final isEn = RegExp(r'^[a-zA-Z0-9\s.,!?]*$').hasMatch(prompt);
    final system = isEn
        ? '''
You are a helpful assistant for the SmartPantri app. You can only respond to questions related to recipes and the SmartPantry app itself. For any other topics, reply with: "I can only assist with questions related to recipes and the SmartPantri app."
'''
        : '''
Te egy segítőkész asszisztens vagy a SmartPantri alkalmazáshoz. Csak a receptekkel és a SmartPantry alkalmazással kapcsolatos kérdésekre válaszolhatsz. Minden egyéb témában ezt válaszold: "Csak a receptekkel és a SmartPantri alkalmazással kapcsolatos kérdésekre válaszolhatok."
''';

    final resp = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(utf8.decode(resp.bodyBytes));
      return data['choices'][0]['message']['content'] as String;
    } else {
      return AppLocalizations.of(context)!.aiResponseError(
          resp.statusCode.toString(), resp.body);
    }
  }

  Widget _buildMessage(Map<String, dynamic> data) {
    final theme = Provider.of<ThemeProvider>(context);
    final fontSizeScale = theme.fontSizeScale;
    final text = data['content'] as String? ?? '';
    final sender = data['sender'] as String? ?? '';
    final isMe = sender == _auth.currentUser!.email;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? (widget.fromGroupScreen ? widget.groupColor : theme.primaryColor) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14 * fontSizeScale,
            color: isMe
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildMessages() {
    final uid = _auth.currentUser!.uid;
    final effectiveColor = widget.fromGroupScreen ? widget.groupColor : Provider.of<ThemeProvider>(context).primaryColor;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc('ai-chat')
          .collection(uid)
          .orderBy('timestamp')
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return Center(child: CircularProgressIndicator(color: effectiveColor));
        final docs = snap.data!.docs;
        return ListView.builder(
          controller: _scrollController,
          itemCount: docs.length,
          itemBuilder: (_, i) {
            return _buildMessage(docs[i].data()! as Map<String, dynamic>);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('AIChatScreen - fromGroupScreen: ${widget.fromGroupScreen}, groupColor: ${widget.groupColor}');

    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;
    final effectiveColor = widget.fromGroupScreen ? widget.groupColor : theme.primaryColor;

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: effectiveColor)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.aiChat,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: effectiveColor,
        actions: [
          IconButton(
            icon: Icon(
              iconStyle == 'filled' ? Icons.chat : Icons.chat_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              if (_isInSharedGroup) {
                Navigator.pushReplacementNamed(context, '/groupDetail', arguments: _groupId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.needSharedGroupForFeature,
                      style: TextStyle(fontSize: 14 * fontSizeScale),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessages()),
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
                        controller: _messageController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: l10n.typeAMessage,
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: effectiveColor,
                    child: IconButton(
                      icon: Icon(
                        iconStyle == 'filled' ? Icons.send : Icons.send_outlined,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _isSending ? null : _sendMessage,
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