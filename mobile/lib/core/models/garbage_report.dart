enum ReportStatus {
  pending,
  assigned,
  inProgress,
  completed,
  rejected,
}

extension ReportStatusExtension on ReportStatus {
  String get value {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.assigned:
        return 'assigned';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.completed:
        return 'completed';
      case ReportStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.assigned:
        return 'Assigned';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.completed:
        return 'Completed';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  static ReportStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ReportStatus.pending;
      case 'assigned':
        return ReportStatus.assigned;
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'completed':
        return ReportStatus.completed;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }
}

class GarbageReport {
  final int id;
  final int citizenId;
  final int? collectorId;
  final String photoUrl;
  final double locationLat;
  final double locationLng;
  final String? address;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;

  GarbageReport({
    required this.id,
    required this.citizenId,
    this.collectorId,
    required this.photoUrl,
    required this.locationLat,
    required this.locationLng,
    this.address,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assignedAt,
    this.completedAt,
  });

  factory GarbageReport.fromJson(Map<String, dynamic> json) {
    return GarbageReport(
      id: json['id'] as int,
      citizenId: json['citizen_id'] as int,
      collectorId: json['collector_id'] as int?,
      photoUrl: json['photo_url'] as String,
      locationLat: (json['location_lat'] as num).toDouble(),
      locationLng: (json['location_lng'] as num).toDouble(),
      address: json['address'] as String?,
      description: json['description'] as String?,
      status: ReportStatusExtension.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizen_id': citizenId,
      'collector_id': collectorId,
      'photo_url': photoUrl,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'address': address,
      'description': description,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

class AdminStats {
  final int totalReports;
  final int pendingReports;
  final int assignedReports;
  final int inProgressReports;
  final int completedReports;
  final int totalCollectors;
  final int totalCitizens;

  AdminStats({
    required this.totalReports,
    required this.pendingReports,
    required this.assignedReports,
    required this.inProgressReports,
    required this.completedReports,
    required this.totalCollectors,
    required this.totalCitizens,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalReports: json['total_reports'] as int,
      pendingReports: json['pending_reports'] as int,
      assignedReports: json['assigned_reports'] as int,
      inProgressReports: json['in_progress_reports'] as int,
      completedReports: json['completed_reports'] as int,
      totalCollectors: json['total_collectors'] as int,
      totalCitizens: json['total_citizens'] as int,
    );
  }
}
