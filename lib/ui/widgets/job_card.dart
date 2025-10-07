import 'package:flutter/material.dart';
import '../../data/entity/job.dart';

class JobCard extends StatelessWidget {
  final JobListItem item;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;
  const JobCard({
    super.key,
    required this.item,
    this.onOpen,
    this.onDelete,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.jobId, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${item.status} • ${item.createdAt.toLocal()}'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(icon: const Icon(Icons.open_in_new), onPressed: onOpen),
            IconButton(icon: const Icon(Icons.refresh), onPressed: onRetry),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
