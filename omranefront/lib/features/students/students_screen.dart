import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'students_service.dart';
import 'package:omranefront/features/auth/auth_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:omranefront/core/navigation.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> with RouteAware {
  final _service = StudentsService();
  late Future<List<dynamic>> _future;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _service.getStudents();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getStudents();
    });
    await _future;
  }

  // dispose moved above to unsubscribe

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        decoration: const InputDecoration(
          hintText: 'Search by name, email, ID',
          prefixIcon: Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.role == 'admin';
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await showDialog<bool>(
                  context: context,
                  builder: (_) => const _RegisterStudentDialog(),
                );
                if (created == true) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student registered')),
                  );
                  _refresh();
                }
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Register Student'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Shimmer skeleton list with search bar placeholder
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: 1 + 6,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  if (index == 0) return _buildSearchBar();
                  return const _StudentSkeleton();
                },
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  _buildSearchBar(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Failed to load students: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              );
            }
            final raw = snapshot.data ?? [];
            final items = raw.where((e) {
              if (_query.isEmpty) return true;
              final m = e as Map<String, dynamic>;
              final name = (m['name'] ?? '').toString().toLowerCase();
              final email = (m['email'] ?? '').toString().toLowerCase();
              final sid = (m['studentId'] ?? '').toString().toLowerCase();
              return name.contains(_query) ||
                  email.contains(_query) ||
                  sid.contains(_query);
            }).toList();

            if (raw.isEmpty) {
              final scheme = Theme.of(context).colorScheme;
              return ListView(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 80),
                  Icon(Icons.people_outline, size: 48, color: scheme.outline),
                  const SizedBox(height: 8),
                  const Center(child: Text('No students found')),
                ],
              );
            }

            if (items.isEmpty) {
              return ListView(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      _query.isEmpty
                          ? 'No students found'
                          : 'No results for "$_query"',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              itemCount: 1 + items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i == 0) return _buildSearchBar();
                final s = items[i - 1] as Map<String, dynamic>;
                final name = (s['name'] ?? '').toString();
                final email = (s['email'] ?? '').toString();
                final sid = (s['studentId'] ?? '').toString();
                final scheme = Theme.of(context).colorScheme;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text('$email • $sid'),
                    trailing: isAdmin
                        ? Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  final updated = await showDialog<bool>(
                                    context: context,
                                    builder: (_) =>
                                        _EditStudentDialog(student: s),
                                  );
                                  if (updated == true && mounted) _refresh();
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete student?'),
                                      content: Text(
                                        'This will remove $name and related enrollments/payments.',
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
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    try {
                                      await _service.deleteStudent(
                                        s['id'] as String,
                                      );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Deleted $name'),
                                        ),
                                      );
                                      _refresh();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          )
                        : null,
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

class _StudentSkeleton extends StatelessWidget {
  const _StudentSkeleton();
  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final hi = Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: hi,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const CircleAvatar(radius: 20, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(
                      height: 12,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 10,
                      width: 180,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterStudentDialog extends StatefulWidget {
  const _RegisterStudentDialog();

  @override
  State<_RegisterStudentDialog> createState() => _RegisterStudentDialogState();
}

class _RegisterStudentDialogState extends State<_RegisterStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _studentId = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _studentId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register Student'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentId,
                decoration: const InputDecoration(labelText: 'Student ID'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _loading = true);
                  try {
                    final svc = StudentsService();
                    await svc.registerStudent(
                      email: _email.text.trim(),
                      password: _password.text,
                      name: _name.text.trim(),
                      studentId: _studentId.text.trim(),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Register'),
        ),
      ],
    );
  }
}

class _EditStudentDialog extends StatefulWidget {
  const _EditStudentDialog({required this.student});
  final Map<String, dynamic> student;

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _studentId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.student['name']?.toString());
    _email = TextEditingController(text: widget.student['email']?.toString());
    _studentId = TextEditingController(
      text: widget.student['studentId']?.toString(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Student'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentId,
                decoration: const InputDecoration(labelText: 'Student ID'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _loading = true);
                  try {
                    final svc = StudentsService();
                    await svc.updateStudent(widget.student['id'] as String, {
                      'name': _name.text.trim(),
                      'email': _email.text.trim(),
                      'studentId': _studentId.text.trim(),
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
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
