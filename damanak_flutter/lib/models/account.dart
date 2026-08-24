enum AppStage { configuring, signedOut, onboarding, ready }

enum MemberRole { owner, manager, staff }

extension MemberRoleText on MemberRole {
  String get label => switch (this) {
    MemberRole.owner => 'المالك',
    MemberRole.manager => 'مدير',
    MemberRole.staff => 'موظف',
  };

  bool get canManageTeam =>
      this == MemberRole.owner || this == MemberRole.manager;
  bool get canManageSubscription => this == MemberRole.owner;

  static MemberRole fromValue(String? value) => switch (value) {
    'owner' => MemberRole.owner,
    'manager' => MemberRole.manager,
    _ => MemberRole.staff,
  };
}

class AccountIdentity {
  const AccountIdentity({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;
}

class StoreWorkspace {
  const StoreWorkspace({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.countryCode,
  });

  final String id;
  final String name;
  final String phone;
  final String city;
  final String countryCode;

  factory StoreWorkspace.fromJson(Map<String, dynamic> json) {
    return StoreWorkspace(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'SA',
    );
  }
}

class StoreMembership {
  const StoreMembership({
    required this.storeId,
    required this.userId,
    required this.role,
    required this.status,
  });

  final String storeId;
  final String userId;
  final MemberRole role;
  final String status;

  factory StoreMembership.fromJson(Map<String, dynamic> json) {
    return StoreMembership(
      storeId: json['store_id'] as String,
      userId: json['user_id'] as String,
      role: MemberRoleText.fromValue(json['role'] as String?),
      status: json['status'] as String? ?? 'active',
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final MemberRole role;
  final String status;
  final DateTime joinedAt;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final profile = Map<String, dynamic>.from(
      (json['profiles'] as Map?) ?? const <String, dynamic>{},
    );
    return TeamMember(
      userId: json['user_id'] as String,
      fullName:
          json['full_name'] as String? ??
          profile['full_name'] as String? ??
          'مستخدم ضمانك',
      email: json['email'] as String? ?? profile['email'] as String? ?? '',
      role: MemberRoleText.fromValue(json['role'] as String?),
      status: json['status'] as String? ?? 'active',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class StoreInvite {
  const StoreInvite({
    required this.code,
    required this.role,
    required this.expiresAt,
    required this.maxUses,
  });

  final String code;
  final MemberRole role;
  final DateTime expiresAt;
  final int maxUses;
}
