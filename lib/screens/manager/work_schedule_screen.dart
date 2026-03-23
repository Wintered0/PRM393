import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  // Filter state
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedShift;
  String? _selectedPosition;

  final List<String> _shifts = ['All', 'Morning', 'Afternoon', 'Evening'];
  final List<String> _positions = ['All', 'Manager', 'Cashier', 'Warehouse'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch làm việc'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.brown[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range
                const Text('Ngày', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Từ: ${_fromDate.day}/${_fromDate.month}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Đến: ${_toDate.day}/${_toDate.month}'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Shift Filter
                const Text('Ca làm việc', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedShift ?? 'All',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _shifts.map((shift) => DropdownMenuItem(
                    value: shift,
                    child: Text(shift == 'All' ? 'Tất cả' : shift),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedShift = value == 'All' ? null : value);
                  },
                ),
                const SizedBox(height: 16),

                // Position Filter
                const Text('Vị trí', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPosition ?? 'All',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _positions.map((pos) => DropdownMenuItem(
                    value: pos,
                    child: Text(pos == 'All' ? 'Tất cả' : pos),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPosition = value == 'All' ? null : value);
                  },
                ),
              ],
            ),
          ),

          // Schedule List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildScheduleStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final schedules = snapshot.data?.docs ?? [];

                if (schedules.isEmpty) {
                  return const Center(
                    child: Text('Không có lịch làm việc', style: TextStyle(fontSize: 16)),
                  );
                }

                // Group by date
                final groupedSchedules = <String, List<DocumentSnapshot>>{};
                for (var doc in schedules) {
                  final date = (doc.data() as Map<String, dynamic>)['date'] as Timestamp?;
                  if (date != null) {
                    final dateKey = '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
                    groupedSchedules.putIfAbsent(dateKey, () => []).add(doc);
                  }
                }

                final sortedKeys = groupedSchedules.keys.toList()
                  ..sort((a, b) {
                    final partsA = a.split('/');
                    final partsB = b.split('/');
                    final dateA = DateTime(
                      int.parse(partsA[2]), 
                      int.parse(partsA[1]), 
                      int.parse(partsA[0])
                    );
                    final dateB = DateTime(
                      int.parse(partsB[2]), 
                      int.parse(partsB[1]), 
                      int.parse(partsB[0])
                    );
                    return dateA.compareTo(dateB);
                  });

                return ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final dateKey = sortedKeys[index];
                    final daySchedules = groupedSchedules[dateKey]!;

                    // Group by shift within each day
                    final shiftGroups = <String, List<DocumentSnapshot>>{};
                    for (var doc in daySchedules) {
                      final shift = (doc.data() as Map<String, dynamic>)['shift'] as String? ?? '';
                      shiftGroups.putIfAbsent(shift, () => []).add(doc);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.brown[100],
                          width: double.infinity,
                          child: Text(
                            'Ngày $dateKey',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        ...shiftGroups.entries.map((entry) => _buildShiftSection(entry.key, entry.value)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSection(String shift, List<DocumentSnapshot> docs) {
    return ExpansionTile(
      title: Text('Ca $shift (${docs.length} người)'),
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getPositionColor(data['position'] as String? ?? ''),
            child: Text(
              (data['staffName'] as String? ?? '').substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(data['staffName'] as String? ?? ''),
          subtitle: Text(data['position'] as String? ?? ''),
          // Delete button removed - schedules cannot be deleted once assigned
        );
      }).toList(),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'Manager':
        return Colors.blue;
      case 'Cashier':
        return Colors.green;
      case 'Warehouse':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Stream<QuerySnapshot> _buildScheduleStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('work_schedules');

    // Date range filter
    query = query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_toDate));

    return query.snapshots();
  }

  Future<void> _selectDate(bool isFromDate) async {
    final initialDate = isFromDate ? _fromDate : _toDate;
    final firstDate = DateTime.now().subtract(const Duration(days: 30));
    final lastDate = DateTime.now().add(const Duration(days: 90));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = date;
          // Ensure from date is not after to date
          if (_fromDate.isAfter(_toDate)) {
            _toDate = _fromDate.add(const Duration(days: 7));
          }
        } else {
          _toDate = date;
          // Ensure to date is not before from date
          if (_toDate.isBefore(_fromDate)) {
            _fromDate = _toDate.subtract(const Duration(days: 7));
          }
        }
      });
    }
  }

  // Delete function removed - schedules cannot be deleted once assigned
}