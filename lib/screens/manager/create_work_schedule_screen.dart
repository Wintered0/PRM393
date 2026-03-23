import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateWorkScheduleScreen extends StatefulWidget {
  const CreateWorkScheduleScreen({super.key});

  @override
  State<CreateWorkScheduleScreen> createState() => _CreateWorkScheduleScreenState();
}

class _CreateWorkScheduleScreenState extends State<CreateWorkScheduleScreen> {
  
  
  // Form fields
  String? _selectedPosition;
  String? _selectedStaffName;
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';
  
  // Staff list based on position
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = false;
  
  // Shift options
  final List<String> _shifts = ['Morning', 'Afternoon', 'Evening'];
  
  // Position options
  final List<String> _positions = ['Manager', 'Cashier', 'Warehouse'];

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadStaffByPosition(String position) async {
    setState(() {
      _isLoading = true;
      _selectedStaffName = null;
    });
    
    try {
      final role = position == 'Warehouse' ? 'warehouse' : 
                   position == 'Cashier' ? 'cashier' : 'manager';
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();
      
      setState(() {
        _staffList = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['fullname'] ?? 'Unknown',
          ...doc.data(),
        }).toList();
        _isLoading = false;
      });
      
      // Debug: Print to console
      debugPrint('Loaded ${_staffList.length} staff for role: $role');
      for (var staff in _staffList) {
        debugPrint('Staff: ${staff['name']}, role: ${staff['role']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lá»—i táº£i danh sÃ¡ch nhÃ¢n viÃªn: $e')),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedPosition == null || _selectedStaffName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lÃ²ng chá»n vá»‹ trÃ­ vÃ  nhÃ¢n viÃªn')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // BR-04: Check for duplicate assignment
      final existingQuery = await FirebaseFirestore.instance
          .collection('work_schedules')
          .where('staffId', isEqualTo: _selectedStaffName)
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate))
          .where('shift', isEqualTo: _selectedShift)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NhÃ¢n viÃªn Ä‘Ã£ Ä‘Æ°á»£c phÃ¢n ca nÃ y rá»“i!')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // BR-02: Check consecutive shifts (max 2 per day)
      final dayShiftsQuery = await FirebaseFirestore.instance
          .collection('work_schedules')
          .where('staffId', isEqualTo: _selectedStaffName)
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate))
          .get();

      if (dayShiftsQuery.docs.length >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NhÃ¢n viÃªn Ä‘Ã£ Ä‘Æ°á»£c phÃ¢n tá»‘i Ä‘a 2 ca trong ngÃ y!')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // BR-03: Check shift quota (1 Manager, 1 Cashier, 1 Warehouse per shift)
      final shiftQuotaQuery = await FirebaseFirestore.instance
          .collection('work_schedules')
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate))
          .where('shift', isEqualTo: _selectedShift)
          .get();

      final roleMap = {
        'Manager': 'manager',
        'Cashier': 'cashier',
        'Warehouse': 'warehouse',
      };
      
      final currentRole = roleMap[_selectedPosition] ?? '';
      
      // Count existing staff in this shift by role
      final roleCount = <String, int>{};
      for (var doc in shiftQuotaQuery.docs) {
        final staffRole = doc.data()['staffRole'] as String? ?? '';
        roleCount[staffRole] = (roleCount[staffRole] ?? 0) + 1;
      }

      if ((roleCount[currentRole] ?? 0) >= 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ca $_selectedShift Ä‘Ã£ Ä‘á»§ $_selectedPosition!')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Save to Firestore
      final selectedStaff = _staffList.firstWhere(
        (s) => s['id'] == _selectedStaffName,
        orElse: () => {'id': '', 'name': ''},
      );

      await FirebaseFirestore.instance.collection('work_schedules').add({
        'staffId': _selectedStaffName,
        'staffName': selectedStaff['name'],
        'staffRole': currentRole,
        'position': _selectedPosition,
        'date': Timestamp.fromDate(_selectedDate),
        'shift': _selectedShift,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'Admin',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LÆ°u lá»‹ch thÃ nh cÃ´ng!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lá»—i lÆ°u lá»‹ch: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Táº¡o lá»‹ch lÃ m viá»‡c'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BR-01: Position (Role) Selection
            const Text(
              'Vá»‹ trÃ­ (Role) *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedPosition,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Chá»n vá»‹ trÃ­'),
              items: _positions.map((pos) => DropdownMenuItem(
                value: pos,
                child: Text(pos),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPosition = value;
                  _staffList = [];
                });
                if (value != null) {
                  _loadStaffByPosition(value);
                }
              },
            ),
            const SizedBox(height: 20),

            // Full Name (Staff) Selection
            const Text(
              'NhÃ¢n viÃªn *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedStaffName,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: _isLoading 
                  ? const Text('Äang táº£i...')
                  : _staffList.isEmpty 
                      ? const Text('KhÃ´ng cÃ³ nhÃ¢n viÃªn')
                      : const Text('Chá»n nhÃ¢n viÃªn'),
              items: _staffList.isEmpty 
                  ? []
                  : _staffList.map((staff) => DropdownMenuItem(
                value: staff['id'] as String,
                child: Text(staff['name'] as String),
              )).toList(),
              onChanged: _staffList.isEmpty ? null : (value) {
                setState(() => _selectedStaffName = value);
              },
            ),
            const SizedBox(height: 20),

            // Date Picker
            const Text(
              'NgÃ y lÃ m viá»‡c *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 20),

            // Working Shift Selection
            const Text(
              'Ca lÃ m viá»‡c *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedShift,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _shifts.map((shift) => DropdownMenuItem(
                value: shift,
                child: Text(shift),
              )).toList(),
              onChanged: (value) {
                setState(() => _selectedShift = value ?? 'Morning');
              },
            ),
            const SizedBox(height: 32),

            // Business Rules Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quy táº¯c:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('â€¢ Má»—i ca chá»‰ cÃ³ 1 Manager, 1 Cashier, 1 Warehouse', style: TextStyle(fontSize: 12)),
                  Text('â€¢ NhÃ¢n viÃªn max 2 ca/ngÃ y', style: TextStyle(fontSize: 12)),
                  Text('â€¢ KhÃ´ng trÃ¹ng ca Ä‘Ã£ phÃ¢n', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('LÆ°u lá»‹ch', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

