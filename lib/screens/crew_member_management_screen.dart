import 'package:airlines_admin/models/crew.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class CrewMemberManagementScreen extends StatefulWidget {
  const CrewMemberManagementScreen({Key? key}) : super(key: key);

  @override
  State<CrewMemberManagementScreen> createState() => _CrewMemberManagementScreenState();
}

class _CrewMemberManagementScreenState extends State<CrewMemberManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _crewMembers = [];
  bool _isLoading = true;
  int _page = 1;
  int _limit = 10;
  int _totalPages = 1;
  String? _selectedRole;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _loadCrewMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCrewMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getAllCrewMembers(
        page: _page,
        limit: _limit,
        role: _selectedRole,
      );

      if (response['success']) {
        final List crewMembersData = response['data'];

        setState(() {
          crewMembersData.sort((a, b) =>
              (a['crew_member_id'] as int).compareTo(b['crew_member_id'] as int)
          );

          _crewMembers = crewMembersData;
          _totalPages = response['pagination']['totalPages'] ?? 1;
          _isLoading = false;
          _isSearchMode = false;
        });

      } else {
        throw Exception('Failed to load crew members');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading crew members: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  // Search crew members by last name
  Future<void> _searchCrewMembers() async {
    final lastName = _searchController.text.trim();

    if (lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a last name to search'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Calling API to search for: $lastName');
      final response = await _apiService.searchCrewMembersByLastName(lastName);
      print('API response received: ${response['success']}');

      if (response['success']) {
        final List crewMembersData = response['data'] ?? [];

        setState(() {
          _crewMembers = crewMembersData;
          _isLoading = false;
          _isSearchMode = true;
        });

        // Notify if no results found
        if (crewMembersData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No crew members found with last name "$lastName"'),
              backgroundColor: AppColors.warningColor,
            ),
          );
        }
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  // Reset search and go back to paginated view
  void _resetSearch() {
    setState(() {
      _searchController.clear();
      _isSearchMode = false;
    });
    _loadCrewMembers();
  }

  Future<void> _showCrewMemberDialog({Map<String, dynamic>? crewMember}) async {
    final bool isEditing = crewMember != null;

    final TextEditingController firstNameController = TextEditingController(text: isEditing ? crewMember['first_name'] : '');
    final TextEditingController lastNameController = TextEditingController(text: isEditing ? crewMember['last_name'] : '');
    final TextEditingController licenseNumberController = TextEditingController(text: isEditing ? crewMember['license_number'] ?? '' : '');
    final TextEditingController dateOfBirthController = TextEditingController(
        text: isEditing && crewMember['date_of_birth'] != null
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(crewMember['date_of_birth']))
            : ''
    );
    final TextEditingController experienceYearsController = TextEditingController(
        text: isEditing ? crewMember['experience_years']?.toString() ?? '' : ''
    );
    final TextEditingController contactNumberController = TextEditingController(text: isEditing ? crewMember['contact_number'] ?? '' : '');
    final TextEditingController emailController = TextEditingController(text: isEditing ? crewMember['email'] ?? '' : '');

    String role = isEditing ? crewMember['role'] : 'flight_attendant';
    DateTime? selectedDate = isEditing && crewMember['date_of_birth'] != null
        ? DateTime.parse(crewMember['date_of_birth'])
        : null;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Crew Member' : 'Add New Crew Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'captain', child: Text('Captain')),
                        DropdownMenuItem(value: 'pilot', child: Text('Pilot')),
                        DropdownMenuItem(value: 'flight_attendant', child: Text('Flight Attendant')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          role = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (role == 'captain' || role == 'pilot')
                      TextField(
                        controller: licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'License Number',
                          hintText: 'e.g., XXX123456',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (role == 'captain' || role == 'pilot')
                      const SizedBox(height: 16),
                    TextField(
                      controller: dateOfBirthController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Must be at least 18
                        );

                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                            dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: experienceYearsController,
                      decoration: const InputDecoration(
                        labelText: 'Experience (Years)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contactNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        hintText: 'e.g., +1234567890',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Validate inputs
                    if (firstNameController.text.isEmpty ||
                        lastNameController.text.isEmpty ||
                        dateOfBirthController.text.isEmpty ||
                        experienceYearsController.text.isEmpty ||
                        contactNumberController.text.isEmpty ||
                        emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    // Validate license number for captains and pilots
                    if ((role == 'captain' || role == 'pilot') && licenseNumberController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('License number is required for captains and pilots'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    // Validate experience years
                    final experienceYears = int.tryParse(experienceYearsController.text);
                    if (experienceYears == null || experienceYears < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Experience years must be a valid number'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    try {
                      // Create crew member data
                      final crewMemberData = {
                        'first_name': firstNameController.text,
                        'last_name': lastNameController.text,
                        'role': role,
                        'license_number': (role == 'captain' || role == 'pilot') ? licenseNumberController.text : null,
                        'date_of_birth': dateOfBirthController.text,
                        'experience_years': experienceYears,
                        'contact_number': contactNumberController.text,
                        'email': emailController.text,
                      };

                      Navigator.of(context).pop();
                      EasyLoading.show(status: isEditing ? 'Updating crew member...' : 'Creating crew member...');

                      if (isEditing) {
                        await _apiService.updateCrewMember(crewMember!['crew_member_id'], crewMemberData);
                      } else {
                        await _apiService.createCrewMember(crewMemberData);
                      }

                      EasyLoading.dismiss();
                      _loadCrewMembers();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Crew member updated successfully' : 'Crew member created successfully'),
                          backgroundColor: AppColors.successColor,
                        ),
                      );
                    } catch (e) {
                      EasyLoading.dismiss();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCrewMember(Map<String, dynamic> crewMember) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.errorColor),
              SizedBox(width: 8),
              Text('Confirm Delete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete crew member "${crewMember['first_name']} ${crewMember['last_name']}"?'),
              SizedBox(height: 8),
              Text(
                'Crew Member Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Role: ${_formatRole(crewMember['role'])}'),
              if (crewMember['license_number'] != null)
                Text('• License: ${crewMember['license_number']}'),
              Text('• Experience: ${crewMember['experience_years']} years'),
              Text('• Assigned to ${crewMember['crew_count']} crews'),
              SizedBox(height: 12),
              Text(
                'This action cannot be undone and will remove this member from all assigned crews.',
                style: TextStyle(color: AppColors.errorColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        EasyLoading.show(status: 'Deleting crew member...');
        await _apiService.deleteCrewMember(crewMember['crew_member_id']);
        EasyLoading.dismiss();

        _loadCrewMembers();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crew member deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting crew member: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showAssignmentsDialog(Map<String, dynamic> crewMember) async {
    EasyLoading.show(status: 'Loading assignments...');

    try {
      final response = await _apiService.get('/crew-members/${crewMember['crew_member_id']}/assignments');
      EasyLoading.dismiss();

      if (!response['success']) {
        throw Exception('Failed to load crew assignments');
      }

      final List assignmentsData = response['data'];

      if (!mounted) return;

      // Use a simpler approach without DataTable2
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              width: 600, // Fixed width
              height: 500, // Fixed height
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Crew Assignments: ${crewMember['first_name']} ${crewMember['last_name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: assignmentsData.isEmpty
                        ? const Center(child: Text('This crew member is not assigned to any crews.'))
                        : ListView.builder(
                      itemCount: assignmentsData.length,
                      itemBuilder: (context, index) {
                        final assignment = assignmentsData[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              assignment['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Crew ID: #${assignment['crew_id']} | Members: ${assignment['member_count']}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: assignment['status'] == 'active'
                                    ? AppColors.successColor
                                    : assignment['status'] == 'off-duty'
                                    ? AppColors.warningColor
                                    : AppColors.infoColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                assignment['status'].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Actions
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading assignments: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'captain':
        return 'Captain';
      case 'pilot':
        return 'Pilot';
      case 'flight_attendant':
        return 'Flight Attendant';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Crew Members Management',
                  style: AppTextStyles.headline,
                ),
                Row(
                  children: [
                    // Role filter dropdown
                    DropdownButton<String?>(
                      value: _selectedRole,
                      hint: const Text('All Roles'),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Roles'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'captain',
                          child: Text('Captains'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'pilot',
                          child: Text('Pilots'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'flight_attendant',
                          child: Text('Flight Attendants'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                          _page = 1; // Reset to first page
                          _loadCrewMembers();
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showCrewMemberDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Crew Member'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search by Last Name',
                          hintText: 'Enter last name',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _searchCrewMembers(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _searchCrewMembers,
                      child: const Text('Search'),
                    ),
                    if (_isSearchMode) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _resetSearch,
                        icon: const Icon(Icons.clear),
                        label: const Text('Reset'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Crew Members Table
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _crewMembers.isEmpty
                      ? const Center(child: Text('No crew members found'))
                      : DataTable2(
                    dataRowHeight: 60, // Increase from default (48) to provide more space
                    columns: const [
                      DataColumn2(
                        label: Text('ID'),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text('Name'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Role'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('License/Experience'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Contact'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Crews'),
                        size: ColumnSize.S,
                        numeric: true,
                      ),
                      DataColumn2(
                        label: Text('Actions'),
                        size: ColumnSize.L,
                      ),
                    ],
                    rows: _crewMembers.map<DataRow>((crewMember) {
                      return DataRow(
                        cells: [
                          DataCell(Text('#${crewMember['crew_member_id']}')),
                          DataCell(Text('${crewMember['first_name']} ${crewMember['last_name']}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: crewMember['role'] == 'captain'
                                    ? AppColors.primaryColor
                                    : crewMember['role'] == 'pilot'
                                    ? AppColors.accentColor
                                    : AppColors.infoColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatRole(crewMember['role']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            crewMember['role'] == 'captain' || crewMember['role'] == 'pilot'
                                ? Text('License: ${crewMember['license_number'] ?? 'N/A'}')
                                : Text('Experience: ${crewMember['experience_years']} years'),
                          ),
                          DataCell(
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(crewMember['email'] ?? 'N/A'),
                                  Text(crewMember['contact_number'] ?? 'N/A'),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(crewMember['crew_count'].toString())),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.people, color: AppColors.primaryColor),
                                  tooltip: 'View Assignments',
                                  onPressed: () => _showAssignmentsDialog(crewMember),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.infoColor),
                                  tooltip: 'Edit Crew Member',
                                  onPressed: () => _showCrewMemberDialog(crewMember: crewMember),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.errorColor),
                                  tooltip: 'Delete Crew Member',
                                  onPressed: () => _deleteCrewMember(crewMember),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Pagination
            if (!_isSearchMode && !_isLoading && _crewMembers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Page $_page of $_totalPages'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _page > 1
                          ? () {
                        setState(() {
                          _page--;
                        });
                        _loadCrewMembers();
                      }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _page < _totalPages
                          ? () {
                        setState(() {
                          _page++;
                        });
                        _loadCrewMembers();
                      }
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}