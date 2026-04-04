import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/core/extensions/extensions.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';
import 'package:handwerker_app/presentation/widgets/common/hw_widgets.dart';

// ═══════════════════════════════════════════════════════════════
// ADMIN SHELL
// ═══════════════════════════════════════════════════════════════

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedTab = 0;

  final _tabs = const [
    _AdminTab(icon: Icons.receipt_long_rounded, label: 'Aufträge'),
    _AdminTab(icon: Icons.people_rounded, label: 'Handwerker'),
    _AdminTab(icon: Icons.flag_rounded, label: 'Reklamationen'),
    _AdminTab(icon: Icons.analytics_rounded, label: 'Dashboard'),
    _AdminTab(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          AdminOrdersPanel(),
          AdminCraftsmenPanel(),
          AdminDisputesPanel(),
          AdminDashboard(),
          AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border:
              Border(top: BorderSide(color: AppTheme.slate800, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.asMap().entries.map((entry) {
                final isSelected = entry.key == _selectedTab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = entry.key),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.amber.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entry.value.icon,
                            size: 22,
                            color: isSelected
                                ? AppTheme.amber
                                : AppTheme.slate500),
                        const SizedBox(height: 4),
                        Text(
                          entry.value.label,
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.amber
                                : AppTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTab {
  final IconData icon;
  final String label;
  const _AdminTab({required this.icon, required this.label});
}

// ═══════════════════════════════════════════════════════════════
// ADMIN ORDERS PANEL
// ═══════════════════════════════════════════════════════════════

class AdminOrdersPanel extends ConsumerStatefulWidget {
  const AdminOrdersPanel({super.key});

  @override
  ConsumerState<AdminOrdersPanel> createState() =>
      _AdminOrdersPanelState();
}

class _AdminOrdersPanelState extends ConsumerState<AdminOrdersPanel> {
  OrderStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider(_filterStatus));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alle Aufträge',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Alle',
                        isSelected: _filterStatus == null,
                        onTap: () =>
                            setState(() => _filterStatus = null),
                      ),
                      _FilterChip(
                        label: 'Aktiv',
                        isSelected:
                            _filterStatus == OrderStatus.jobInProgress,
                        onTap: () => setState(() =>
                            _filterStatus = OrderStatus.jobInProgress),
                      ),
                      _FilterChip(
                        label: 'Offen',
                        isSelected:
                            _filterStatus == OrderStatus.requestCreated,
                        onTap: () => setState(() =>
                            _filterStatus = OrderStatus.requestCreated),
                      ),
                      _FilterChip(
                        label: 'Reklamation',
                        isSelected:
                            _filterStatus == OrderStatus.disputeOpened,
                        onTap: () => setState(() =>
                            _filterStatus = OrderStatus.disputeOpened),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Order list
        ordersAsync.when(
          data: (response) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: response.data!.isEmpty 
              ? const SliverToBoxAdapter(child: HWEmptyState(icon: Icons.receipt_long_rounded, title: 'Keine Aufträge gefunden'))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final order = response.data![i];
                      return SlideUpFadeIn(
                        delay: Duration(milliseconds: i * 50),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: HWInfoCard(
                            icon: order.status?.icon ?? Icons.receipt_long_rounded,
                            iconColor: order.status?.color ?? AppTheme.amber,
                            title: 'Auftrag #${order.orderNumber ?? order.id?.substring(0, 8)}',
                            subtitle: '${order.serviceCategory?.nameDE ?? 'Unbekannt'} • ${order.location?.city ?? ''}',
                            trailing: HWStatusBadge(
                              label: order.statusLabel,
                              color: order.status?.color ?? AppTheme.amber,
                            ),
                            onTap: () {},
                          ),
                        ),
                      );
                    },
                    childCount: response.data!.length,
                  ),
                ),
          ),
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.amber))),
          error: (e, _) => SliverFillRemaining(child: Center(child: Text('Fehler beim Laden: $e', style: const TextStyle(color: AppTheme.error)))),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADMIN CRAFTSMEN PANEL
// ═══════════════════════════════════════════════════════════════

