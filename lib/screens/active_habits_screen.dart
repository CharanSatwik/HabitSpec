import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_habit_sheet.dart';
import '../providers/habit_provider.dart';
import '../providers/auth_provider.dart';
import '../models/habit.dart';
import 'analytics_screen.dart';

class ActiveHabitsScreen extends StatefulWidget {
  final bool showAddHabit;
  final bool isEmbedded;
  const ActiveHabitsScreen({
    super.key,
    this.showAddHabit = false,
    this.isEmbedded = false,
  });

  @override
  State<ActiveHabitsScreen> createState() => _ActiveHabitsScreenState();
}

class _ActiveHabitsScreenState extends State<ActiveHabitsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showAddHabit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddHabitSheet(),
        );
      });
    }
  }

  void _showHabitOptions(
    BuildContext context,
    Habit habit,
    HabitProvider provider,
  ) {
    final theme = Theme.of(context);
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
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                title: const Text("Edit Habit"),
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddHabitSheet(editingHabit: habit),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text(
                  "Delete Habit",
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Habit"),
                      content: Text(
                        "Are you sure you want to delete '${habit.title}'?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.deleteHabit(habit.id);
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "Delete",
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

  void _changeUserName(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController(text: auth.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Username"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your new name"),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await auth.updateUserName(controller.text.trim());
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer<AuthProvider>(
          builder: (context, auth, _) => SafeArea(
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
                  leading: Icon(
                    Icons.edit_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text("Change Username"),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _changeUserName(context, auth);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: const Text("Logout"),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).logout();
                              Navigator.of(dialogContext).pop();
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateString = DateFormat('MMM d').format(now);

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
              builder: (consumerContext, auth, _) => GestureDetector(
                onTap: () => _showProfileMenu(consumerContext),
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
              "Today's Habits",
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateString,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Consumer<HabitProvider>(
            builder: (context, provider, child) {
              if (!provider.isInitialized) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final habits = provider.habits;

              if (habits.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No habits yet.",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddHabitSheet(),
                            );
                          },
                          child: const Text("Add your first habit"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == habits.length) {
                      return const SizedBox(
                        height: 100,
                      ); // padding for bottom nav
                    }

                    final habit = habits[index];
                    final isCompleted = habit.isCompletedOn(now);

                    String subtitleText = "";
                    if (habit.isQuantifiable) {
                      subtitleText = isCompleted
                          ? "Completed: ${habit.targetQuantity} ${habit.quantityUnit}"
                          : "Goal: ${habit.targetQuantity} ${habit.quantityUnit}";
                    } else {
                      subtitleText = isCompleted
                          ? "Completed"
                          : "Tap to complete";
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: HabitCard(
                        title: habit.title,
                        subtitle: subtitleText,
                        icon: IconData(
                          habit.iconCodePoint,
                          fontFamily: habit.iconFontFamily ?? 'MaterialIcons',
                        ),
                        iconBackgroundColor: isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondaryContainer,
                        iconColor: isCompleted
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSecondaryContainer,
                        isCompleted: isCompleted,
                        onLongPress: () =>
                            _showHabitOptions(context, habit, provider),
                        onTap: () {
                          provider.toggleHabitCompletion(habit.id, now);
                        },
                        progressWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  habit.progressText,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "${(habit.progressPercentage * 100).toInt()}%",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: habit.progressPercentage,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                        actionWidget: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.2,
                                  )
                                : theme.colorScheme.surfaceContainerHighest,
                            border: isCompleted
                                ? null
                                : Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                          ),
                          child: Icon(
                            isCompleted ? Icons.task_alt : Icons.check,
                            color: isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.tertiary,
                          ),
                        ),
                      ),
                    );
                  }, childCount: habits.length + 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
