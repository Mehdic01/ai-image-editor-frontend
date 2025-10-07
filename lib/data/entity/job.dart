import 'package:equatable/equatable.dart';

class Job extends Equatable {
  final String jobId;
  final String status; // processing | done | error
  final String? resultUrl;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? prompt;

  const Job({
    required this.jobId,
    required this.status,
    this.resultUrl,
    this.error,
    required this.createdAt,
    required this.updatedAt,
    this.prompt,
  });

  factory Job.fromJson(Map<String, dynamic> j) => Job(
    jobId: j['job_id'] as String,
    status: j['status'] as String,
    resultUrl: j['result_url'] as String?,
    error: j['error'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
    prompt: j['prompt'] as String?,
  );

  @override
  List<Object?> get props => [
    jobId,
    status,
    resultUrl,
    error,
    createdAt,
    updatedAt,
    prompt,
  ];
}

class JobListItem extends Equatable {
  final String jobId;
  final String status;
  final String? resultUrl;
  final DateTime createdAt;
  final String? prompt;
  const JobListItem({
    required this.jobId,
    required this.status,
    this.resultUrl,
    required this.createdAt,
    this.prompt,
  });

  factory JobListItem.fromJson(Map<String, dynamic> j) => JobListItem(
    jobId: j['job_id'] as String,
    status: j['status'] as String,
    resultUrl: j['result_url'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    prompt: j['prompt'] as String?,
  );

  @override
  List<Object?> get props => [jobId, status, resultUrl, createdAt, prompt];
}
