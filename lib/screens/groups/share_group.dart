import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n.dart';
import '../../Providers/theme_provider.dart';

class ShareGroupScreen extends StatefulWidget {
  final String groupId;

  const ShareGroupScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _ShareGroupScreenState createState() => _ShareGroupScreenState();
}

class _ShareGroupScreenState extends State<ShareGroupScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  String? _message;
  bool _loading = false;

  Color _darken(Color c, [double amt = .2]) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    final theme = Provider.of<ThemeProvider>(context);
    final color = _darken(theme.primaryColor);
    final fontSizeScale = theme.fontSizeScale;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
      child: Text(text, style: TextStyle(fontSize: 16 * fontSizeScale)),
    );
  }

  Future<void> _shareGroup() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _message = AppLocalizations.of(context)!.pleaseEnterEmailAddress);
      return;
    }

    setState(() => _loading = true);

    try {
      print('Searching for user with email: $email');
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snap.docs.isEmpty) {
        print('No user found for email: $email');
        setState(() => _message = AppLocalizations.of(context)!.userNotFound);
      } else {
        final userId = snap.docs.first.id;
        print('Found user with UID: $userId');

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'sharedWith': FieldValue.arrayUnion([userId])
        });

        print('Group shared with UID: $userId');
        setState(() {
          _message = AppLocalizations.of(context)!.groupSharedSuccessfully;
        });
        _emailCtrl.clear();
      }
    } catch (e) {
      print('Error sharing group: $e');
      setState(() => _message = '${AppLocalizations.of(context)!.errorSharingGroup} $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            iconStyle == 'filled' ? Icons.arrow_back : Icons.arrow_back_outlined,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  AppLocalizations.of(context)!.shareGroup,
                  style: TextStyle(
                    fontSize: 24 * fontSizeScale,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailCtrl,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.enterEmailToShareWith,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14 * fontSizeScale,
                    ),
                    hintText: 'email@example.com',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                      fontSize: 14 * fontSizeScale,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primaryColor),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  text: AppLocalizations.of(context)!.shareGroup,
                  onPressed: _loading ? null : _shareGroup,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: _message == AppLocalizations.of(context)!.groupSharedSuccessfully
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 14 * fontSizeScale,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}