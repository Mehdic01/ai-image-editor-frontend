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
  bool _generating = false; // only for full-screen overlay during generation
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

  void _clearImage() {
    setState(() {
      _bytes = null;
      _filename = null;
      _jobId = null;
      _job = null;
      _error = null;
    });
  }

  // image picking handled via PromptComposer.onPickImage

  Future<void> _create() async {
    if (_bytes == null || _filename == null || _prompt.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _generating = true;
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
      setState(() {
        _loading = false;
        _generating = false;
      });
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
      body: Stack(
        children: [
          Row(
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
                    // Also clear compose state (prompt + uploaded image)
                    _bytes = null;
                    _filename = null;
                    _prompt = '';
                    _promptController.clear();
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
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Slider area above the composer
                            Container(
                              constraints: const BoxConstraints(
                                minHeight: 260,
                                maxHeight: 420,
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Builder(
                                builder: (_) {
                                  final resultUrl = _job?.resultUrl;
                                  if (resultUrl != null) {
                                    return BeforeAfter(
                                      key: ValueKey(resultUrl),
                                      before:
                                          _bytes != null
                                              ? Image.memory(
                                                _bytes!,
                                                fit: BoxFit.contain,
                                              )
                                              : const Center(
                                                child: Text('Original'),
                                              ),
                                      after: Image.network(
                                        '$apiBase$resultUrl',
                                        key: ValueKey('img-$resultUrl'),
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  }
                                  return const Center(
                                    child: Text('Result will appear here'),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Composer with circular buttons inside the field
                            Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: PromptComposer(
                                  controller: _promptController,
                                  initialPrompt: _prompt,
                                  onPromptChanged:
                                      (v) => setState(() => _prompt = v),
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
                            const SizedBox(height: 12),
                            // Uploaded image preview under the textfield
                            if (_bytes != null)
                              Align(
                                alignment: Alignment.center,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 800,
                                  ),
                                  child: SizedBox(
                                    height: 240,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.black12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Center(
                                              child: Image.memory(
                                                _bytes!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.black54,
                                            child: IconButton(
                                              tooltip: 'Remove image',
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                              ),
                                              onPressed: _clearImage,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                            // The main two-panel row is replaced by the slider above.
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
              ),
            ],
          ),
          if (_generating) Positioned.fill(child: _LoadingOverlay()),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatefulWidget {
  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Container(
        color: Colors.white.withOpacity(0.92),
        child: Center(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              return Transform.scale(
                scale: _pulse.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(height: 4),
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 16),
                      Text(
                        'Generating your image...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'This can take a few seconds',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
