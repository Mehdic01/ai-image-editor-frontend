import 'package:flutter/material.dart';
import '../../data/repo/jobs_repository.dart';
import '../../data/entity/job.dart';

class JobsSidebar extends StatefulWidget {
  final JobsRepository repo;
  final ValueChanged<String>? onOpen;
  final String? selectedJobId;
  final VoidCallback? onCreateNew;

  const JobsSidebar({
    super.key,
    required this.repo,
    this.onOpen,
    this.selectedJobId,
    this.onCreateNew,
  });

  @override
  State<JobsSidebar> createState() => JobsSidebarState();
}

class JobsSidebarState extends State<JobsSidebar> {
  List<JobListItem>? _items;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repo.listJobs();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Delete job'),
                content: const Text(
                  'Are you sure you want to delete this job?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!ok) return;
    try {
      await widget.repo.deleteJob(id);
      setState(() {
        _items = (_items ?? const [])
            .where((e) => e.jobId != id)
            .toList(growable: false);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'done':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25),
        border: const Border(right: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          // Create new tab
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create a new image'),
            selected: widget.selectedJobId == null,
            onTap: widget.onCreateNew,
          ),
          const Divider(height: 1),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('Error: $_error'),
        ),
      );
    }
    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(child: Text('No jobs yet'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final it = items[index];
        final prompt =
            (it.prompt == null || it.prompt!.trim().isEmpty)
                ? '(no prompt)'
                : it.prompt!;
        return ListTile(
          selected: it.jobId == widget.selectedJobId,
          title: Text(prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Row(
            children: [
              Icon(Icons.circle, size: 10, color: _statusColor(it.status)),
              const SizedBox(width: 6),
              Text(it.status),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  it.createdAt.toLocal().toString(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(it.jobId),
          ),
          onTap: widget.onOpen == null ? null : () => widget.onOpen!(it.jobId),
        );
      },
    );
  }
}
