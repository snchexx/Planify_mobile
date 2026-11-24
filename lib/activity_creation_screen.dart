import 'package:material_ui/material_ui.dart';
import 'package:planify_mobile/services/activities_api.dart';
import 'package:planify_mobile/services/auth_api.dart';

class ActivityCreationScreen extends StatefulWidget {
  const ActivityCreationScreen({
    super.key,
    required this.session,
    required this.activitiesApi,
    this.activity,
  });

  final AuthSession session;
  final ActivitiesApi activitiesApi;
  final PlanifyActivity? activity;

  @override
  State<ActivityCreationScreen> createState() => _ActivityCreationScreenState();
}

class _ActivityCreationScreenState extends State<ActivityCreationScreen> {
  static const _green = Color(0xFF18A84F);
  static const _priorityOptions = ['Alta', 'Media', 'Baja'];
  static const _reminderOptions = [15, 25, 35, 45, 60];
  static const _categories = [
    _CategoryOption('Estudio', Icons.menu_book_outlined),
    _CategoryOption('Trabajo', Icons.work_outline_rounded),
    _CategoryOption('Personal', Icons.person_outline_rounded),
    _CategoryOption('Otros', Icons.more_horiz_rounded),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String _selectedCategory = 'Estudio';
  String _selectedPriority = 'Alta';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _reminderMinutesBefore = 15;
  bool _reminderEnabled = true;
  bool _isSaving = false;
  String? _saveError;

  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    if (activity == null) {
      return;
    }

    _titleController.text = activity.title;
    _descriptionController.text = activity.description;
    final category = activity.category;
    if (category != null) {
      if (_categories.any((option) => option.label == category)) {
        _selectedCategory = category;
      } else {
        _selectedCategory = 'Otros';
        _customCategoryController.text = category;
      }
    }
    if (_priorityOptions.contains(activity.priority)) {
      _selectedPriority = activity.priority!;
    }
    final startsAt = activity.startsAt;
    _selectedDate = DateTime(startsAt.year, startsAt.month, startsAt.day);
    _selectedTime = TimeOfDay.fromDateTime(startsAt);
    _reminderEnabled = activity.reminderEnabled ?? false;
    if (_reminderOptions.contains(activity.reminderMinutesBefore)) {
      _reminderMinutesBefore = activity.reminderMinutesBefore!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
      helpText: 'Selecciona la fecha de la actividad',
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Selecciona la hora de la actividad',
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) {
      return 'Escribe el título de la actividad.';
    }
    if (title.length > 150) {
      return 'El título no puede superar 150 caracteres.';
    }
    return null;
  }

