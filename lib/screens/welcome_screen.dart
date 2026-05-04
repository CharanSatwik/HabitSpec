import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_input.dart';
import '../widgets/primary_glow_button.dart';
import '../providers/auth_provider.dart';
import 'greeting_setup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.completeOnboarding(name);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GreetingSetupScreen(userName: name)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Clean background
          Container(
            decoration: BoxDecoration(color: theme.colorScheme.surface),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Anchor
                    Transform.rotate(
                      angle: 0.05,
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.spa,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                    GlassPanel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Let's begin\nyour journey.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "A quiet space for your habits. How should we address you?",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 40),
                          GlassInput(
                            hintText: "Your preferred name",
                            controller: _nameController,
                          ),
                          const SizedBox(height: 24),
                          PrimaryGlowButton(
                            text: "Let's go",
                            onPressed: _submitName,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Opacity(
                      opacity: 0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Your sanctuary is private",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
