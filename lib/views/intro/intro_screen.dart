import '../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PROXVEL INTRO', style: TextStyle(fontSize: 24)),
            ElevatedButton(
              onPressed: () => context.go('/welcome'),
              child: Text(context.l10n.continueAction),
            ),
          ],
        ),
      ),
    );
  }
}
