import 'dart:typed_data';
import 'api_client.dart';
import '../entity/job.dart';

class JobsRepository {
  final ApiClient _api;
  JobsRepository(this._api);

  Future<String> createJob({
    required Uint8List bytes,
    required String filename,
    required String prompt,
  }) async {
    final j = await _api.postMultipart(
      '/api/jobs',
      fields: {'prompt': prompt},
      bytes: bytes,
      filename: filename,
    );
    return j['job_id'] as String;
  }

  Future<Job> getJob(String id) async {
    final j = await _api.get('/api/jobs/$id');
    return Job.fromJson(j as Map<String, dynamic>);
  }

  Future<List<JobListItem>> listJobs() async {
    // basit liste (sayfalama yok)
    final list = await _api.get('/api/jobs');
    if (list is Map && list['items'] != null) {
      // eğer sayfalama endpointine çevrilirse
      final arr =
          (list['items'] as List)
              .map((e) => JobListItem.fromJson(e as Map<String, dynamic>))
              .toList();
      return arr;
    }
    final arr =
        (list as List)
            .map((e) => JobListItem.fromJson(e as Map<String, dynamic>))
            .toList();
    return arr;
  }

  Future<Job> retry(String id) async {
    final j = await _api.post('/api/jobs/$id/retry');
    return Job.fromJson(j);
  }

  Future<void> deleteJob(String id) async {
    await _api.delete('/api/jobs/$id');
  }

  String downloadUrl(String id) => '$apiBase/api/jobs/$id/download';
}
