import 'dart:typed_data';
import 'dart:html' as html; // web download (Flutter Web)
import 'package:flutter/material.dart';
import 'package:frontend/ui/widgets/before_after.dart';
import 'package:frontend/ui/widgets/jobs_sidebar.dart';
import 'package:frontend/ui/widgets/prompt_composer.dart';
import 'package:frontend/ui/widgets/loading_overlay.dart';
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

  late TextEditingController _promptController;
  Uint8List? _bytes;
  String? _filename;
  String _prompt = '';
  Job? _job;
  bool _loading = false;
  bool _generating = false; // full-screen overlay during generation
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
      _job = null;
      _error = null;
    });
  }

  Future<void> _create() async {
    if (_bytes == null || _filename == null || _prompt.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _generating = true;
      _error = null;
      _job = null;
    });
    try {
      final id = await _repo.createJob(
        bytes: _bytes!,
        filename: _filename!,
        prompt: _prompt.trim(),
      );
      setState(() => _selectedJobId = id);
      _sidebarKey.currentState?.refresh();

      // Poll for status
      for (int i = 0; i < 120; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final j = await _repo.getJob(id);
        setState(() => _job = j);
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
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 900;
    final showSidebar = !isNarrow;
    final contentMaxWidth = isNarrow ? size.width - 24 : 800.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative corner backgrounds (light image), non-interactive
          Positioned(
            left: 250,
            top: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 1,
                child: Image.asset(
                  'icons/top.png',
                  width: isNarrow ? 140 : 600,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'icons/down.png',
                width: isNarrow ? 160 : 600,
                fit: BoxFit.fill,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSidebar)
                JobsSidebar(
                  key: _sidebarKey,
                  repo: _repo,
                  width: 250,
                  selectedJobId: _selectedJobId,
                  onCreateNew: () {
                    setState(() {
                      _selectedJobId = null;
                      _job = null;
                      _error = null;
                      _bytes = null;
                      _filename = null;
                      _prompt = '';
                      _promptController.text = '';
                    });
                  },
                  onOpen: (id) async {
                    setState(() {
                      _selectedJobId = id;
                      _job = null;
                      _error = null;
                      _bytes = null;
                      _filename = null;
                      _prompt = '';
                      _promptController.text = '';
                    });
                    try {
                      final j = await _repo.getJob(id);
                      if (!mounted) return;
                      setState(() => _job = j);
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _error = e.toString());
                    }
                  },
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12 : 16,
                    vertical: isNarrow ? 8 : 16,
                  ),
                  child: SizedBox(
                    height: size.height,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Top: result image box (if any)
                        if (resultUrl != null)
                          Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: contentMaxWidth,
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: isNarrow ? 8 : 16,
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 260,
                                    maxHeight: 420,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: BeforeAfter(
                                          key: ValueKey(resultUrl),
                                          before:
                                              _bytes != null
                                                  ? Image.memory(
                                                    _bytes!,
                                                    fit: BoxFit.contain,
                                                  )
                                                  : const Center(
                                                    child: Text(''),
                                                  ),
                                          after: Image.network(
                                            '$apiBase$resultUrl',
                                            key: ValueKey('img-$resultUrl'),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.grey.shade300,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed: _download,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                            icon: const Icon(
                                              Icons.download,
                                              color: Colors.black,
                                            ),
                                            tooltip: 'Download',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Center: Prompt composer (always centered)
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: contentMaxWidth * 1.2,
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

                        // Bottom: uploaded image preview (if any)
                        if (_bytes != null)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: contentMaxWidth,
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: isNarrow ? 12 : 16,
                                ),
                                child: SizedBox(
                                  height: isNarrow ? 200 : 240,
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
                          ),

                        if (_error != null)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    (_bytes != null
                                        ? (isNarrow ? 200 : 240)
                                        : 0) +
                                    (isNarrow ? 24 : 28),
                              ),
                              child: Text(
                                'Error: $_error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_generating)
            const Positioned.fill(
              child: LoadingOverlay(
                title: 'Generating your image',
                subtitle: 'This may take a few seconds',
              ),
            ),
        ],
      ),
    );
  }
}
