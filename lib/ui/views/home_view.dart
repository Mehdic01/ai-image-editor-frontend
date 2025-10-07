import 'dart:typed_data';
import 'dart:html' as html; // web için download
import 'package:flutter/material.dart';
import 'package:frontend/ui/widgets/before_after.dart';
import 'package:frontend/ui/widgets/jobs_sidebar.dart';
import 'package:frontend/ui/widgets/prompt_composer.dart';
import '../../data/repo/api_client.dart';
import '../../data/repo/jobs_repository.dart';
import '../../data/entity/job.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _repo = JobsRepository(ApiClient());
  final _sidebarKey = GlobalKey<JobsSidebarState>();
  late final TextEditingController _promptController;
  Uint8List? _bytes;
  String? _filename;
  String _prompt = '';
  String? _jobId;
  Job? _job;
  bool _loading = false;
  String? _error;
  String? _selectedJobId; // for sidebar selection

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: _prompt);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // Image picking is handled inside PromptComposer now.

  Future<void> _create() async {
    if (_bytes == null || _filename == null || _prompt.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _job = null;
      _jobId = null;
    });
    try {
      final id = await _repo.createJob(
        bytes: _bytes!,
        filename: _filename!,
        prompt: _prompt.trim(),
      );
      setState(() => _jobId = id);
      setState(() => _selectedJobId = id);
      // refresh sidebar to include the new job immediately
      _sidebarKey.currentState?.refresh();

      // polling
      for (int i = 0; i < 120; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final j = await _repo.getJob(id);
        setState(() => _job = j);
        // keep sidebar up-to-date (status changes)
        _sidebarKey.currentState?.refresh();
        if (j.status == 'done' || j.status == 'error') break;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _download() {
    if (_job?.resultUrl == null) return;
    final url = '$apiBase${_job!.resultUrl}';
    html.AnchorElement(href: url)
      ..download = url.split('/').last
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _bytes != null && _prompt.trim().isNotEmpty && !_loading;
    final resultUrl = _job?.resultUrl;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('AI Image Editor')),
      body: Row(
        children: [
          // Sidebar on the left
          JobsSidebar(
            key: _sidebarKey,
            repo: _repo,
            selectedJobId: _selectedJobId,
            onCreateNew: () {
              setState(() {
                _selectedJobId = null;
                _jobId = null;
                _job = null; // clear result
                _error = null;
                _bytes = null;
                _filename = null;
                _prompt = '';
                _promptController.clear();
                _loading = false;
              });
            },
            onOpen: (id) async {
              setState(() {
                _selectedJobId = id;
                _jobId = id;
                _loading = true;
                _error = null;
                _job = null; // clear previous result while loading new one
              });
              try {
                final j = await _repo.getJob(id);
                setState(() => _job = j);
              } catch (e) {
                setState(() => _error = e.toString());
              } finally {
                setState(() => _loading = false);
              }
            },
          ),
          // Main content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: PromptComposer(
                            initialPrompt: _prompt,
                            controller: _promptController,
                            onPromptChanged: (v) => setState(() => _prompt = v),
                            onPickImage: (bytes, filename) async {
                              setState(() {
                                _bytes = bytes;
                                _filename = filename;
                              });
                            },
                            onSend: canSubmit ? _create : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_filename != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Selected: $_filename'),
                        ),
                      if (_jobId != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Job: $_jobId'),
                        ),
                      if (_error != null)
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12),
                                ),
                                child:
                                    _bytes != null
                                        ? Image.memory(
                                          _bytes!,
                                          fit: BoxFit.contain,
                                        )
                                        : const Center(child: Text('Original')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12),
                                ),
                                child:
                                    resultUrl != null
                                        ? BeforeAfter(
                                          key: ValueKey(resultUrl),
                                          before:
                                              _bytes != null
                                                  ? Image.memory(
                                                    _bytes!,
                                                    fit: BoxFit.contain,
                                                  )
                                                  : const SizedBox(),
                                          after: Image.network(
                                            '$apiBase$resultUrl',
                                            key: ValueKey('img-$resultUrl'),
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                        : const Center(child: Text('Result')),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (resultUrl != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _download,
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
