import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class StudioAvailabilityScreen extends StatefulWidget {
  final int studioId;
  final String studioName;
  const StudioAvailabilityScreen({super.key, required this.studioId, required this.studioName});

  @override
  State<StudioAvailabilityScreen> createState() => _StudioAvailabilityScreenState();
}

class _StudioAvailabilityScreenState extends State<StudioAvailabilityScreen> {
  bool _isLoading = true;
  List<dynamic> _availability = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    setState(() => _isLoading = true);
    final result = await StudioOwnerDashboardService.getAvailability(widget.studioId);
    if (mounted) {
      setState(() {
        if (result['success']) {
          _availability = result['data']['slots'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text('${widget.studioName} Availability', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSlotDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
          : _availability.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _availability.length,
                  itemBuilder: (context, index) {
                    final slot = _availability[index];
                    return _buildSlotCard(slot);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No availability slots set.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Creators can only book when you set availability.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSlotCard(dynamic slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.access_time, color: Color(0xFFE63946)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot['date'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${slot['start_time']} - ${slot['end_time']}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              // Confirm delete
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Slot?'),
                  content: const Text('Are you sure you want to remove this availability slot?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (!mounted) return;
              if (confirmed == true) {
                await StudioOwnerDashboardService.deleteAvailabilitySlot(slot['id']);
                _fetchAvailability();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSlotDialog() async {
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Availability Slot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(selectedDate == null ? 'Select Date' : 'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFFE63946)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              const Divider(),
              ListTile(
                title: Text(startTime == null ? 'Select Start Time' : 'Starts: ${startTime!.format(context)}'),
                trailing: const Icon(Icons.access_time, color: Color(0xFFE63946)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                  if (picked != null) setDialogState(() => startTime = picked);
                },
              ),
              ListTile(
                title: Text(endTime == null ? 'Select End Time' : 'Ends: ${endTime!.format(context)}'),
                trailing: const Icon(Icons.access_time, color: Color(0xFFE63946)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                  if (picked != null) setDialogState(() => endTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (selectedDate == null || startTime == null || endTime == null)
                  ? null
                  : () async {
                      final data = {
                        'date': selectedDate!.toLocal().toString().split(' ')[0],
                        'start_time': '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}',
                        'end_time': '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}',
                        'is_available': true,
                      };
                      await StudioOwnerDashboardService.saveAvailability(widget.studioId, data);
                      if (mounted) {
                        Navigator.pop(context);
                        _fetchAvailability();
                      }
                    },
              child: const Text('Add Slot'),
            ),
          ],
        ),
      ),
    );
  }

}