  String _dateForApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _timeForApi(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String _categoryValue() => _selectedCategory == 'Otros'
      ? _customCategoryController.text.trim()
      : _selectedCategory;

  Future<void> _saveActivity() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      setState(() {
        _saveError = _selectedDate == null
            ? 'Selecciona la fecha de la actividad.'
            : 'Selecciona la hora de la actividad.';
      });
      return;
    }
    if (_selectedCategory == 'Otros' && _categoryValue().isEmpty) {
      setState(() {
        _saveError = 'Escribe el nombre de la categoría.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final date = _dateForApi(_selectedDate!);
      final time = _timeForApi(_selectedTime!);
      final category = _categoryValue();
      final reminderMinutesBefore = _reminderEnabled
          ? _reminderMinutesBefore
          : null;
      if (_isEditing) {
        await widget.activitiesApi.updateActivity(
          id: widget.activity!.id,
          accessToken: widget.session.accessToken,
          title: title,
          description: description,
          date: date,
          time: time,
          category: category,
          priority: _selectedPriority,
          reminderEnabled: _reminderEnabled,
          reminderMinutesBefore: reminderMinutesBefore,
        );
      } else {
        await widget.activitiesApi.createActivity(
          accessToken: widget.session.accessToken,
          title: title,
          description: description,
          date: date,
          time: time,
          category: category,
          priority: _selectedPriority,
          reminderEnabled: _reminderEnabled,
          reminderMinutesBefore: reminderMinutesBefore,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ActivitiesApiException catch (error) {
      if (mounted) {
        setState(() {
          _saveError = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 2000 / 600,
                child: Image.asset(
                  'assets/create_activity_banner.png',
                  key: const Key('create-activity-banner'),
                  fit: BoxFit.cover,
                  semanticLabel: 'Planify, organiza hoy, logra mañana',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 17),
                      _buildLabeledField(
                        label: 'Título de la actividad',
                        child: TextFormField(
                          key: const Key('activity-title-field'),
                          controller: _titleController,
                          maxLength: 150,
                          validator: _validateTitle,
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: 'Ej. Estudiar matemáticas, reunión de trabajo...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabeledField(
                        label: 'Descripción (opcional)',
                        child: TextFormField(
                          key: const Key('activity-description-field'),
                          controller: _descriptionController,
                          maxLength: 5000,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText:
                                'Agrega más detalles sobre tu actividad...',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('Fecha y hora'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _PickerButton(
                              key: const Key('activity-date-picker'),
                              icon: Icons.calendar_month_outlined,
                              label: _selectedDate == null
                                  ? 'Selecciona la fecha'
                                  : _formatDate(_selectedDate!),
                              onTap: _selectDate,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PickerButton(
                              key: const Key('activity-time-picker'),
                              icon: Icons.access_time_rounded,
                              label: _selectedTime == null
                                  ? 'Selecciona la hora'
                                  : _formatTime(_selectedTime!),
                              onTap: _selectTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Categoría'),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          for (
                            var index = 0;
                            index < _categories.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 5),
                            Expanded(
                              child: _CategoryButton(
                                option: _categories[index],
                                selected:
                                    _selectedCategory ==
                                    _categories[index].label,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory =
                                        _categories[index].label;
                                    _saveError = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_selectedCategory == 'Otros') ...[
                        const SizedBox(height: 9),
                        TextFormField(
                          key: const Key('custom-category-field'),
                          controller: _customCategoryController,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            hintText: 'Escribe una categoría',
                            counterText: '',
                          ),
                        ),
                      ],
                      const SizedBox(height: 17),
                      const _FieldLabel('Prioridad'),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          for (
                            var index = 0;
                            index < _priorityOptions.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 7),
                            Expanded(
                              child: _PriorityButton(
                                label: _priorityOptions[index],
                                selected:
                                    _selectedPriority ==
                                    _priorityOptions[index],
                                onTap: () {
                                  setState(() {
                                    _selectedPriority = _priorityOptions[index];
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 17),
                      const _FieldLabel('Recordatorio'),
                      const SizedBox(height: 7),
                      _buildReminderControl(),
                      if (_saveError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _saveError!,
                          key: const Key('activity-save-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          key: const Key('save-activity-button'),
                          onPressed: _isSaving ? null : _saveActivity,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.assignment_turned_in_outlined),
                          label: Text(
                            _isSaving
                                ? 'Guardando...'
                                : _isEditing
                                ? 'Guardar cambios'
                                : 'Guardar actividad',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF43AD79),
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isEditing ? Icons.edit_rounded : Icons.add_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Editar actividad' : 'Crear actividad',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _isEditing ? 'Actualiza los detalles de tu actividad.' : 'Agrega tus tareas y compromisos. ¡Mantén el control de tu día!',
                style: const TextStyle(fontSize: 11, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_FieldLabel(label), const SizedBox(height: 6), child],
    );
  }

  Widget _buildReminderControl() {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 7, right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF888888)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Switch(
            key: const Key('reminder-enabled-switch'),
            value: _reminderEnabled,
            activeTrackColor: _green,
            onChanged: (enabled) {
              setState(() {
                _reminderEnabled = enabled;
              });
            },
          ),
          const Expanded(
            child: Text(
              'Recibir notificación',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              key: const Key('reminder-offset-dropdown'),
              value: _reminderMinutesBefore,
              borderRadius: BorderRadius.circular(10),
              items: [
                for (final minutes in _reminderOptions)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(
                      '$minutes min antes',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
              onChanged: _reminderEnabled
                  ? (minutes) {
                      if (minutes != null) {
                        setState(() {
                          _reminderMinutesBefore = minutes;
                        });
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 19),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF555555),
        side: const BorderSide(color: Color(0xFF888888)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _CategoryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFDDF8E7) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('category-${option.label.toLowerCase()}-button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? const Color(0xFF0AA64F) : Colors.black54,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 20,
                color: selected ? const Color(0xFF00994B) : Colors.black,
              ),
              const SizedBox(height: 2),
              Text(
                option.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? const Color(0xFF007D3B) : Colors.black,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: Key('priority-${label.toLowerCase()}-button'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: selected ? const Color(0xFFDDF8E7) : Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF0AA64F) : Colors.black87,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: selected ? const Color(0xFF129F4B) : Colors.black,
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
