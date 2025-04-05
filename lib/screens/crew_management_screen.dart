import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/api_service.dart';
import '../models/crew.dart';
import '../utils/constants.dart';

class CrewManagementScreen extends StatefulWidget {
  const CrewManagementScreen({Key? key}) : super(key: key);

  @override
  State<CrewManagementScreen> createState() => _CrewManagementScreenState();
}

class _CrewManagementScreenState extends State<CrewManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Crew> _crews = [];
  bool _isLoading = true;
  int _page = 1;
  int _limit = 10;
  int _totalPages = 1;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadCrews();
  }

  Future<void> _loadCrews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getAllCrews(page: _page, limit: _limit);

      if (response['success']) {
        final List crewsData = response['data'];
        final crews = crewsData.map((data) => Crew.fromJson(data)).toList();
        crews.sort((a, b) => a.crewId.compareTo(b.crewId));
        setState(() {
          _crews = crews;
          _totalPages = response['pagination']['totalPages'] ?? 1;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load crews');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading crews: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _showCrewDialog({Crew? crew}) async {
    final bool isEditing = crew != null;
    final TextEditingController nameController = TextEditingController(text: isEditing ? crew.name : '');
    String status = isEditing ? crew.status : 'active';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Crew' : 'Create New Crew'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Crew Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'off-duty', child: Text('Off Duty')),
                        DropdownMenuItem(value: 'training', child: Text('Training')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          status = value!;
                        });
                      },
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
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a crew name'),
                          backgroundColor: AppColors.warningColor,
                        ),
                      );
                      return;
                    }

                    try {
                      // Create crew data
                      final crewData = {
                        'name': nameController.text,
                        'status': status,
                      };

                      Navigator.of(context).pop();
                      EasyLoading.show(status: isEditing ? 'Updating crew...' : 'Creating crew...');

                      if (isEditing) {
                        await _apiService.updateCrew(crew!.crewId, crewData);
                      } else {
                        await _apiService.createCrew(crewData);
                      }

                      EasyLoading.dismiss();
                      _loadCrews();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Crew updated successfully' : 'Crew created successfully'),
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

  Future<void> _deleteCrew(Crew crew) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete crew ${crew.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        EasyLoading.show(status: 'Deleting crew...');
        await _apiService.deleteCrew(crew.crewId);
        EasyLoading.dismiss();

        _loadCrews();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crew deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting crew: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showCrewMembersDialog(Crew crew) async {
    EasyLoading.show(status: 'Loading crew members...');

    try {
      final response = await _apiService.getCrewMembers(crew.crewId);

      EasyLoading.dismiss();

      if (!response['success']) {
        throw Exception('Failed to load crew members');
      }

      final List membersData = response['data'];

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Crew Members: ${crew.name}'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: membersData.isEmpty
                    ? const Center(child: Text('No crew members assigned to this crew yet.'))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Captains
                    const Text(
                      'Captains',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    ...membersData
                        .where((m) => m['role'] == 'captain')
                        .map((captain) => _buildCrewMemberTile(
                      captain,
                      crew.crewId,
                          () => _loadCrewMembers(crew.crewId),
                    )),
                    const SizedBox(height: 20),

                    // Pilots
                    const Text(
                      'Pilots',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    ...membersData
                        .where((m) => m['role'] == 'pilot')
                        .map((pilot) => _buildCrewMemberTile(
                      pilot,
                      crew.crewId,
                          () => _loadCrewMembers(crew.crewId),
                    )),
                    const SizedBox(height: 20),

                    // Flight Attendants
                    const Text(
                      'Flight Attendants',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    ...membersData
                        .where((m) => m['role'] == 'flight_attendant')
                        .map((attendant) => _buildCrewMemberTile(
                      attendant,
                      crew.crewId,
                          () => _loadCrewMembers(crew.crewId),
                    )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => _showAssignCrewMemberDialog(crew.crewId),
                child: const Text('Add Crew Member'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading crew members: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Widget _buildCrewMemberTile(Map<String, dynamic> member, int crewId, Function refreshCallback) {
    return ListTile(
      title: Text('${member['first_name']} ${member['last_name']}'),
      subtitle: member['license_number'] != null
          ? Text('License: ${member['license_number']} | Exp: ${member['experience_years']} years')
          : Text('Experience: ${member['experience_years']} years'),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () => _removeCrewMember(crewId, member['crew_member_id'], refreshCallback),
      ),
    );
  }

  Future<void> _removeCrewMember(int crewId, int memberId, Function refreshCallback) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Remove'),
          content: const Text('Are you sure you want to remove this crew member?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        EasyLoading.show(status: 'Removing crew member...');
        await _apiService.removeCrewMember(crewId, memberId);
        EasyLoading.dismiss();

        refreshCallback();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crew member removed successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing crew member: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadCrewMembers(int crewId) async {
    Navigator.of(context).pop(); // Close current dialog
    _showCrewMembersDialog(_crews.firstWhere((crew) => crew.crewId == crewId));
  }

  Future<void> _showAssignCrewMemberDialog(int crewId) async {
    EasyLoading.show(status: 'Loading available crew members...');

    try {
      // Get crew members already assigned to this crew
      final crewMembersResponse = await _apiService.getCrewMembers(crewId);
      final List assignedMembers = crewMembersResponse['data'] ?? [];
      final assignedMemberIds = assignedMembers.map((m) => m['crew_member_id']).toList();

      // Get all crew members
      final response = await _apiService.getAllCrewMembers(limit: 100);

      EasyLoading.dismiss();

      if (!response['success']) {
        throw Exception('Failed to load crew members');
      }

      final List allMembersData = response['data'];

      // Filter out already assigned members
      final availableMembers = allMembersData.where(
              (member) => !assignedMemberIds.contains(member['crew_member_id'])
      ).toList();

      if (availableMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available crew members to assign'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }

      if (!mounted) return;

      int? selectedMemberId;

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Assign Crew Member'),
                content: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Select Crew Member',
                    border: OutlineInputBorder(),
                  ),
                  items: availableMembers.map((member) {
                    return DropdownMenuItem<int>(
                      value: member['crew_member_id'],
                      child: Text(
                        '${member['first_name']} ${member['last_name']} (${_formatRole(member['role'])})',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMemberId = value;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (selectedMemberId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a crew member'),
                            backgroundColor: AppColors.warningColor,
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).pop();
                      await _assignCrewMember(crewId, selectedMemberId!);
                    },
                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading crew members: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _assignCrewMember(int crewId, int memberId) async {
    try {
      EasyLoading.show(status: 'Assigning crew member...');
      await _apiService.assignCrewMember(crewId, memberId);
      EasyLoading.dismiss();

      // Refresh the crew members dialog
      _loadCrewMembers(crewId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crew member assigned successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning crew member: ${e.toString()}'),
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
                  'Crew Management',
                  style: AppTextStyles.headline,
                ),
                Row(
                  children: [
                    // Status filter dropdown
                    DropdownButton<String?>(
                      value: _selectedStatus,
                      hint: const Text('All Statuses'),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'off-duty',
                          child: Text('Off Duty'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'training',
                          child: Text('Training'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue;
                          _page = 1; // Reset to first page
                          _loadCrews();
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showCrewDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Crew'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Crews Table
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _crews.isEmpty
                      ? const Center(child: Text('No crews found'))
                      : DataTable2(
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
                        label: Text('Status'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Members'),
                        size: ColumnSize.S,
                        numeric: true,
                      ),
                      DataColumn2(
                        label: Text('Aircraft'),
                        size: ColumnSize.S,
                        numeric: true,
                      ),
                      DataColumn2(
                        label: Text('Actions'),
                        size: ColumnSize.L,
                      ),
                    ],
                    rows: _crews.map((crew) {
                      return DataRow(
                        cells: [
                          DataCell(Text('#${crew.crewId}')),
                          DataCell(Text(crew.name)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: crew.status == 'active'
                                    ? AppColors.successColor
                                    : crew.status == 'off-duty'
                                    ? AppColors.warningColor
                                    : AppColors.infoColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                crew.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(crew.memberCount.toString())),
                          DataCell(Text(crew.aircraftCount.toString())),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.people, color: AppColors.primaryColor),
                                  tooltip: 'Manage Crew Members',
                                  onPressed: () => _showCrewMembersDialog(crew),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.infoColor),
                                  tooltip: 'Edit Crew',
                                  onPressed: () => _showCrewDialog(crew: crew),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.errorColor),
                                  tooltip: 'Delete Crew',
                                  onPressed: () => _deleteCrew(crew),
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
            if (!_isLoading && _crews.isNotEmpty)
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
                        _loadCrews();
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
                        _loadCrews();
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