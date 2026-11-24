import 'package:material_ui/material_ui.dart';
import 'package:planify_mobile/activity_creation_screen.dart';
import 'package:planify_mobile/services/activities_api.dart';
import 'package:planify_mobile/services/auth_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session, this.activitiesApi});

  final AuthSession session;
  final ActivitiesApi? activitiesApi;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ActivitiesApi _activitiesApi;
  late final bool _ownsActivitiesApi;
  List<PlanifyActivity> _activities = [];
  bool _isLoadingActivities = true;
  String? _activitiesError;

  @override
  void initState() {
    super.initState();
    _ownsActivitiesApi = widget.activitiesApi == null;
    _activitiesApi = widget.activitiesApi ?? ActivitiesApi();
    _loadActivities();
  }

  @override
  void dispose() {
    if (_ownsActivitiesApi) {
      _activitiesApi.close();
    }
    super.dispose();
  }

  String get _firstName {
    final name = widget.session.firstName?.trim();
    if (name == null || name.isEmpty) {
      return 'bienvenido';
    }
    return name.split(RegExp(r'\s+')).first;
  }

  static const _actions = [
    _HomeAction(
      id: 'create-activity',
      label: 'Crear\nActividad',
      icon: Icons.create_new_folder_outlined,
      color: Color(0xFF00A85A),
      background: Color(0xFFD8F9E6),
    ),
    _HomeAction(
      id: 'ai-agent',
      label: 'Solicitar\nAgente IA',
      icon: Icons.forum_outlined,
      color: Color(0xFF21177A),
      background: Color(0xFFF0EEFF),
    ),
    _HomeAction(
      id: 'view-activity',
      label: 'Ver\nActividad',
      icon: Icons.assignment_outlined,
      color: Color(0xFF43A8E8),
      background: Color(0xFFE1F4FF),
    ),
    _HomeAction(
      id: 'reminders',
      label: 'Recordatorios',
      icon: Icons.notifications_none_rounded,
      color: Color(0xFFEA8A00),
      background: Color(0xFFFFF1D4),
    ),
    _HomeAction(
      id: 'history',
      label: 'Historial',
      icon: Icons.history_rounded,
      color: Color(0xFFFF6B83),
      background: Color(0xFFFFE6E9),
    ),
    _HomeAction(
      id: 'statistics',
      label: 'Estadísticas',
      icon: Icons.analytics_outlined,
      color: Color(0xFF00A88A),
      background: Color(0xFFDDF8F2),
    ),
  ];

  Future<void> _loadActivities() async {
    setState(() {
      _isLoadingActivities = true;
      _activitiesError = null;
    });

    try {
      final allActivities = await _activitiesApi.fetchActivities(
        accessToken: widget.session.accessToken,
      );
      final now = DateTime.now();
      final upcomingActivities =
          allActivities
              .where((activity) => activity.startsAt.isAfter(now))
              .toList()
            ..sort((first, second) {
              final firstNotification = first.notificationAt.isBefore(now)
                  ? first.startsAt
                  : first.notificationAt;
              final secondNotification = second.notificationAt.isBefore(now)
                  ? second.startsAt
                  : second.notificationAt;
              return firstNotification.compareTo(secondNotification);
            });
      if (mounted) {
        setState(() {
          _activities = upcomingActivities;
        });
      }
    } on ActivitiesApiException catch (error) {
      if (mounted) {
        setState(() {
          _activitiesError = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
        });
      }
    }
  }

  Future<void> _openActivityCreation() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ActivityCreationScreen(
          session: widget.session,
          activitiesApi: _activitiesApi,
        ),
      ),
    );
    if (created == true) {
      await _loadActivities();
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildTodaySummary(),
                    _buildActions(),
                    _buildActivities(),
                    _buildAssistantCard(),
                  ],
                ),
              ),
            ),
            NavigationBar(
              height: 66,
              selectedIndex: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  label: 'Actividades',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_none_rounded),
                  label: 'Recordatorios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AspectRatio(
      key: const Key('home-hero'),
      aspectRatio: 2000 / 750,
      child: ClipRRect(
        key: const Key('home-hero-clip'),
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/principal.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: 'Planify, organiza hoy, logra mañana',
            ),
            Positioned(
              left: 16,
              right: 150,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $_firstName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Aquí tienes un resumen de tus actividades y recordatorios de hoy.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF4F5962),
                      fontSize: 10,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 16,
              child: Row(
                children: [
                  _HeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notificaciones',
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    icon: Icons.account_circle_outlined,
                    label: 'Perfil',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    final todayActivities = _activities
        .where((activity) => _isToday(activity.startsAt))
        .length;
    final remindersToday = _activities
        .where(
          (activity) =>
              activity.reminderEnabled == true &&
              _isToday(activity.notificationAt),
        )
        .length;

    return Transform.translate(
      key: const Key('summary-overlap'),
      offset: const Offset(0, -12),
      child: Container(
        key: const Key('today-summary'),
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD9F9E6),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF86F0B0),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 29,
                color: Color(0xFF006B37),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tienes hoy',
                    style: TextStyle(fontSize: 10, color: Color(0xFF626B70)),
                  ),
                  Text(
                    '$todayActivities actividades',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$remindersToday recordatorios pendientes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF626B70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF83ECAF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver todas',
                    style: TextStyle(
                      color: Color(0xFF005B31),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = 10.0;
          final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
          return Wrap(
            spacing: spacing,
            runSpacing: 10,
            children: [
              for (final action in _actions)
                SizedBox(
                  width: itemWidth,
                  height: 86,
                  child: _ActionCard(
                    key: Key('action-${action.id}'),
                    action: action,
                    onTap: action.id == 'create-activity'
                        ? _openActivityCreation
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivities() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próximas actividades',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Row(
                children: [
                  Text('Ver todas', style: TextStyle(color: Color(0xFF18A84F))),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: Color(0xFF18A84F),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            key: const Key('upcoming-activities'),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildActivityRows(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRows() {
    if (_isLoadingActivities) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            key: Key('activities-loading'),
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_activitiesError != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              _activitiesError!,
              key: const Key('activities-error'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF70777D)),
            ),
            TextButton(
              onPressed: _loadActivities,
              child: const Text('Volver a intentar'),
            ),
          ],
        ),
      );
    }
    if (_activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aún no tienes actividades próximas.',
          key: Key('activities-empty'),
          style: TextStyle(fontSize: 11, color: Color(0xFF70777D)),
          textAlign: TextAlign.center,
        ),
      );
    }

    final displayedActivities = _activities.take(5).toList();
    return Column(
      children: [
        for (var index = 0; index < displayedActivities.length; index++) ...[
          _ActivityRow(activity: displayedActivities[index]),
          if (index != displayedActivities.length - 1)
            const Divider(height: 1, indent: 12, endIndent: 12),
        ],
      ],
    );
  }

  Widget _buildAssistantCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRRect(
            key: const Key('assistant-card'),
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 2172 / 724,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/assistant_help.png',
                    key: const Key('assistant-card-image'),
                    fit: BoxFit.cover,
                    semanticLabel: 'Robot de Planify para ayudarte',
                  ),
                  Positioned(
                    left: constraints.maxWidth * 0.43,
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Necesitas ayuda?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pregunta a nuestro agente IA y recibe recomendaciones para organizar mejor tu tiempo y cumplir tus objetivos.',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFF2F8FF),
                            fontSize: 9,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_rounded,
                                size: 12,
                                color: Color(0xFF087D66),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Chatear con IA',
                                style: TextStyle(
                                  color: Color(0xFF064B58),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 13,
                                color: Color(0xFF064B58),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: null,
      tooltip: label,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 22, color: const Color(0xFF00994B)),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({super.key, required this.action, this.onTap});

  final _HomeAction action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(action.icon, color: action.color, size: 23),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: action.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_circle_right_rounded,
                    size: 18,
                    color: action.color.withAlpha(160),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final PlanifyActivity activity;

  @override
  Widget build(BuildContext context) {
    final style = _activityStyle(activity.category);
    final date = activity.startsAt;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeLabel =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    final reminderLabel =
        activity.reminderEnabled == true &&
            activity.reminderMinutesBefore != null
        ? 'Aviso ${activity.reminderMinutesBefore} min antes'
        : 'Sin recordatorio';
    final priority = activity.priority ?? 'Media';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Icon(style.icon, size: 20, color: style.color),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$dateLabel   $timeLabel · $reminderLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF70777D)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: style.color.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              priority,
              style: TextStyle(
                color: style.color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ActivityStyle _activityStyle(String? category) {
    switch (category?.toLowerCase()) {
      case 'estudio':
        return const _ActivityStyle(
          icon: Icons.menu_book_rounded,
          color: Color(0xFF21177A),
        );
      case 'trabajo':
        return const _ActivityStyle(
          icon: Icons.work_outline_rounded,
          color: Color(0xFF00A85A),
        );
      case 'personal':
        return const _ActivityStyle(
          icon: Icons.person_outline_rounded,
          color: Color(0xFF62A5D8),
        );
      default:
        return const _ActivityStyle(
          icon: Icons.event_note_rounded,
          color: Color(0xFFEA8A00),
        );
    }
  }
}

class _HomeAction {
  const _HomeAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
}

class _ActivityStyle {
  const _ActivityStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}