class AdminCraftsmenPanel extends ConsumerStatefulWidget {
  const AdminCraftsmenPanel({super.key});

  @override
  ConsumerState<AdminCraftsmenPanel> createState() => _AdminCraftsmenPanelState();
}

class _AdminCraftsmenPanelState extends ConsumerState<AdminCraftsmenPanel> {
  CraftsmanStatus? _filterStatus;

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCraftsmanSheet(
        onCreated: () => ref.invalidate(adminCraftsmenProvider),
      ),
    );
  }

  void _openStatusSheet(BuildContext context, CraftsmanProfile craftsman) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusManagementSheet(
        craftsman: craftsman,
        onUpdated: () => ref.invalidate(adminCraftsmenProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final craftsmenAsync = ref.watch(adminCraftsmenProvider(_filterStatus));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Handwerker',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.slate100,
                        letterSpacing: -1,
                      ),
                    ),
                    HWButton(
                      label: 'Neu',
                      icon: Icons.add_rounded,
                      width: 100,
                      onTap: () => _openCreateSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    _AdminStatCard(
                      value: '—', // This would normally come from a summary API
                      label: 'Aktiv',
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 10),
                    _AdminStatCard(
                      value: '—',
                      label: 'Ausstehend',
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 10),
                    _AdminStatCard(
                      value: '—',
                      label: 'Gesperrt',
                      color: AppTheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Alle',
                        isSelected: _filterStatus == null,
                        onTap: () => setState(() => _filterStatus = null),
                      ),
                      _FilterChip(
                        label: 'Aktiv',
                        isSelected: _filterStatus == CraftsmanStatus.active,
                        onTap: () => setState(() => _filterStatus = CraftsmanStatus.active),
                      ),
                      _FilterChip(
                        label: 'Ausstehend',
                        isSelected: _filterStatus == CraftsmanStatus.pending,
                        onTap: () => setState(() => _filterStatus = CraftsmanStatus.pending),
                      ),
                      _FilterChip(
                        label: 'Gesperrt',
                        isSelected: _filterStatus == CraftsmanStatus.suspended,
                        onTap: () => setState(() => _filterStatus = CraftsmanStatus.suspended),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        craftsmenAsync.when(
          data: (response) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: response.data!.isEmpty
              ? const SliverToBoxAdapter(child: HWEmptyState(icon: Icons.people_rounded, title: 'Keine Handwerker gefunden'))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final craftsman = response.data![i];
                      return SlideUpFadeIn(
                        delay: Duration(milliseconds: i * 60),
                        child: TapScale(
                          onTap: () => _openStatusSheet(context, craftsman),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.slate800,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                              border: Border.all(color: AppTheme.slate700),
                            ),
                            child: Row(
                              children: [
                                HWAvatar(
                                  name: craftsman.displayName,
                                  size: 44,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        craftsman.displayName,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.displayFont,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.slate100,
                                        ),
                                      ),
                                      Text(
                                        '★ ${craftsman.ratingAvg?.toStringAsFixed(1) ?? '—'} • ${craftsman.completedJobsCount ?? 0} Aufträge',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.bodyFont,
                                          fontSize: 12,
                                          color: AppTheme.slate400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                HWStatusBadge(
                                  label: craftsman.status?.label ?? 'Unbekannt',
                                  color: craftsman.status?.color ?? AppTheme.slate400,
                                  showDot: false,
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.slate600,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: response.data!.length,
                  ),
                ),
          ),
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.amber))),
          error: (e, _) => SliverFillRemaining(child: Center(child: Text('Fehler beim Laden: $e', style: const TextStyle(color: AppTheme.error)))),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADMIN DISPUTES PANEL
// ═══════════════════════════════════════════════════════════════

class AdminDisputesPanel extends ConsumerStatefulWidget {
  const AdminDisputesPanel({super.key});

  @override
  ConsumerState<AdminDisputesPanel> createState() => _AdminDisputesPanelState();
}

class _AdminDisputesPanelState extends ConsumerState<AdminDisputesPanel> {
  DisputeStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final disputesAsync = ref.watch(adminDisputesProvider(_filterStatus));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offene Reklamationen',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SLA: Entscheidung innerhalb 72 Stunden',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    color: AppTheme.slate400,
                  ),
                ),
                const SizedBox(height: 20),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Alle',
                        isSelected: _filterStatus == null,
                        onTap: () => setState(() => _filterStatus = null),
                      ),
                      _FilterChip(
                        label: 'Offen',
                        isSelected: _filterStatus == DisputeStatus.opened,
                        onTap: () => setState(() => _filterStatus = DisputeStatus.opened),
                      ),
                      _FilterChip(
                        label: 'In Prüfung',
                        isSelected: _filterStatus == DisputeStatus.underReview,
                        onTap: () => setState(() => _filterStatus = DisputeStatus.underReview),
                      ),
                      _FilterChip(
                        label: 'Gelöst',
                        isSelected: _filterStatus == DisputeStatus.resolved,
                        onTap: () => setState(() => _filterStatus = DisputeStatus.resolved),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        disputesAsync.when(
          data: (response) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: response.data!.isEmpty
              ? const SliverToBoxAdapter(child: HWEmptyState(icon: Icons.flag_rounded, title: 'Keine Reklamationen gefunden'))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final dispute = response.data![i];
                      final Color statusColor = dispute.status == DisputeStatus.resolved 
                          ? AppTheme.success 
                          : (dispute.status == DisputeStatus.opened ? AppTheme.error : AppTheme.warning);

                      return SlideUpFadeIn(
                        delay: Duration(milliseconds: i * 60),
                        child: TapScale(
                          onTap: () {},
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.slate800,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                              border: Border.all(
                                color: statusColor.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    HWStatusBadge(
                                      label: dispute.status?.name.toUpperCase() ?? 'UNBEKANNT',
                                      color: statusColor,
                                    ),
                                    const Spacer(),
                                    Text(
                                      dispute.createdAt?.timeAgo ?? '',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.bodyFont,
                                        fontSize: 12,
                                        color: AppTheme.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Auftrag #${dispute.orderId?.substring(0, 8)}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.slate100,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dispute.description ?? 'Keine Beschreibung',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.bodyFont,
                                    fontSize: 13,
                                    color: AppTheme.slate400,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.slate700,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Prüfen →',
                                            style: TextStyle(
                                              fontFamily: AppTheme.bodyFont,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.slate200,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    );
                  },
                    childCount: response.data!.length,
                  ),
                ),
          ),
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.amber))),
          error: (e, _) => SliverFillRemaining(child: Center(child: Text('Fehler beim Laden: $e', style: const TextStyle(color: AppTheme.error)))),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADMIN DASHBOARD
