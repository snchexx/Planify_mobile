import 'package:material_ui/material_ui.dart';
import 'package:planify_mobile/services/auth_api.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.session});

  final AuthSession session;

  String get _firstName {
    final name = session.firstName?.trim();
    if (name == null || name.isEmpty) {
      return 'bienvenido';
    }
    return name.split(RegExp(r'\s+')).first;
  }

  static const _activities = [
    _ActivityData(
      title: 'Examen de matemáticas',
      date: '10 sep 2026',
      time: '8:00 AM',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF21177A),
      statusColor: Color(0xFF21177A),
      status: 'Pendiente',
    ),
    _ActivityData(
      title: 'Entregar trabajo de programación',
      date: '10 sep 2026',
      time: '8:00 AM',
      icon: Icons.description_rounded,
      color: Color(0xFF00A85A),
      statusColor: Color(0xFF00A85A),
      status: 'Pendiente',
    ),
    _ActivityData(
      title: 'Reunión con el equipo',
      date: '10 sep 2026',
      time: '9:00 AM',
      icon: Icons.groups_rounded,
      color: Color(0xFF62B6F4),
      statusColor: Color(0xFF62B6F4),
      status: 'Pendiente',
    ),
    _ActivityData(
      title: 'Salir al gimnasio',
      date: '10 sep 2026',
      time: '10:00 AM',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFE84265),
      statusColor: Color(0xFFE84265),
      status: 'Pendiente',
    ),
    _ActivityData(
      title: 'Aprender inglés',
      date: '10 sep 2026',
      time: '11:00 AM',
      icon: Icons.translate_rounded,
      color: Color(0xFFFFA500),
      statusColor: Color(0xFFFFA500),
      status: 'Pendiente',
    ),
  ];

  static const _actions = [
    _HomeAction(
      label: 'Crear\nActividad',
      icon: Icons.create_new_folder_outlined,
      color: Color(0xFF00A85A),
      background: Color(0xFFD8F9E6),
    ),
    _HomeAction(
      label: 'Solicitar\nAgente IA',
      icon: Icons.forum_outlined,
      color: Color(0xFF21177A),
      background: Color(0xFFF0EEFF),
    ),
    _HomeAction(
      label: 'Ver\nActividad',
      icon: Icons.assignment_outlined,
      color: Color(0xFF43A8E8),
      background: Color(0xFFE1F4FF),
    ),
    _HomeAction(
      label: 'Recordatorios',
      icon: Icons.notifications_none_rounded,
      color: Color(0xFFEA8A00),
      background: Color(0xFFFFF1D4),
    ),
    _HomeAction(
      label: 'Historial',
      icon: Icons.history_rounded,
      color: Color(0xFFFF6B83),
      background: Color(0xFFFFE6E9),
    ),
    _HomeAction(
      label: 'Estadísticas',
      icon: Icons.analytics_outlined,
      color: Color(0xFF00A88A),
      background: Color(0xFFDDF8F2),
    ),
  ];

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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tienes hoy',
                    style: TextStyle(fontSize: 10, color: Color(0xFF626B70)),
                  ),
                  Text(
                    '3 actividades',
                    maxLines: 1,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '1 recordatorio pendiente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Color(0xFF626B70)),
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
                  child: _ActionCard(action: action),
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
            child: Column(
              children: [
                for (var index = 0; index < _activities.length; index++) ...[
                  _ActivityRow(activity: _activities[index]),
                  if (index != _activities.length - 1)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                ],
              ],
            ),
          ),
        ],
      ),
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
  const _ActionCard({required this.action});

  final _HomeAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      decoration: BoxDecoration(
        color: action.background,
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
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final _ActivityData activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Icon(activity.icon, size: 20, color: activity.color),
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
                  '${activity.date}   ${activity.time}',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF70777D)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: activity.color.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              activity.status,
              style: TextStyle(
                color: activity.statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.more_vert, size: 18),
        ],
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
}

class _ActivityData {
  const _ActivityData({
    required this.title,
    required this.date,
    required this.time,
    required this.icon,
    required this.color,
    required this.statusColor,
    required this.status,
  });

  final String title;
  final String date;
  final String time;
  final IconData icon;
  final Color color;
  final Color statusColor;
  final String status;
}
