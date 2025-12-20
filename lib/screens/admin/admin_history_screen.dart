import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedAction;

  final List<String> _actionTypes = [
    'Все',
    'create_company',
    'update_company',
    'delete_company',
    'add_branch',
    'delete_branch',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      // Start the query builder
      var query = Supabase.instance.client
          .from('admin_logs')
          .select('*, profiles(email)'); // Returns PostgrestFilterBuilder

      // Apply filters BEFORE ordering
      if (_selectedAction != null && _selectedAction != 'Все') {
        query = query.eq('action_type', _selectedAction!);
      }

      if (_startDate != null) {
        query = query.gte('created_at', _startDate!.toIso8601String());
      }
      if (_endDate != null) {
        // Add one day to include the end date fully
        final end = _endDate!.add(const Duration(days: 1));
        query = query.lt('created_at', end.toIso8601String());
      }

      // Apply ordering LAST
      final data = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // If profiles join fails, try without it
        if (e.toString().contains('profiles')) {
          _loadLogsSimple();
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
          // Fail silently or fallback to simple load if table exists but join fails
          _loadLogsSimple();
        }
      }
    }
  }

  Future<void> _loadLogsSimple() async {
    try {
      var query = Supabase.instance.client.from('admin_logs').select();

      if (_selectedAction != null && _selectedAction != 'Все') {
        query = query.eq('action_type', _selectedAction!);
      }

      if (_startDate != null) {
        query = query.gte('created_at', _startDate!.toIso8601String());
      }
      if (_endDate != null) {
        final end = _endDate!.add(const Duration(days: 1));
        query = query.lt('created_at', end.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadLogs();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedAction = null;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История действий'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _startDate == null
                              ? 'Выберите дату'
                              : '${DateFormat('dd.MM').format(_startDate!)} - ${DateFormat('dd.MM').format(_endDate!)}',
                        ),
                        onPressed: _pickDateRange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedAction ?? 'Все',
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _actionTypes
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() => _selectedAction = val);
                          _loadLogs();
                        },
                      ),
                    ),
                  ],
                ),
                if (_startDate != null ||
                    _selectedAction != null && _selectedAction != 'Все')
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Сбросить фильтры',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),

          // List Section
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _logs.isEmpty
                    ? const Center(child: Text('История пуста'))
                    : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final date =
                            DateTime.parse(log['created_at']).toLocal();
                        final action = log['action_type'];
                        final details = log['details'];
                        final profile =
                            log.containsKey('profiles')
                                ? log['profiles']
                                : null;
                        final email =
                            profile != null ? profile['email'] : 'Admin';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading: _getIconForAction(action),
                            title: Text(details ?? action),
                            subtitle: Text(
                              '$email • ${DateFormat('dd.MM.yyyy HH:mm').format(date)}',
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _getIconForAction(String action) {
    switch (action) {
      case 'create_company':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.add, color: Colors.white),
        );
      case 'delete_company':
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.delete, color: Colors.white),
        );
      case 'update_company':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.edit, color: Colors.white),
        );
      case 'add_branch':
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.store, color: Colors.white),
        );
      case 'delete_branch':
        return const CircleAvatar(
          backgroundColor: Colors.deepOrange,
          child: Icon(Icons.remove_circle, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.history, color: Colors.white),
        );
    }
  }
}
