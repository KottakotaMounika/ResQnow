import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  int? _userId;

  final List<String> departments = [
    'General Medicine',
    'Cardiology',
    'Orthopedics',
    'Neurology',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'ENT',
    'Ophthalmology',
    'Psychiatry',
    'Emergency',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _userId = user['id'];
      await _loadAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final appointments = await _dbHelper.getAppointments(_userId!);
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load appointments: $e');
    }
  }

  List<Map<String, dynamic>> get _upcomingAppointments {
    final now = DateTime.now();
    return _appointments.where((apt) {
      try {
        final appointmentDate = DateTime.parse(apt['appointment_date']);
        return appointmentDate.isAfter(now.subtract(const Duration(days: 1))) && 
               apt['status'] == 'scheduled';
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> get _pastAppointments {
    final now = DateTime.now();
    return _appointments.where((apt) {
      try {
        final appointmentDate = DateTime.parse(apt['appointment_date']);
        return appointmentDate.isBefore(now.subtract(const Duration(days: 1))) || 
               apt['status'] == 'completed';
      } catch (e) {
        return apt['status'] == 'completed';
      }
    }).toList();
  }

  List<Map<String, dynamic>> get _cancelledAppointments {
    return _appointments.where((apt) => apt['status'] == 'cancelled').toList();
  }

  void _showBookAppointmentDialog() {
    final hospitalController = TextEditingController();
    final doctorController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String selectedDepartment = departments.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Appointment'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hospitalController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital/Clinic Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_hospital),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  items: departments.map((dept) => DropdownMenuItem(
                    value: dept,
                    child: Text(dept),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedDepartment = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('EEEE, MMMM dd, yyyy').format(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  trailing: const Icon(Icons.arrow_drop_down),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                  trailing: const Icon(Icons.arrow_drop_down),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Symptoms, concerns, or special requirements',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _bookAppointment(
              hospitalController.text,
              doctorController.text,
              selectedDepartment,
              selectedDate,
              selectedTime,
              notesController.text,
            ),
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }

  Future<void> _bookAppointment(
    String hospital,
    String doctor,
    String department,
    DateTime date,
    TimeOfDay time,
    String notes,
  ) async {
    if (hospital.trim().isEmpty || doctor.trim().isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    try {
      final appointmentData = {
        'user_id': _userId!,
        'hospital_name': hospital.trim(),
        'doctor_name': doctor.trim(),
        'department': department,
        'appointment_date': DateFormat('yyyy-MM-dd').format(date),
        'appointment_time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'status': 'scheduled',
        'notes': notes.trim().isEmpty ? null : notes.trim(),
      };

      await _dbHelper.insertAppointment(appointmentData);
      _showSuccessSnackBar('Appointment booked successfully');

      Navigator.pop(context);
      await _loadAppointments();
    } catch (e) {
      _showErrorSnackBar('Failed to book appointment: $e');
    }
  }

  Future<void> _updateAppointmentStatus(int appointmentId, String status) async {
    try {
      await _dbHelper.updateAppointmentStatus(appointmentId, status);
      _showSuccessSnackBar('Appointment ${status.toLowerCase()}');
      await _loadAppointments();
    } catch (e) {
      _showErrorSnackBar('Failed to update appointment: $e');
    }
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Hospital', appointment['hospital_name']),
              _buildDetailRow('Department', appointment['department']),
              _buildDetailRow('Doctor', 'Dr. ${appointment['doctor_name']}'),
              _buildDetailRow('Date', DateFormat('EEEE, MMMM dd, yyyy')
                  .format(DateTime.parse(appointment['appointment_date']))),
              _buildDetailRow('Time', appointment['appointment_time']),
              _buildDetailRow('Status', appointment['status'].toUpperCase()),
              if (appointment['notes'] != null && appointment['notes'].toString().isNotEmpty)
                _buildDetailRow('Notes', appointment['notes']),
              _buildDetailRow('Booked On', DateFormat('MMM dd, yyyy')
                  .format(DateTime.parse(appointment['created_at']))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Upcoming',
              icon: Badge(
                label: Text('${_upcomingAppointments.length}'),
                child: const Icon(Icons.upcoming),
              ),
            ),
            Tab(
              text: 'Past',
              icon: Badge(
                label: Text('${_pastAppointments.length}'),
                child: const Icon(Icons.history),
              ),
            ),
            Tab(
              text: 'Cancelled',
              icon: Badge(
                label: Text('${_cancelledAppointments.length}'),
                child: const Icon(Icons.cancel),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(_upcomingAppointments, 'upcoming'),
                _buildAppointmentsList(_pastAppointments, 'past'),
                _buildAppointmentsList(_cancelledAppointments, 'cancelled'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBookAppointmentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments, String type) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment, type);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String title;
    String subtitle;

    switch (type) {
      case 'upcoming':
        icon = Icons.upcoming;
        title = 'No Upcoming Appointments';
        subtitle = 'Book your next appointment with a doctor';
        break;
      case 'past':
        icon = Icons.history;
        title = 'No Past Appointments';
        subtitle = 'Your appointment history will appear here';
        break;
      case 'cancelled':
        icon = Icons.cancel;
        title = 'No Cancelled Appointments';
        subtitle = 'Cancelled appointments will appear here';
        break;
      default:
        icon = Icons.event_note;
        title = 'No Appointments';
        subtitle = 'Your appointments will appear here';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (type == 'upcoming') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showBookAppointmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Book Appointment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, String type) {
    final date = DateTime.parse(appointment['appointment_date']);
    final time = appointment['appointment_time'];
    final status = appointment['status'];

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['hospital_name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appointment['department'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dr. ${appointment['doctor_name']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, MMM dd, yyyy').format(date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (appointment['notes'] != null && appointment['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment['notes'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (type == 'upcoming') ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _updateAppointmentStatus(appointment['id'], 'cancelled'),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _updateAppointmentStatus(appointment['id'], 'completed'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Complete'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
