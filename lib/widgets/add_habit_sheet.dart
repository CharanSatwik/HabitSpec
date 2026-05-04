import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import 'glass_panel.dart';
import 'glass_input.dart';
import 'primary_glow_button.dart';
import '../utils/ui_utils.dart';

class AddHabitSheet extends StatefulWidget {
  final Habit? editingHabit;
  const AddHabitSheet({super.key, this.editingHabit});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  // Quantifiable fields
  bool _isQuantifiable = false;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  IconData _selectedIcon = Icons.self_improvement;
  int _goalDays = 30;

  final List<IconData> _availableIcons = [
    Icons.self_improvement,
    Icons.water_drop,
    Icons.edit_document,
    Icons.fitness_center,
    Icons.menu_book,
    Icons.directions_run,
    Icons.bedtime,
    Icons.spa,
    Icons.music_note,
    Icons.clean_hands,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingHabit != null) {
      _titleController.text = widget.editingHabit!.title;
      _selectedIcon = IconData(
        widget.editingHabit!.iconCodePoint,
        fontFamily: widget.editingHabit!.iconFontFamily ?? 'MaterialIcons',
      );
      _goalDays = widget.editingHabit!.goalDays;
      if (!_availableIcons.contains(_selectedIcon)) {
        _availableIcons.insert(0, _selectedIcon);
      }
      _isQuantifiable = widget.editingHabit!.isQuantifiable;
      if (_isQuantifiable) {
        _quantityController.text =
            widget.editingHabit!.targetQuantity?.toString() ?? "";
        _unitController.text = widget.editingHabit!.quantityUnit ?? "";
      }
    }
    _goalController.text = _goalDays.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _saveHabit() {
    final title = _titleController.text.trim();
    final goalText = _goalController.text.trim();
    final goal = int.tryParse(goalText) ?? _goalDays;

    double? qty;
    String? unit;
    if (_isQuantifiable) {
      qty = double.tryParse(_quantityController.text.trim());
      unit = _unitController.text.trim();
      if (qty == null || unit.isEmpty) {
        UIUtils.showTopSnackBar(context, "Please enter quantity and unit");
        return;
      }
    }

    if (title.isNotEmpty) {
      final provider = Provider.of<HabitProvider>(context, listen: false);
      if (widget.editingHabit != null) {
        provider.editHabit(
          widget.editingHabit!.id,
          title,
          _selectedIcon,
          goal,
          isQuantifiable: _isQuantifiable,
          targetQuantity: qty,
          quantityUnit: unit,
        );
      } else {
        provider.addHabit(
          title,
          _selectedIcon,
          goal,
          isQuantifiable: _isQuantifiable,
          targetQuantity: qty,
          quantityUnit: unit,
        );
      }
      Navigator.of(context).pop();
    } else {
      UIUtils.showTopSnackBar(context, "Please enter a habit title");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GlassPanel(
        customBorderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.editingHabit != null ? "Edit Habit" : "New Habit",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GlassInput(
                hintText: "What do you want to track?",
                controller: _titleController,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Text(
                "Choose Icon",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Goal Duration (Days)",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GlassInput(
                          hintText: "e.g. 30",
                          controller: _goalController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Add daily quantity goal",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  "e.g., 2 Liters, 5 km",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _isQuantifiable,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (val) {
                  setState(() {
                    _isQuantifiable = val;
                  });
                },
              ),
              if (_isQuantifiable) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: GlassInput(
                        hintText: "Quantity",
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: GlassInput(
                        hintText: "Unit (e.g. L, km)",
                        controller: _unitController,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              PrimaryGlowButton(text: "Save Habit", onPressed: _saveHabit),
            ],
          ),
        ),
      ),
    );
  }
}
