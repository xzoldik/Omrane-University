import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:omranefront/features/auth/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _redirecting = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      if (!_redirecting) {
        _redirecting = true;
        final navigator = Navigator.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          navigator.pushNamedAndRemoveUntil('/', (r) => false);
        });
      }
      return const SizedBox.shrink();
    }

    final isAdmin = user.role == 'admin';
    final tabs = isAdmin
        ? const [
            _NavTab('Students', Icons.people_alt_outlined, '/students'),
            _NavTab('Courses', Icons.menu_book_outlined, '/courses'),
            _NavTab('Enrollments', Icons.checklist_outlined, '/enrollments'),
            _NavTab('Payments', Icons.payments_outlined, '/payments'),
          ]
        : const [
            _NavTab('All Courses', Icons.menu_book_outlined, '/courses'),
            _NavTab('My Courses', Icons.checklist_outlined, '/my-courses'),
            _NavTab('My Payments', Icons.receipt_long_outlined, '/my-payments'),
            _NavTab(
              'My Fees',
              Icons.account_balance_wallet_outlined,
              '/my-fees',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحبا، ${user.name}'),
        actions: [
          IconButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              navigator.pushNamedAndRemoveUntil('/', (r) => false);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: ListView.separated(
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final t = tabs[i];
              return _NavCard(t: t)
                  .animate(delay: (50 * i).ms)
                  .fadeIn(begin: 0.9, duration: 200.ms)
                  .scaleXY(begin: 0.98, end: 1.0, duration: 250.ms);
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i < tabs.length) {
            Navigator.of(context).pushNamed(tabs[i].route);
          }
        },
        destinations: tabs
            .map(
              (t) => NavigationDestination(icon: Icon(t.icon), label: t.title),
            )
            .toList(),
      ),
    );
  }
}

class _NavTab {
  const _NavTab(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String route;
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.t});
  final _NavTab t;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(t.route),
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 140),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primaryContainer, scheme.surfaceContainerHighest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(t.icon, size: 36, color: scheme.primary),
                const SizedBox(height: 12),
                Text(t.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('افتح', style: TextStyle(color: scheme.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
