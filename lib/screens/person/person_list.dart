import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../repository/person.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  final _repo = PeopleRepository();
  List<Person> _people = [];

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<bool> _confirmDelete(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('This will delete $name and all their entries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _loadPeople() async {
    final people = await _repo.getAllPeople();
    if (!mounted) return;
    setState(() => _people = people);
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _showAddDialog() async {
    final firstname = TextEditingController();
    final lastname = TextEditingController();
    final othername = TextEditingController();
    final phoneno = TextEditingController();
    final email = TextEditingController();
    final address = TextEditingController();
    final metAt = TextEditingController();
    DateTime? followUpDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add person'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstname,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                TextField(
                  controller: lastname,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                TextField(
                  controller: othername,
                  decoration: const InputDecoration(labelText: 'Other name'),
                ),
                TextField(
                  controller: phoneno,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: metAt,
                  decoration: const InputDecoration(labelText: 'Met at'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    followUpDate == null
                        ? 'Follow-up date'
                        : 'Follow-up: ${followUpDate!.toLocal().toString().split(' ').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: followUpDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => followUpDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && firstname.text.trim().isNotEmpty) {
      await _repo.addPerson(
        firstname: firstname.text.trim(),
        lastname: _trimmedOrNull(lastname.text),
        othername: _trimmedOrNull(othername.text),
        phoneno: _trimmedOrNull(phoneno.text),
        email: _trimmedOrNull(email.text),
        address: _trimmedOrNull(address.text),
        metAt: _trimmedOrNull(metAt.text),
        followUpDate: followUpDate,
      );
      await _loadPeople();
    }

    firstname.dispose();
    lastname.dispose();
    othername.dispose();
    phoneno.dispose();
    email.dispose();
    address.dispose();
    metAt.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Co-laborer')),
      body: _people.isEmpty
          ? const Center(child: Text('No people yet'))
          : ListView.builder(
        itemCount: _people.length,
        itemBuilder: (context, index) {
          final person = _people[index];
          final fullName = [
            person.firstname,
            person.lastname,
            person.othername,
          ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
          final details = [
            person.phoneno,
            person.email,
            person.address,
            person.metAt,
          ].whereType<String>().where((part) => part.isNotEmpty).join(' • ');
          return ListTile(
            title: Text(fullName),
            subtitle: details.isEmpty ? null : Text(details),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}