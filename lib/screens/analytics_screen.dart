import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_panel.dart';
import '../providers/habit_provider.dart';
import '../providers/auth_provider.dart';
import 'dart:math' as math;

class MinimalBounceScrollPhysics extends BouncingScrollPhysics {
  const MinimalBounceScrollPhysics({super.parent});

  @override
  MinimalBounceScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MinimalBounceScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) {
    return 0.15 * math.pow(1 - overscrollFraction, 2);
  }
}

class AnalyticsScreen extends StatefulWidget {
  final bool isEmbedded;
  const AnalyticsScreen({super.key, this.isEmbedded = false});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  void _showProfileMenu(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName ?? "User",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            auth.userEmail ?? "No email provided",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  "Logout",
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            auth.logout();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "Logout",
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      extendBody: true,
      body: CustomScrollView(
        physics: const MinimalBounceScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 72,
            leading: Consumer<AuthProvider>(
              builder: (context, auth, _) => GestureDetector(
                onTap: () => _showProfileMenu(context),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              "HabitSpec",
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            actions: [],
          ),
          Consumer<HabitProvider>(
            builder: (context, provider, child) {
              if (!provider.isInitialized) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final habits = provider.habits;
              final currentGlobalStreak = provider.currentGlobalStreak;
              final consistencyData = provider.getConsistencyData(
                21,
              ); // 3 weeks

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      "Analytics & Streaks",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GlassPanel(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "CONSISTENCY (Last 21 Days)",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  fontSize: 15,
                                ),
                              ),
                              Icon(
                                Icons.calendar_month,
                                color: theme.colorScheme.tertiary,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: 21,
                            itemBuilder: (context, index) {
                              final isDone = consistencyData[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? theme.colorScheme.secondary
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: GlassPanel(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "CURRENT STREAK",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "$currentGlobalStreak",
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "days",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GlassPanel(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "BEST STREAK",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "${provider.bestGlobalStreak}",
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.secondary,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "days",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Text(
                      "Daily Progress",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (habits.isEmpty)
                      Center(
                        child: Text(
                          "No habits to track yet.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    ...habits.map((habit) {
                      final isCompleted = habit.isCompletedOn(now);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildProgressItem(
                          theme,
                          title: habit.title,
                          subtitle: isCompleted ? "Completed" : "Pending",
                          icon: IconData(
                            habit.iconCodePoint,
                            fontFamily: habit.iconFontFamily ?? 'MaterialIcons',
                          ),
                          progress: isCompleted ? 1.0 : 0.0,
                          isCompleted: isCompleted,
                        ),
                      );
                    }),

                    const SizedBox(height: 100), // padding for bottom nav
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required double progress,
    bool isCompleted = false,
  }) {
    return Opacity(
      opacity: isCompleted ? 0.75 : 1.0,
      child: GlassPanel(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                icon,
                color: isCompleted
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.secondary,
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
