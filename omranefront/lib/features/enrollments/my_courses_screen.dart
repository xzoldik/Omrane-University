import 'package:flutter/material.dart';
import 'enrollments_service.dart';
import 'package:omranefront/core/navigation.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> with RouteAware {
  final _service = EnrollmentsService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.myCourses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.myCourses();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Failed to load courses: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              );
            }
            final items = (snapshot.data ?? []).cast<Map<String, dynamic>>();
            if (items.isEmpty) {
              final scheme = Theme.of(context).colorScheme;
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.menu_book_outlined,
                    size: 48,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('You are not enrolled in any course yet'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final e = items[i];
                final title = '${e['courseName']} • ${e['courseNumber']}';
                final subtitle =
                    'Status: ${e['status']} • Enrolled: ${e['enrollmentDate']}';
                final credits = e['credits']?.toString();
                final price = e['price']?.toString();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subtitle),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: -8,
                          children: [
                            if (credits != null)
                              Chip(label: Text('$credits cr')),
                            if (price != null) Chip(label: Text('Fee: $price')),
                          ],
                        ),
                      ],
                    ),
                    trailing: TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Unenroll from course?'),
                            content: Text('Leave ${e['courseName']}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Unenroll'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          try {
                            await _service.unenroll(
                              e['enrollmentId'].toString(),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unenrolled')),
                            );
                            _refresh();
                          } catch (err) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err.toString())),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Unenroll'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
