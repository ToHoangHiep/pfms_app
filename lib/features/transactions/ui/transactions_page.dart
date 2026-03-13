import 'package:flutter/material.dart';

import '../../../data/api_client.dart';
import '../../../data/models/transaction.dart';
import 'package:firebase_auth/firebase_auth.dart';
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}
String formatMoney(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final posFromEnd = s.length - i;
    buf.write(s[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}


class _TransactionsPageState extends State<TransactionsPage> {
  final api = ApiClient();

  final TextEditingController _searchCtrl = TextEditingController();

  String filterType = 'all'; // all | income | expense
  String query = '';
  bool newestFirst = true;

  bool loading = true;
  String? error;
  List<TransactionModel> items = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await api.listTransactions();
      setState(() {
        items = data;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  int get totalIncome =>
      items.where((e) => e.type == 'income').fold(0, (s, e) => s + e.amount);

  int get totalExpense =>
      items.where((e) => e.type == 'expense').fold(0, (s, e) => s + e.amount);
  List<TransactionModel> get visibleItems {
    Iterable<TransactionModel> it = items;

    // 1) filter theo type
    if (filterType != 'all') {
      it = it.where((e) => e.type == filterType);
    }

    // 2) search theo category (CHỈ category)
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      it = it.where((e) {
        final cat = (e.category ?? '').toLowerCase();
        return cat.contains(q);
      });
    }

    // 3) sort (ưu tiên occurredAt, fallback id)
    final list = it.toList();

    int cmp(TransactionModel a, TransactionModel b) {
      final ad = (a.occurredAt ?? '').trim();
      final bd = (b.occurredAt ?? '').trim();

      // đưa rỗng xuống cuối
      if (ad.isEmpty && bd.isNotEmpty) return 1;
      if (ad.isNotEmpty && bd.isEmpty) return -1;

      final c = ad.compareTo(bd);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    }

    list.sort(cmp);
    return newestFirst ? list.reversed.toList() : list;
  }
  Future<void> _openCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _TransactionDialog(),
    );
    if (created == true) {
      await _load();
    }
  }

  Future<void> _openEditDialog(TransactionModel t) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _TransactionDialog(existing: t),
    );
    if (updated == true) {
      await _load();
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá giao dịch?'),
        content: Text('ID: $id'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await api.deleteTransaction(id);
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xoá lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () async {
              // logout Firebase => StreamBuilder ở main.dart tự đưa về AuthTestPage
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Lỗi: $error'),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Income',
                    value: totalIncome,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Expense',
                    value: totalExpense,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Filter type
                    DropdownButton<String>(
                      value: filterType,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'income', child: Text('Income')),
                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      ],
                      onChanged: (v) => setState(() => filterType = v ?? 'all'),
                    ),
                    const SizedBox(width: 12),

                    // Sort toggle
                    OutlinedButton.icon(
                      onPressed: () => setState(() => newestFirst = !newestFirst),
                      icon: Icon(newestFirst ? Icons.south : Icons.north),
                      label: Text(newestFirst ? 'Newest' : 'Oldest'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search category',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _searchCtrl.clear();
                        query = '';
                      }),
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => query = v.trim()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: () {
                final data = visibleItems;

                if (data.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('Chưa có giao dịch nào')),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = data[i];
                    final sign = t.type == 'income' ? '+' : '-';
                    return ListTile(
                      title: Text(
                        '${t.category ?? "(no category)"}  •  ${sign}${formatMoney(t.amount)}',
                      ),
                      subtitle: Text(
                        [
                          if (t.note != null && t.note!.isNotEmpty) t.note!,
                          if (t.occurredAt != null && t.occurredAt!.isNotEmpty) t.occurredAt!,
                          'id=${t.id}',
                        ].join('  |  '),
                      ),
                      onTap: () => _openEditDialog(t),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(t.id),
                      ),
                    );
                  },
                );
              }(),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(formatMoney(value), style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({this.existing});

  final TransactionModel? existing;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final api = ApiClient();

  late String type;
  final amountCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final occurredAtCtrl = TextEditingController();

  bool saving = false;
  String? err;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    type = e?.type ?? 'expense';
    amountCtrl.text = (e?.amount ?? 0).toString();
    categoryCtrl.text = e?.category ?? '';
    noteCtrl.text = e?.note ?? '';
    occurredAtCtrl.text = e?.occurredAt ?? '';
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    categoryCtrl.dispose();
    noteCtrl.dispose();
    occurredAtCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      err = null;
    });

    final amount = int.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        saving = false;
        err = 'Amount phải là số > 0';
      });
      return;
    }

    final category = categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim();
    final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
    final occurredAt = occurredAtCtrl.text.trim().isEmpty ? null : occurredAtCtrl.text.trim();

    try {
      if (widget.existing == null) {
        await api.createTransaction(
          type: type,
          amount: amount,
          category: category,
          note: note,
          occurredAt: occurredAt,
        );
      } else {
        await api.updateTransaction(
          widget.existing!.id,
          type: type,
          amount: amount,
          category: category,
          note: note,
          occurredAt: occurredAt,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        err = e.toString();
      });
    } finally {
      setState(() {
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Sửa transaction' : 'Tạo transaction'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('income')),
                  DropdownMenuItem(value: 'expense', child: Text('expense')),
                ],
                onChanged: saving ? null : (v) => setState(() => type = v ?? 'expense'),
                decoration: const InputDecoration(labelText: 'type'),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'amount'),
                enabled: !saving,
              ),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'category (vd: Ăn uống)'),
                enabled: !saving,
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'note'),
                enabled: !saving,
              ),
              TextField(
                controller: occurredAtCtrl,
                decoration: const InputDecoration(
                  labelText: 'occurredAt (ISO, vd: 2026-03-13T23:55:00)',
                ),
                enabled: !saving,
              ),
              if (err != null) ...[
                const SizedBox(height: 10),
                Text(err!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }
}