// ═══════════════════════════════════════════════════════════════

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analytics',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),

                // KPI cards
                Row(
                  children: [
                    Expanded(
                      child: _KPICard(
                        label: 'Ø Erste Antwort',
                        value: '3.2',
                        unit: 'min',
                        target: '< 5 min',
                        progress: 0.85,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KPICard(
                        label: 'Erfüllungsrate',
                        value: '84',
                        unit: '%',
                        target: '> 80%',
                        progress: 0.84,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KPICard(
                        label: 'Ø Bewertung',
                        value: '4.5',
                        unit: '/ 5',
                        target: '> 4.3',
                        progress: 0.9,
                        color: AppTheme.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KPICard(
                        label: 'Reklamationsrate',
                        value: '2.1',
                        unit: '%',
                        target: '< 3%',
                        progress: 0.7,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KPICard(
                        label: 'Zahlungserfolg',
                        value: '98.2',
                        unit: '%',
                        target: '> 97%',
                        progress: 0.98,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KPICard(
                        label: 'Stornoquote',
                        value: '3.8',
                        unit: '%',
                        target: '< 5%',
                        progress: 0.76,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Today's stats
                const Text(
                  'Heute',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate100,
                  ),
                ),
                const SizedBox(height: 12),

                _TodayStat(
                  icon: Icons.add_circle_outline,
                  label: 'Neue Aufträge',
                  value: '23',
                  color: AppTheme.amber,
                ),
                _TodayStat(
                  icon: Icons.check_circle_outline,
                  label: 'Abgeschlossen',
                  value: '18',
                  color: AppTheme.success,
                ),
                _TodayStat(
                  icon: Icons.euro_rounded,
                  label: 'Umsatz',
                  value: '€2,340',
                  color: AppTheme.amber,
                ),
                _TodayStat(
                  icon: Icons.people_outline,
                  label: 'Aktive Handwerker',
                  value: '19',
                  color: AppTheme.info,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: HWAnimations.fast,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.amber : AppTheme.slate800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.slate900 : AppTheme.slate300,
          ),
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _AdminStatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 12,
                color: AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String target;
  final double progress;
  final Color color;

  const _KPICard({
    required this.label,
    required this.value,
    required this.unit,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.slate800,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12,
              color: AppTheme.slate400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate100,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  color: AppTheme.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedProgressRing(
            progress: progress,
            size: 6,
            strokeWidth: 6,
            color: color,
            backgroundColor: AppTheme.slate700,
          ),
          const SizedBox(height: 6),
          Text(
            'Ziel: $target',
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TodayStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.slate800,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 14,
                  color: AppTheme.slate300,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADMIN PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Profil',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.slate100,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Admin badge card
                  SlideUpFadeIn(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.slate800,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLG),
                        border: Border.all(color: AppTheme.slate700),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.amber, AppTheme.amberDark],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.glowAmber,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 30,
                                color: AppTheme.slate900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Administrator',
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.slate100,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.amber.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.amber,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  _AdminMenuItem(
                    index: 0,
                    icon: Icons.dark_mode_outlined,
                    label: 'Dunkelmodus',
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (v) =>
                          ref.read(themeModeProvider.notifier).state = v,
                      activeColor: AppTheme.amber,
                    ),
                    onTap: () => ref.read(themeModeProvider.notifier).state =
                        !isDark,
                  ),
                  _AdminMenuItem(
                    index: 1,
                    icon: Icons.help_outline_rounded,
                    label: 'Hilfe & Support',
                    onTap: () {},
                  ),
                  _AdminMenuItem(
                    index: 2,
                    icon: Icons.info_outline_rounded,
                    label: 'Über die App',
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),

                  // Logout button
                  SlideUpFadeIn(
                    delay: const Duration(milliseconds: 400),
                    child: GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.surfaceCard,
                            title: const Text(
                              'Abmelden?',
                              style: TextStyle(color: AppTheme.slate100),
                            ),
                            content: const Text(
                              'Möchtest du dich wirklich abmelden?',
                              style: TextStyle(color: AppTheme.slate400),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Abbrechen',
                                    style: TextStyle(
                                        color: AppTheme.slate400)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Abmelden',
                                    style:
                                        TextStyle(color: AppTheme.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref.read(authProvider.notifier).logout();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(
                              color: AppTheme.error.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: AppTheme.error, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Abmelden',
                              style: TextStyle(
                                fontFamily: AppTheme.displayFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Handwerker v1.0.0',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 12,
                        color: AppTheme.slate600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _AdminMenuItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SlideUpFadeIn(
      delay: Duration(milliseconds: 100 + index * 60),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.slate400, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.slate200,
                  ),
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.slate600, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATUS MANAGEMENT SHEET
// ═══════════════════════════════════════════════════════════════

class _StatusManagementSheet extends ConsumerStatefulWidget {
  final CraftsmanProfile craftsman;
  final VoidCallback? onUpdated;

  const _StatusManagementSheet({
    required this.craftsman,
    this.onUpdated,
  });

  @override
  ConsumerState<_StatusManagementSheet> createState() =>
      _StatusManagementSheetState();
}

class _StatusManagementSheetState
    extends ConsumerState<_StatusManagementSheet> {
  CraftsmanStatus? _selectedStatus;
  final _reasonCtrl = TextEditingController();
  bool _confirmDeactivation = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  CraftsmanStatus get _currentStatus =>
      widget.craftsman.status ?? CraftsmanStatus.pending;

  Future<void> _submit() async {
    if (_selectedStatus == null) return;

    await ref.read(updateCraftsmanStatusProvider.notifier).update(
          widget.craftsman.id!,
          _selectedStatus!,
          reason: _reasonCtrl.text.trim().isEmpty
              ? null
              : _reasonCtrl.text.trim(),
        );

    final state = ref.read(updateCraftsmanStatusProvider);
    if (!mounted) return;

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: AppTheme.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.error!,
                  style: const TextStyle(color: AppTheme.slate100),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      Navigator.of(context).pop();
      widget.onUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 10),
              Text(
                'Status auf „${_selectedStatus!.label}" geändert',
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateCraftsmanStatusProvider);
    final transitions = _currentStatus.allowedTransitions;
    final isTerminalCurrent = _currentStatus.isTerminal;
    final isDeactivationSelected =
        _selectedStatus == CraftsmanStatus.deactivated;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.slate600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                HWAvatar(name: widget.craftsman.displayName, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.craftsman.displayName,
                        style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate100,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _currentStatus.icon,
                            size: 14,
                            color: _currentStatus.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _currentStatus.label,
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _currentStatus.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Terminal state notice
            if (isTerminalCurrent) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.slate700,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.slate600),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 18, color: AppTheme.slate400),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dieser Account ist permanent deaktiviert. Keine weiteren Statusänderungen möglich.',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 13,
                          color: AppTheme.slate400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Status selection label
              const Text(
                'Status ändern zu',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate400,
                ),
              ),
              const SizedBox(height: 12),

              // Status chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: transitions.map((status) {
                  final isSelected = _selectedStatus == status;
                  final isDeactivate = status == CraftsmanStatus.deactivated;
                  final chipColor =
                      isDeactivate ? AppTheme.error : status.color;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedStatus =
                          isSelected ? null : status;
                      if (_selectedStatus != CraftsmanStatus.deactivated) {
                        _confirmDeactivation = false;
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? chipColor.withOpacity(0.15)
                            : AppTheme.slate800,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? chipColor : AppTheme.slate700,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon,
                              size: 16,
                              color: isSelected
                                  ? chipColor
                                  : AppTheme.slate400),
                          const SizedBox(width: 7),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? chipColor
                                  : AppTheme.slate300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_selectedStatus != null) ...[
                const SizedBox(height: 20),

                // Deactivation warning + confirmation
                if (isDeactivationSelected) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.error.withOpacity(0.25)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 18, color: AppTheme.error),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'DEAKTIVIERT ist ein permanenter Zustand. Diese Aktion kann nicht rückgängig gemacht werden.',
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 13,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(
                        () => _confirmDeactivation = !_confirmDeactivation),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _confirmDeactivation
                                ? AppTheme.error
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _confirmDeactivation
                                  ? AppTheme.error
                                  : AppTheme.slate600,
                            ),
                          ),
                          child: _confirmDeactivation
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Ich bestätige, dass dieser Account permanent deaktiviert werden soll.',
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 13,
                              color: AppTheme.slate300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Reason field
                const Text(
                  'Begründung (optional)',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate400,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 14,
                    color: AppTheme.slate100,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'z. B. „Alle Dokumente geprüft und genehmigt"',
                    hintStyle: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14,
                      color: AppTheme.slate500,
                    ),
                    filled: true,
                    fillColor: AppTheme.slate800,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.slate700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.slate700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppTheme.amber, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                HWButton(
                  label: isDeactivationSelected
                      ? 'Permanent deaktivieren'
                      : 'Status auf „${_selectedStatus!.label}" setzen',
                  icon: isDeactivationSelected
                      ? Icons.cancel_rounded
                      : _selectedStatus!.icon,
                  isLoading: updateState.isLoading,
                  onTap: (updateState.isLoading ||
                          (isDeactivationSelected && !_confirmDeactivation))
                      ? null
                      : _submit,
                ),
              ],
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CREATE CRAFTSMAN SHEET
// ═══════════════════════════════════════════════════════════════

class _CreateCraftsmanSheet extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;
  const _CreateCraftsmanSheet({this.onCreated});

  @override
  ConsumerState<_CreateCraftsmanSheet> createState() =>
      _CreateCraftsmanSheetState();
}

class _CreateCraftsmanSheetState extends ConsumerState<_CreateCraftsmanSheet> {
  final _formKey = GlobalKey<FormState>();

  final _phoneCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  final Set<String> _selectedCategoryIds = {};

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _radiusCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final request = CreateCraftsmanRequest(
      phone: _phoneCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      categoryIds:
          _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.toList(),
      radiusKm: _radiusCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_radiusCtrl.text.trim()),
      street: _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      postalCode:
          _postalCtrl.text.trim().isEmpty ? null : _postalCtrl.text.trim(),
    );

    await ref.read(createCraftsmanProvider.notifier).submit(request);

    final state = ref.read(createCraftsmanProvider);
    if (!mounted) return;

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: ${state.error}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      Navigator.of(context).pop();
      widget.onCreated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 10),
              Text(
                  'Handwerker ${state.created?.displayName ?? ''} angelegt'),
            ],
          ),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createCraftsmanProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.slate600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Handwerker anlegen',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.slate100,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // Phone
              _SheetLabel('Telefonnummer *'),
              _SheetTextField(
                controller: _phoneCtrl,
                hint: '+49 151 00000000',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Pflichtfeld';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // First + Last name row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SheetLabel('Vorname *'),
                        _SheetTextField(
                          controller: _firstNameCtrl,
                          hint: 'Max',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Pflichtfeld'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SheetLabel('Nachname *'),
                        _SheetTextField(
                          controller: _lastNameCtrl,
                          hint: 'Mustermann',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Pflichtfeld'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Email
              _SheetLabel('E-Mail'),
              _SheetTextField(
                controller: _emailCtrl,
                hint: 'max@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),

              // Radius
              _SheetLabel('Einsatzradius (km)'),
              _SheetTextField(
                controller: _radiusCtrl,
                hint: '25',
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                prefixIcon: Icons.radar_rounded,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    if (double.tryParse(v.trim()) == null) {
                      return 'Ungültige Zahl';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Address
              _SheetLabel('Adresse'),
              _SheetTextField(
                controller: _streetCtrl,
                hint: 'Musterstraße 1',
                prefixIcon: Icons.home_rounded,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _SheetTextField(
                      controller: _cityCtrl,
                      hint: 'Stadt',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SheetTextField(
                      controller: _postalCtrl,
                      hint: 'PLZ',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Service categories
              _SheetLabel('Fachbereiche'),
              categoriesAsync.when(
                data: (categories) => categories.isEmpty
                    ? const Text(
                        'Keine Kategorien verfügbar',
                        style: TextStyle(
                            color: AppTheme.slate400, fontSize: 13),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected =
                              _selectedCategoryIds.contains(cat.id);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSelected) {
                                _selectedCategoryIds.remove(cat.id);
                              } else if (cat.id != null) {
                                _selectedCategoryIds.add(cat.id!);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.amber.withValues(alpha: 0.15)
                                    : AppTheme.slate800,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.amber
                                      : AppTheme.slate700,
                                ),
                              ),
                              child: Text(
                                cat.nameDE ?? cat.nameEN ?? cat.slug ?? '?',
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppTheme.amber
                                      : AppTheme.slate300,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                loading: () => const SizedBox(
                  height: 32,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.amber, strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const Text(
                  'Kategorien konnten nicht geladen werden',
                  style:
                      TextStyle(color: AppTheme.slate400, fontSize: 13),
                ),
              ),

              const SizedBox(height: 28),

              // Submit button
              HWButton(
                label: 'Handwerker anlegen',
                icon: Icons.person_add_rounded,
                isLoading: createState.isLoading,
                onTap: createState.isLoading ? null : _submit,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet helpers ─────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.slate400,
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontFamily: AppTheme.bodyFont,
        fontSize: 15,
        color: AppTheme.slate100,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 15,
          color: AppTheme.slate500,
        ),
        filled: true,
        fillColor: AppTheme.slate800,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppTheme.slate500, size: 20)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.slate700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
        ),
        errorStyle: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 12,
          color: AppTheme.error,
        ),
      ),
    );
  }
}

