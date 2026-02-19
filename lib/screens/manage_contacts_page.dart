// lib/screens/manage_contacts_page.dart
import 'package:flutter/material.dart';
// CORRECTED IMPORT PATHS
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../services/storage_service.dart';

class ManageContactsPage extends StatefulWidget {
  const ManageContactsPage({super.key});

  @override
  State<ManageContactsPage> createState() => _ManageContactsPageState();
}

class _ManageContactsPageState extends State<ManageContactsPage> {
  final _storageService = StorageService();
  List<Contact> _contacts = [];
  bool _isLoading = true;

  final List<Contact> _defaultContacts = [
    Contact(
      name: "National Emergency",
      phone: "112",
      isEmergency: true,
      relationship: "Official Service",
      notes: "All-in-one emergency number.",
    ),
    Contact(
      name: "Police",
      phone: "100",
      isEmergency: true,
      relationship: "Official Service",
    ),
    Contact(
      name: "Ambulance",
      phone: "108",
      isEmergency: true,
      relationship: "Official Service",
    ),
    Contact(
      name: "Fire Brigade",
      phone: "101",
      isEmergency: true,
      relationship: "Official Service",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final userAddedContacts = await _storageService.getAllContacts();
      if (mounted) {
        setState(() {
          _contacts = [..._defaultContacts, ...userAddedContacts];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading contacts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isDefaultContact(Contact contact) {
    return _defaultContacts.any((c) => c.phone == contact.phone);
  }

  Future<void> _addOrEditContact([Contact? existingContact]) async {
    final result = await showDialog<Contact>(
      context: context,
      builder: (context) => ContactDialog(contact: existingContact),
    );

    if (result != null) {
      try {
        if (existingContact != null) {
          // CORRECTED UPDATE LOGIC
          final updatedContact = Contact(
            id: existingContact.id,
            name: result.name,
            phone: result.phone,
            isEmergency: result.isEmergency,
            relationship: result.relationship,
            notes: result.notes,
            createdAt: existingContact.createdAt, // Preserve original creation date
          );
          await _storageService.updateContact(updatedContact);
        } else {
          await _storageService.insertContact(result);
        }
        _loadContacts(); // Refresh the list
      } catch (e) {
        // Handle error...
      }
    }
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Contact"),
        content: Text("Are you sure you want to delete ${contact.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete")),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storageService.deleteContact(contact.id!);
        _loadContacts();
      } catch (e) {
        // Handle error...
      }
    }
  }

  Future<void> _callContact(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot launch phone dialer")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Contacts"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadContacts)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Contacts: ${_contacts.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Emergency Contacts: ${_contacts.where((c) => c.isEmergency).length}", style: TextStyle(color: Colors.red.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      final bool isDefault = _isDefaultContact(contact);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: contact.isEmergency ? Colors.red.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(
                              isDefault ? Icons.shield_outlined : contact.isEmergency ? Icons.emergency : Icons.person_outline,
                              color: contact.isEmergency ? Colors.red : Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(contact.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("📱 ${contact.formattedPhone}"),
                          trailing: isDefault
                              ? IconButton(
                                  icon: const Icon(Icons.phone, color: Colors.green),
                                  tooltip: 'Call ${contact.name}',
                                  onPressed: () => _callContact(contact.phone),
                                )
                              : PopupMenuButton(
                                  onSelected: (value) {
                                    if (value == 'call') _callContact(contact.phone);
                                    if (value == 'edit') _addOrEditContact(contact);
                                    if (value == 'delete') _deleteContact(contact);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'call', child: Row(children: [Icon(Icons.phone, color: Colors.green), SizedBox(width: 8), Text('Call')])),
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Edit')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete')])),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditContact(),
        child: const Icon(Icons.add),
        tooltip: "Add Personal Contact",
      ),
    );
  }
}

// ... (Your ContactDialog and ContactsManagerBody widgets are unchanged below this line)
// The errors in those widgets were caused by the bad imports at the top of the file.
// They will now work correctly without any changes.

// Contact Dialog for Add/Edit
class ContactDialog extends StatefulWidget {
  final Contact? contact;

  const ContactDialog({super.key, this.contact});

  @override
  State<ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isEmergency = false;

  final List<String> _relationshipOptions = [
    'Family', 'Friend', 'Doctor', 'Colleague', 'Neighbor', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phone;
      _relationshipController.text = widget.contact!.relationship ?? '';
      _notesController.text = widget.contact!.notes ?? '';
      _isEmergency = widget.contact!.isEmergency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    // Allows short codes like 100, 112 as well as 10-digit numbers
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 3 && digits.length <= 10;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      widget.contact == null ? Icons.person_add : Icons.person_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.contact == null ? "Add Contact" : "Edit Contact",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Full Name *",
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Please enter name' : null,
                ),
                
                const SizedBox(height: 16),
                
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Phone Number *",
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    helperText: "e.g. 112, or a 10-digit number",
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Please enter phone number';
                    }
                    if (!_isValidPhone(value!)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Relationship Field
                DropdownButtonFormField<String>(
                  value: _relationshipController.text.isEmpty ? null : _relationshipController.text,
                  decoration: const InputDecoration(
                    labelText: "Relationship",
                    prefixIcon: Icon(Icons.group_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _relationshipOptions.map((relationship) => 
                    DropdownMenuItem(
                      value: relationship,
                      child: Text(relationship),
                    )
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _relationshipController.text = value ?? '';
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: "Notes (Optional)",
                    prefixIcon: Icon(Icons.note_outlined),
                    border: OutlineInputBorder(),
                    hintText: "Any additional information...",
                    alignLabelWithHint: true,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Emergency Contact Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isEmergency 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isEmergency 
                          ? Colors.red.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emergency,
                        color: _isEmergency ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Emergency Contact",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "This contact will receive SOS alerts",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isEmergency,
                        onChanged: (value) => setState(() => _isEmergency = value),
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final contact = Contact(
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            isEmergency: _isEmergency,
                            relationship: _relationshipController.text.trim().isEmpty 
                                ? null : _relationshipController.text.trim(),
                            notes: _notesController.text.trim().isEmpty 
                                ? null : _notesController.text.trim(),
                          );
                          Navigator.pop(context, contact);
                        }
                      },
                      child: Text(widget.contact == null ? "Add" : "Update"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Contacts Manager Body for Setup Page
class ContactsManagerBody extends StatefulWidget {
  const ContactsManagerBody({super.key});

  @override
  State<ContactsManagerBody> createState() => _ContactsManagerBodyState();
}

class _ContactsManagerBodyState extends State<ContactsManagerBody> {
  final _storageService = StorageService();
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _storageService.getAllContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    final result = await showDialog<Contact>(
      context: context,
      builder: (context) => const ContactDialog(),
    );

    if (result != null) {
      try {
        await _storageService.insertContact(result);
        _loadContacts();
      } catch (e) {
        print('Error adding contact: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Add Contact Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Emergency Contact"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              
              // Contacts List or Empty State
              Expanded(
                child: _contacts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contact_emergency_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No contacts added yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add at least one emergency contact",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: contact.isEmergency
                                    ? Colors.red.withOpacity(0.1)
                                    : Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Icon(
                                  contact.isEmergency 
                                      ? Icons.emergency 
                                      : Icons.person_outline,
                                  color: contact.isEmergency 
                                      ? Colors.red 
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                              title: Text(contact.displayName),
                              subtitle: Text(contact.formattedPhone),
                              trailing: contact.isEmergency 
                                  ? const Icon(Icons.emergency, color: Colors.red, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}