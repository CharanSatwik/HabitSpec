import 'package:flutter/material.dart';
import '../widgets/primary_glow_button.dart';
import 'active_habits_screen.dart';

class GreetingSetupScreen extends StatelessWidget {
  final String userName;

  const GreetingSetupScreen({super.key, required this.userName});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning";
    } else if (hour < 17) {
      return "Good afternoon";
    } else {
      return "Good evening";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();

    return Scaffold(
      body: Stack(
        children: [
          // Clean background
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar Area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surfaceContainerHigh,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        "HabitSpec",
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 20,
                          color: theme.colorScheme.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Organic Visual Element
                          Container(
                            width: 200,
                            height: 200,
                            margin: const EdgeInsets.only(bottom: 40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            // Optional: Place a subtle illustration or icon inside
                            child: Icon(
                              Icons.wb_sunny_rounded,
                              size: 80,
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),

                          Text(
                            "$greeting, $userName!",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "What mindful habits shall we cultivate today?",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 48),

                          PrimaryGlowButton(
                            text: "Add First Habit",
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const ActiveHabitsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

