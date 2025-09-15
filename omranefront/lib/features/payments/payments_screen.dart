import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omranefront/features/courses/courses_service.dart';
import 'package:omranefront/features/students/students_service.dart';
import 'payments_service.dart';
import 'package:omranefront/core/navigation.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with RouteAware {
  final _service = PaymentsService();
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
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
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
        title: const Text('Payments'),
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
            builder: (_) => const _CreatePaymentDialog(),
          );
          if (created == true) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Payment recorded')));
            _refresh();
          }
        },
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Add Payment'),
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
                  child: const _PaymentSkeleton(),
                ),
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Failed to load payments: ${snapshot.error}',
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
                    Icons.payments_outlined,
                    size: 48,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: 8),
                  const Center(child: Text('No payments found')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = items[i];
                final title = '${p['studentName']} • ${p['studentNumber']}';
                final subtitle = '${p['courseName']} • ${p['courseNumber']}';
                final currency = NumberFormat.currency(
                  locale: 'ar_DZ',
                  name: 'DZD',
                  symbol: 'دج',
                );
                final amount = currency.format((p['amount'] ?? 0));
                final status = (p['status'] ?? '').toString();
                final method = (p['paymentMethod'] ?? '').toString();
                final dateRaw = (p['paymentDate'] ?? '').toString();
                final date = DateFormat(
                  'dd/MM/yyyy',
                  'ar_DZ',
                ).format(DateTime.tryParse(dateRaw) ?? DateTime.now());
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
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
                            Chip(label: Text('Amount: $amount')),
                            Chip(label: Text(method)),
                            _statusChip(status, Theme.of(context).colorScheme),
                            Chip(label: Text(date)),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        try {
                          await _service.updatePaymentStatus(
                            p['id'].toString(),
                            v,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Status updated to $v')),
                          );
                          _refresh();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'pending',
                          child: Text('Mark pending'),
                        ),
                        PopupMenuItem(
                          value: 'completed',
                          child: Text('Mark completed'),
                        ),
                        PopupMenuItem(
                          value: 'failed',
                          child: Text('Mark failed'),
                        ),
                        PopupMenuItem(
                          value: 'refunded',
                          child: Text('Mark refunded'),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert),
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
    case 'pending':
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
      break;
    case 'failed':
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
      break;
    case 'refunded':
      bg = scheme.secondaryContainer;
      fg = scheme.onSecondaryContainer;
      break;
  }
  return Chip(
    label: Text(status),
    backgroundColor: bg,
    labelStyle: TextStyle(color: fg),
  );
}

