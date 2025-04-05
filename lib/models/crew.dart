class Crew {
  final int crewId;
  final String name;
  final String status;
  final int memberCount;
  final int aircraftCount;
  final List<CrewMember>? members;

  Crew({
    required this.crewId,
    required this.name,
    required this.status,
    required this.memberCount,
    required this.aircraftCount,
    this.members,
  });

  factory Crew.fromJson(Map<String, dynamic> json) {
    // Parse crew members if present
    List<CrewMember>? crewMembers;
    if (json['members'] != null) {
      crewMembers = (json['members'] as List)
          .map((member) => CrewMember.fromJson(member))
          .toList();
    }

    return Crew(
      crewId: json['crew_id'] ?? 0,
      name: json['name'] ?? 'Unknown Crew',
      status: json['status'] ?? 'active',
      memberCount: json['member_count'] ?? 0,
      aircraftCount: json['aircraft_count'] ?? 0,
      members: crewMembers,
    );
  }
}

class CrewMember {
  final int crewMemberId;
  final String firstName;
  final String lastName;
  final String role;
  final String? licenseNumber;
  final int experienceYears;

  CrewMember({
    required this.crewMemberId,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.licenseNumber,
    required this.experienceYears,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      crewMemberId: json['crew_member_id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? '',
      licenseNumber: json['license_number'],
      experienceYears: json['experience_years'] ?? 0,
    );
  }

  String get fullName => '$firstName $lastName';

  String get roleDisplay {
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
}