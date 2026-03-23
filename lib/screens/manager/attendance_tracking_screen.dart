import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceTrackingScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const AttendanceTrackingScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<AttendanceTrackingScreen> createState() => _AttendanceTrackingScreenState();
}

class _AttendanceTrackingScreenState extends State<AttendanceTrackingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedShift;

  final List<String> _shifts = ['All', 'Morning', 'Afternoon', 'Evening'];

  // Shift time definitions
  final Map<String, Map<String, int>> _shiftTimes = {
    'Morning': {'start': 7, 'end': 12},
    'Afternoon': {'start': 13, 'end': 18},
    'Evening': {'start': 18, 'end': 22},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi chấm công'),
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
                // Date Picker
                const Text('Ngày', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Shift Filter
                const Text('Ca làm việc', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedShift ?? 'All',
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
              ],
            ),
          ),

          // Attendance List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildScheduleStream(),
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final schedules = scheduleSnapshot.data?.docs ?? [];

                if (schedules.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có lịch làm việc cho ngày này',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                // Filter by shift if selected
                var filteredSchedules = schedules;
                if (_selectedShift != null) {
                  filteredSchedules = schedules.where((doc) {
                    final shift = (doc.data() as Map<String, dynamic>)['shift'] as String? ?? '';
                    return shift == _selectedShift;
                  }).toList();
                }

                if (filteredSchedules.isEmpty) {
                  return Center(
                      child: Text(
                        'Không có lịch cho ca $_selectedShift',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredSchedules.length,
                  itemBuilder: (context, index) {
                    final scheduleDoc = filteredSchedules[index];
                    final scheduleData = scheduleDoc.data() as Map<String, dynamic>;
                    return _buildStaffCard(scheduleData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildScheduleStream() {
    // Get start and end of selected date
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('work_schedules')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();
  }

  Widget _buildStaffCard(Map<String, dynamic> scheduleData) {
    final staffId = scheduleData['staffId'] as String? ?? '';
    final staffName = scheduleData['staffName'] as String? ?? 'Unknown';
    final position = scheduleData['position'] as String? ?? '';
    final shift = scheduleData['shift'] as String? ?? '';
    final shiftStart = _shiftTimes[shift]?['start'] ?? 7;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('checkin_checkout')
          .doc('${staffId}__${_formatDateKey(_selectedDate)}')
          .get(),
      builder: (context, snapshot) {
        DateTime? checkInTime;
        DateTime? checkOutTime;
        String status = 'Absent';

        if (snapshot.hasData && snapshot.data!.exists) {
          final checkInData = snapshot.data!.data() as Map<String, dynamic>?;
          if (checkInData != null) {
            final firstCheckIn = checkInData['firstCheckInAt'] as Timestamp?;
            final lastEvent = checkInData['latestEventAt'] as Timestamp?;
            final hasCheckout = checkInData['hasCheckout'] as bool? ?? false;

            if (firstCheckIn != null) {
              checkInTime = firstCheckIn.toDate();
              
              // BR-02: Lateness Threshold - Late if > 5 minutes past shift start
              final thresholdMinute = shiftStart + 0.083; // 5 minutes = 0.083 hours
              if (checkInTime.hour + checkInTime.minute / 60 <= thresholdMinute) {
                status = 'On Time';
              } else {
                status = 'Late';
              }
            }

            if (lastEvent != null && hasCheckout) {
              checkOutTime = lastEvent.toDate();
              status = status == 'Absent' ? 'Absent' : 'Checked Out';
            }
          }
        }

        // BR-05: Check if shift started but no check-in (Absent)
        final now = DateTime.now();
        final shiftStartTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, shiftStart);
        if (now.isAfter(shiftStartTime.add(const Duration(minutes: 30))) && status == 'Absent') {
          status = 'Absent';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Name and Role
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getPositionColor(position),
                      child: Text(
                        staffName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staffName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            position,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const Divider(height: 24),

                // Schedule Time
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Lịch: ${_getShiftTime(shift)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Check-in Time
                Row(
                  children: [
                    Icon(
                      status == 'Absent' ? Icons.warning : Icons.login,
                      size: 20,
                      color: status == 'Absent' ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Check-in: ${checkInTime != null ? '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}' : '--:--'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: status == 'Late' ? Colors.orange : (status == 'Absent' ? Colors.red : Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Check-out Time
                if (checkOutTime != null)
                  Row(
                    children: [
                      const Icon(Icons.logout, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Check-out: ${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'On Time':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Late':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'Absent':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'Checked Out':
        color = Colors.blue;
        icon = Icons.logout;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
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

  String _getShiftTime(String shift) {
    switch (shift) {
      case 'Morning':
        return '07:00 - 12:00';
      case 'Afternoon':
        return '13:00 - 18:00';
      case 'Evening':
        return '18:00 - 22:00';
      default:
        return '--:--';
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }
}
