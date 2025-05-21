import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartpantri/generated/l10n.dart';

class GroupAndAIChatScreen extends StatefulWidget {
  final String groupId;
  final bool isGuest, isShared;
  final Color groupColor;

  const GroupAndAIChatScreen({
    super.key,
    required this.groupId,
    required this.isGuest,
    required this.isShared,
    required this.groupColor,
  });

  @override
  State<GroupAndAIChatScreen> createState() => _GroupAndAIChatScreenState();
}

class _GroupAndAIChatScreenState extends State<GroupAndAIChatScreen> {
  bool _aiMode = false;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Ha nincs megosztott csoport, automatikusan AI módra váltunk
    if (!widget.isShared) _aiMode = true;
  }

  // Üzenetküldés (AI vagy csoport szerint)
  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);

    if (_aiMode) {
      await _sendToAI(text);
    } else {
      await _sendToGroup(text);
    }

    setState(() => _sending = false);
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // Üzenet mentése a csoportos chatbe
  Future<void> _sendToGroup(String text) async {
    await _fs
        .collection('chats')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'sender': _auth.currentUser?.email ?? 'Guest',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Üzenet küldése az OpenAI API-nak
  Future<void> _sendToAI(String prompt) async {
    final uid = _auth.currentUser!.uid;
    final base = _fs.collection('chats').doc('ai-chat').collection(uid);

    await base.add({
      'sender': _auth.currentUser?.email ?? 'Guest',
      'content': prompt,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (key.isEmpty) return;

    final localeCode = Localizations.localeOf(context).languageCode;
    final isHu = localeCode == 'hu';

    final system = isHu
        ? '''
Te egy segítőkész asszisztens vagy a SmartPantri alkalmazáshoz. Kérhetsz tőlem recepteket (pl. "Adj egy receptet kenyérhez" vagy "Hogyan süssek sütit"), és válaszolok lépésről lépésre magyarul. Csak a receptekkel és a SmartPantri alkalmazással kapcsolatos kérdésekre válaszolhatsz. Minden egyéb témában ezt válaszold: "Csak a receptekkel és a SmartPantri alkalmazással kapcsolatos kérdésekre válaszolhatok."
'''
        : '''
You are a helpful assistant for the SmartPantri app. You can provide recipes (e.g., "Give me a recipe for bread" or "How do I bake a cake") and respond step-by-step in English. You can only respond to questions related to recipes and the SmartPantri app itself. For any other topics, reply with: "I can only assist with questions related to recipes and the SmartPantri app."
''';

    final resp = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key'
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );

    final ai = resp.statusCode == 200
        ? jsonDecode(utf8.decode(resp.bodyBytes))['choices'][0]['message']['content'] as String
        : AppLocalizations.of(context)!.aiResponseError(
      resp.statusCode.toString(),
      resp.body,
    );

    await base.add({
      'sender': 'AI',
      'content': ai,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Egyetlen üzenet megjelenítése
  Widget _buildMsg(Map<String, dynamic> d) {
    final isAI = _aiMode;
    final sender = d['sender'] as String? ?? '';
    final text = d[isAI ? 'content' : 'text'] as String? ?? '';
    final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final time = DateFormat('HH:mm').format(ts);
    final isMe = sender == _auth.currentUser?.email;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor.withOpacity(0.7)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!_aiMode)
              Text(sender,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontSize: 12)),
            Text(text,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface)),
            if (!_aiMode)
              Text(time,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontSize: 10)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final effectiveColor =
    theme.useGlobalTheme ? theme.primaryColor : widget.groupColor;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;

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
            _aiMode ? l10n.aiChat : l10n.groupChat,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: effectiveColor,
        actions: [
          if (widget.isShared)
            IconButton(
              icon: Icon(
                _aiMode
                    ? (iconStyle == 'filled'
                    ? Icons.smart_toy
                    : Icons.smart_toy_outlined)
                    : (iconStyle == 'filled'
                    ? Icons.chat
                    : Icons.chat_outlined),
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () => setState(() => _aiMode = !_aiMode),
              tooltip: l10n.switchChat,
            )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _aiMode
                    ? _fs
                    .collection('chats')
                    .doc('ai-chat')
                    .collection(_auth.currentUser!.uid)
                    .orderBy('timestamp')
                    .snapshots()
                    : _fs
                    .collection('chats')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData)
                    return Center(
                        child: CircularProgressIndicator(color: effectiveColor));
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: docs.length,
                    itemBuilder: (_, i) =>
                        _buildMsg(docs[i].data()! as Map<String, dynamic>),
                  );
                },
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                            fontSize: 16 * fontSizeScale,
                          ),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16 * fontSizeScale,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: effectiveColor,
                    child: IconButton(
                      icon: Icon(
                        iconStyle == 'filled'
                            ? Icons.send
                            : Icons.send_outlined,
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