class _PaymentSkeleton extends StatelessWidget {
  const _PaymentSkeleton();
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

class _CreatePaymentDialog extends StatefulWidget {
  const _CreatePaymentDialog();
  @override
  State<_CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<_CreatePaymentDialog> {
  final _payments = PaymentsService();
  final _students = StudentsService();
  final _courses = CoursesService();
  String? _studentId;
  String? _courseId;
  final _amount = TextEditingController();
  String _method = 'cash';
  bool _loading = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _studentsList = [];
  List<Map<String, dynamic>> _coursesList = [];
  List<Map<String, dynamic>> _allPayments = [];
  double? _remaining;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final s = (await _students.getStudents()).cast<Map<String, dynamic>>();
      final c = (await _courses.getCourses()).cast<Map<String, dynamic>>();
      // For admin, we can load all payments to compute remaining balances
      final pays = (await _payments.listAll()).cast<Map<String, dynamic>>();
      setState(() {
        _studentsList = s;
        _coursesList = c;
        _allPayments = pays;
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

  void _recomputeRemaining() {
    if (_studentId == null || _courseId == null) {
      setState(() => _remaining = null);
      return;
    }
    final course = _coursesList.firstWhere(
      (c) => c['id'].toString() == _courseId,
      orElse: () => {},
    );
    final price = (course['price'] is num)
        ? (course['price'] as num).toDouble()
        : double.tryParse((course['price'] ?? '0').toString()) ?? 0.0;
    final paid = _allPayments
        .where(
          (p) =>
              p['studentId'].toString() == _studentId &&
              p['courseId'].toString() == _courseId &&
              (p['status'] ?? '').toString().toLowerCase() == 'completed',
        )
        .fold<double>(0.0, (sum, p) {
          final a = (p['amount'] is num)
              ? (p['amount'] as num).toDouble()
              : double.tryParse((p['amount'] ?? '0').toString()) ?? 0.0;
          return sum + a;
        });
    final rem = (price - paid);
    setState(() => _remaining = rem < 0 ? 0.0 : rem);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment'),
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
                      onChanged: (v) {
                        setState(() => _studentId = v);
                        _recomputeRemaining();
                      },
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
                      onChanged: (v) {
                        setState(() => _courseId = v);
                        _recomputeRemaining();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    if (_remaining != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Remaining: ${NumberFormat.currency(locale: 'ar_DZ', name: 'DZD', symbol: 'دج').format(_remaining)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Method'),
                      isExpanded: true,
                      value: _method,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(
                          value: 'transfer',
                          child: Text('Bank Transfer'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _method = v ?? _method),
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
                  final amountText = _amount.text.trim().replaceAll(',', '.');
                  if (_studentId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a student')),
                    );
                    return;
                  }
                  if (_courseId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a course')),
                    );
                    return;
                  }
                  if (double.tryParse(amountText) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  final amt = double.parse(amountText);
                  if (_remaining != null && amt > _remaining! + 1e-6) {
                    final fmt = NumberFormat.currency(
                      locale: 'ar_DZ',
                      name: 'DZD',
                      symbol: 'دج',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Amount exceeds remaining balance (${fmt.format(_remaining)})',
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _submitting = true);
                  try {
                    await _payments.createPayment(
                      courseId: _courseId!,
                      amount: amt,
                      paymentMethod: _method,
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
              : const Text('Save'),
        ),
      ],
    );
  }
}

class MyPaymentsScreen extends StatefulWidget {
  const MyPaymentsScreen({super.key});

  @override
  State<MyPaymentsScreen> createState() => _MyPaymentsScreenState();
}

class _MyPaymentsScreenState extends State<MyPaymentsScreen> with RouteAware {
  final _service = PaymentsService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.myPayments();
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
      _future = _service.myPayments();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Payments')),
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
                      'Failed to load payments: ${snapshot.error}',
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
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No payments found')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = items[i];
                final title = '${p['courseName']} • ${p['courseNumber']}';
                final amount = (p['amount'] ?? 0).toString();
                final status = (p['status'] ?? '').toString();
                final method = (p['paymentMethod'] ?? '').toString();
                final date = (p['paymentDate'] ?? '').toString();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(title),
                    subtitle: Wrap(
                      spacing: 8,
                      runSpacing: -8,
                      children: [
                        Chip(label: Text('Amount: $amount')),
                        Chip(label: Text(method)),
                        Chip(label: Text(status)),
                        Chip(label: Text(date)),
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

class MyFeesScreen extends StatefulWidget {
  const MyFeesScreen({super.key});

  @override
  State<MyFeesScreen> createState() => _MyFeesScreenState();
}

class _MyFeesScreenState extends State<MyFeesScreen> with RouteAware {
  final _service = PaymentsService();
  late Future<Map<String, dynamic>> _future;
  final _amount = TextEditingController();
  String _method = 'cash';
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _future = _service.myFees();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _amount.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.myFees();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Fees')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
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
                      'Failed to load fees: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              );
            }
            final data = snapshot.data ?? {};
            final fees = (data['outstandingFees'] as List? ?? [])
                .cast<Map<String, dynamic>>();
            final totalOwed = (data['totalOwed'] ?? 0).toString();
            if (fees.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No outstanding fees. You are all set!')),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Total Outstanding'),
                    subtitle: Text('You owe: $totalOwed'),
                  ),
                ),
                const SizedBox(height: 12),
                ...fees.map((f) {
                  final title = '${f['courseName']} • ${f['courseNumber']}';
                  final owed = (f['amountOwed'] ?? 0).toString();
                  final paid = (f['paidAmount'] ?? 0).toString();
                  final total = (f['totalFee'] ?? 0).toString();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(title),
                      subtitle: Wrap(
                        spacing: 8,
                        runSpacing: -8,
                        children: [
                          Chip(label: Text('Total: $total')),
                          Chip(label: Text('Paid: $paid')),
                          Chip(label: Text('Owed: $owed')),
                        ],
                      ),
                      trailing: IconButton(
                        tooltip: 'Pay',
                        icon: const Icon(Icons.add_card_outlined),
                        onPressed: () async {
                          _amount.text = (f['amountOwed'] ?? 0).toString();
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Make a Payment'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Course: ${f['courseName']} • ${f['courseNumber']}',
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _amount,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.,]'),
                                        ),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Amount',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Method',
                                      ),
                                      value: _method,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'cash',
                                          child: Text('Cash'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'card',
                                          child: Text('Card'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'transfer',
                                          child: Text('Bank Transfer'),
                                        ),
                                      ],
                                      onChanged: (v) => _method = v ?? _method,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: _paying
                                      ? null
                                      : () async {
                                          final txt = _amount.text
                                              .trim()
                                              .replaceAll(',', '.');
                                          if (double.tryParse(txt) == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Enter a valid amount',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          setState(() => _paying = true);
                                          try {
                                            await _service.createPayment(
                                              courseId: f['courseId']
                                                  .toString(),
                                              amount: double.parse(txt),
                                              paymentMethod: _method,
                                            );
                                            if (!context.mounted) return;
                                            Navigator.pop(context, true);
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(e.toString()),
                                              ),
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(() => _paying = false);
                                            }
                                          }
                                        },
                                  child: _paying
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Pay'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            _refresh();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
