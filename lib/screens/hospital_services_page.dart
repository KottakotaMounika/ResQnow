// lib/screens/hospital_services_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/location_service.dart';
import '../models/appointment_model.dart';
import '../services/storage_service.dart';

class HospitalServicesPage extends StatelessWidget {
  const HospitalServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Services"),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _buildServiceCard(
            context,
            icon: Icons.map_outlined,
            title: "Nearby Hospitals",
            subtitle: "Find hospitals on the map",
            onTap: () async {
              final locationResult = await LocationService.getCurrentLocation();
              locationResult.fold(
                (errorMessage) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(errorMessage)));
                  }
                },
                (position) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NearbyHospitalsMap(
                          userLocation: LatLng(
                            position.latitude,
                            position.longitude,
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
          _buildServiceCard(
            context,
            icon: Icons.calendar_today_outlined,
            title: "Book Appointment",
            subtitle: "Schedule a doctor's visit",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookAppointmentPage(),
                ),
              );
            },
          ),
          _buildServiceCard(
            context,
            icon: Icons.list_alt_outlined,
            title: "My Appointments",
            subtitle: "View and manage appointments",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyAppointmentsPage(),
                ),
              );
            },
          ),
          _buildServiceCard(
            context,
            icon: Icons.phone_in_talk_outlined,
            title: "Emergency Call",
            subtitle: "Directly call emergency services (108)",
            onTap: () async {
              final Uri callUri = Uri(scheme: 'tel', path: '108');
              if (await canLaunchUrl(callUri)) {
                await launchUrl(callUri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cannot launch phone dialer")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// Enhanced Appointment Booking Page
class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _storageService = StorageService();
  
  String _selectedDepartment = 'General';
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  final List<String> _departments = [
    'General',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'ENT',
    'Ophthalmology',
    'Psychiatry',
  ];

  final List<String> _timeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset time slot
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || 
        _selectedDate == null || 
        _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appointment = Appointment(
        patientName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        department: _selectedDepartment,
        appointmentDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        status: 'Scheduled',
      );

      await _storageService.insertAppointment(appointment);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                const Text("Appointment Confirmed"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your appointment has been successfully booked!"),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📋 Department: $_selectedDepartment", style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text("📅 Date: ${DateFormat('EEEE, MMM d, y').format(_selectedDate!)}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text("🕐 Time: $_selectedTimeSlot", style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text("📱 Contact: ${_phoneController.text}", style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Please arrive 15 minutes early. You'll receive a reminder notification.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to hospital services
                },
                child: const Text("OK"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MyAppointmentsPage()),
                  );
                },
                child: const Text("View Appointments"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error booking appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to book appointment. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Appointment"),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Patient Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Patient Information",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true
                          ? 'Please enter patient name' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                        helperText: "10-digit phone number",
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter phone number';
                        }
                        if (value!.trim().length != 10) {
                          return 'Please enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Appointment Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Appointment Details",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: "Department",
                        prefixIcon: Icon(Icons.local_hospital_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _departments.map((department) => 
                        DropdownMenuItem(
                          value: department,
                          child: Text(department),
                        )
                      ).toList(),
                      onChanged: (value) => setState(() => _selectedDepartment = value!),
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Selection
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Appointment Date",
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate == null 
                              ? 'Select Date' 
                              : DateFormat('EEEE, MMM d, y').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null 
                                ? Colors.grey.shade600 
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Time Slot Selection
                    if (_selectedDate != null) ...[
                      const Text("Available Time Slots:", style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timeSlots.map((slot) => 
                          FilterChip(
                            label: Text(slot),
                            selected: _selectedTimeSlot == slot,
                            onSelected: (selected) => setState(() => 
                              _selectedTimeSlot = selected ? slot : null
                            ),
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          )
                        ).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Additional Notes Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Additional Information",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: "Notes (Optional)",
                        prefixIcon: Icon(Icons.note_outlined),
                        border: OutlineInputBorder(),
                        hintText: "Any specific symptoms or concerns...",
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text(
                        "Book Appointment",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// My Appointments Page
class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  final _storageService = StorageService();
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final appointments = await _storageService.getAllAppointments();
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updatedAppointment = Appointment(
          id: appointment.id,
          patientName: appointment.patientName,
          phoneNumber: appointment.phoneNumber,
          department: appointment.department,
          appointmentDate: appointment.appointmentDate,
          timeSlot: appointment.timeSlot,
          createdAt: appointment.createdAt,
          status: 'Cancelled',
          notes: appointment.notes,
        );

        await _storageService.updateAppointment(updatedAppointment);
        _loadAppointments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Appointment cancelled successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error cancelling appointment: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to cancel appointment"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments"),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No appointments found",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Book your first appointment to see it here",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookAppointmentPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Book Appointment"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    final isUpcoming = appointment.appointmentDate.isAfter(DateTime.now());
                    final isCancelled = appointment.status.toLowerCase() == 'cancelled';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCancelled 
                              ? Colors.red.withOpacity(0.1)
                              : isUpcoming 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                          child: Icon(
                            isCancelled 
                                ? Icons.cancel_outlined
                                : isUpcoming 
                                    ? Icons.schedule_outlined
                                    : Icons.history_outlined,
                            color: isCancelled 
                                ? Colors.red
                                : isUpcoming 
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                        title: Text(
                          appointment.department,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("👤 ${appointment.patientName}"),
                            Text("📅 ${appointment.formattedDate} at ${appointment.timeSlot}"),
                            Text("📱 ${appointment.phoneNumber}"),
                            if (appointment.notes != null) 
                              Text("📝 ${appointment.notes}", 
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              appointment.displayStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCancelled 
                                    ? Colors.red
                                    : isUpcoming 
                                        ? Colors.green
                                        : Colors.grey,
                              ),
                            ),
                            if (isUpcoming && !isCancelled)
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'cancel',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel_outlined, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Cancel'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'cancel') {
                                    _cancelAppointment(appointment);
                                  }
                                },
                                child: const Icon(Icons.more_vert),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookAppointmentPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: "Book New Appointment",
      ),
    );
  }
}

// Nearby Hospitals Map (existing implementation)
class NearbyHospitalsMap extends StatefulWidget {
  final LatLng userLocation;
  
  const NearbyHospitalsMap({super.key, required this.userLocation});

  @override
  State<NearbyHospitalsMap> createState() => _NearbyHospitalsMapState();
}

class _NearbyHospitalsMapState extends State<NearbyHospitalsMap> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _hospitals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyHospitals();
  }

  Future<void> _fetchNearbyHospitals() async {
    // Implementation for fetching nearby hospitals from OpenStreetMap
    // This is a simplified version - you can enhance it with actual API calls
    setState(() {
      _markers = [
        Marker(
          point: widget.userLocation,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 40,
          ),
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Hospitals"),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.userLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }
}