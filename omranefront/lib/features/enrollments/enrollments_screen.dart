import 'package:flutter/material.dart';
import 'package:omranefront/features/courses/courses_service.dart';
import 'package:omranefront/features/students/students_service.dart';
import 'enrollments_service.dart';
import 'package:omranefront/core/navigation.dart';
import 'package:shimmer/shimmer.dart';

class EnrollmentsScreen extends StatefulWidget {
  const EnrollmentsScreen({super.key});

  @override
  State<EnrollmentsScreen> createState() => _EnrollmentsScreenState();
}

class _EnrollmentsScreenState extends State<EnrollmentsScreen> with RouteAware {
  final _service = EnrollmentsService();
  late Future<List<dynamic>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.listAll();
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
      _future = _service.listAll();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollments'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by student or course',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => const _EnrollDialog(),
          );
          if (created == true) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Enrollment created')));
            _refresh();
          }
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Enroll Student'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              final scheme = Theme.of(context).colorScheme;
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, __) => Shimmer.fromColors(
                  baseColor: scheme.surfaceContainerHighest,
                  highlightColor: scheme.surface,
                  child: const _EnrollSkeleton(),
                ),
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Failed to load enrollments: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              );
            }
            var items = (snapshot.data ?? []).cast<Map<String, dynamic>>();
            if (_query.isNotEmpty) {
              items = items.where((e) {
                final sName = (e['studentName'] ?? '').toString().toLowerCase();
                final cName = (e['courseName'] ?? '').toString().toLowerCase();
                final cNum = (e['courseNumber'] ?? '').toString().toLowerCase();
                final sNum = (e['studentNumber'] ?? '')
                    .toString()
                    .toLowerCase();
                return sName.contains(_query) ||
                    cName.contains(_query) ||
                    cNum.contains(_query) ||
                    sNum.contains(_query);
              }).toList();
            }

            if (items.isEmpty) {
              final scheme = Theme.of(context).colorScheme;
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.playlist_add_check_circle_outlined,
                    size: 48,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: 8),
                  const Center(child: Text('No enrollments found')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final e = items[i];
                final title = '${e['studentName']} • ${e['studentNumber']}';
                final subtitle = '${e['courseName']} • ${e['courseNumber']}';
                final status = (e['status'] ?? '').toString();
                final grade = e['grade'];
                final date = (e['enrollmentDate'] ?? '').toString();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.checklist_outlined),
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
                            _statusChip(status, Theme.of(context).colorScheme),
                            if (grade != null)
                              Chip(label: Text('Grade: $grade')),
                            Chip(label: Text(date)),
                          ],
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Edit status/grade',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            final updated = await showDialog<bool>(
                              context: context,
                              builder: (_) =>
                                  _EditEnrollmentDialog(enrollment: e),
                            );
                            if (updated == true) _refresh();
                          },
                        ),
                        IconButton(
                          tooltip: 'Unenroll',
                          icon: const Icon(Icons.person_remove_alt_1_outlined),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Unenroll student?'),
                                content: Text(
                                  'Remove ${e['studentName']} from ${e['courseName']}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Unenroll'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              try {
                                await _service.unenroll(e['id'].toString());
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
                        ),
                      ],
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

Widget _statusChip(String status, ColorScheme scheme) {
  Color bg = scheme.surfaceContainerHighest;
  Color fg = scheme.onSurface;
  switch (status.toLowerCase()) {
    case 'completed':
      bg = scheme.primaryContainer;
      fg = scheme.onPrimaryContainer;
      break;
    case 'enrolled':
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
      break;
    case 'dropped':
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
      break;
  }
  return Chip(
    label: Text(status),
    backgroundColor: bg,
    labelStyle: TextStyle(color: fg),
  );
}

class _EnrollSkeleton extends StatelessWidget {
  const _EnrollSkeleton();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(width: 36, height: 36, color: Colors.white),
        title: Container(height: 14, color: Colors.white),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Container(height: 12, color: Colors.white),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: const [_SkChip(), _SkChip(), _SkChip()]),
          ],
        ),
      ),
    );
  }
}

class _SkChip extends StatelessWidget {
  const _SkChip();
  @override
  Widget build(BuildContext context) {
    return Container(width: 80, height: 24, color: Colors.white);
  }
}

class _EnrollDialog extends StatefulWidget {
  const _EnrollDialog();

  @override
  State<_EnrollDialog> createState() => _EnrollDialogState();
}

class _EnrollDialogState extends State<_EnrollDialog> {
  final _enrollments = EnrollmentsService();
  final _students = StudentsService();
  final _courses = CoursesService();

  String? _studentId;
  String? _courseId;
  bool _loading = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _studentsList = [];
  List<Map<String, dynamic>> _coursesList = [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final s = (await _students.getStudents()).cast<Map<String, dynamic>>();
      final c = (await _courses.getCourses()).cast<Map<String, dynamic>>();
      setState(() {
        _studentsList = s;
        _coursesList = c;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enroll Student'),
      content: _loading
          ? const SizedBox(
              width: 220,
              height: 90,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Student'),
                      isExpanded: true,
                      value: _studentId,
                      items: _studentsList
                          .map(
                            (s) => DropdownMenuItem(
                              value: s['id'].toString(),
                              child: Text(
                                '${s['name']} • ${s['studentId']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _studentId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Course'),
                      isExpanded: true,
                      value: _courseId,
                      items: _coursesList
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(
                                '${c['name']} • ${c['courseNumber']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _courseId = v),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  if (_studentId == null || _courseId == null) return;
                  setState(() => _submitting = true);
                  try {
                    await _enrollments.enroll(
                      courseId: _courseId!,
                      studentId: _studentId,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (mounted) setState(() => _submitting = false);
                  }
                },
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enroll'),
        ),
      ],
    );
  }
}

class _EditEnrollmentDialog extends StatefulWidget {
  const _EditEnrollmentDialog({required this.enrollment});
  final Map<String, dynamic> enrollment;

  @override
  State<_EditEnrollmentDialog> createState() => _EditEnrollmentDialogState();
}

class _EditEnrollmentDialogState extends State<_EditEnrollmentDialog> {
  final _service = EnrollmentsService();
  final _formKey = GlobalKey<FormState>();
  late String _status;
  final _gradeController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.enrollment['status']?.toString() ?? 'enrolled';
    final g = widget.enrollment['grade'];
    if (g != null) _gradeController.text = g.toString();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Enrollment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: _status,
              items: const [
                DropdownMenuItem(value: 'enrolled', child: Text('enrolled')),
                DropdownMenuItem(value: 'completed', child: Text('completed')),
                DropdownMenuItem(value: 'dropped', child: Text('dropped')),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gradeController,
              decoration: const InputDecoration(labelText: 'Grade (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    final grade = _gradeController.text.trim().isEmpty
                        ? null
                        : _gradeController.text.trim();
                    await _service.update(
                      widget.enrollment['id'].toString(),
                      status: _status,
                      grade: grade,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
