import 'package:flutter/material.dart';
import 'glass_panel.dart';

class HabitCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Widget? actionWidget;
  final Widget? progressWidget;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const HabitCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.actionWidget,
    this.progressWidget,
    this.isCompleted = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Opacity(
        opacity: isCompleted ? 0.7 : 1.0,
        child: GlassPanel(
          borderRadius: 24.0,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: iconBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor:
                                      theme.colorScheme.outlineVariant,
                                  decorationThickness: 2,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isCompleted
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isCompleted
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionWidget != null) ...[
                    const SizedBox(width: 16),
                    actionWidget!,
                  ],
                ],
              ),
              if (progressWidget != null) ...[
                const SizedBox(height: 16),
                progressWidget!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

