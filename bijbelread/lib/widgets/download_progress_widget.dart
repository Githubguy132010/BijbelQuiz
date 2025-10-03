import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/download_task.dart';
import '../models/offline_content.dart';

/// Widget for displaying download progress
class DownloadProgressWidget extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const DownloadProgressWidget({
    super.key,
    required this.task,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.progressText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            LinearPercentIndicator(
              percent: task.progress / 100,
              lineHeight: 8,
              backgroundColor: Colors.grey[200],
              progressColor: _getProgressColor(),
              barRadius: const Radius.circular(4),
            ),

            const SizedBox(height: 8),

            // Status and time info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (task.startedAt != null)
                  Text(
                    _formatDuration(task.startedAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),

            // Error message if failed
            if (task.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build action button based on task status
  Widget _buildActionButton() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          onPressed: onPause,
          tooltip: 'Pauzeren',
          iconSize: 20,
        );
      case DownloadStatus.pending:
        return IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: onCancel,
          tooltip: 'Annuleren',
          iconSize: 20,
        );
      case DownloadStatus.paused:
        return IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: onResume,
          tooltip: 'Hervatten',
          iconSize: 20,
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onResume,
          tooltip: 'Opnieuw proberen',
          iconSize: 20,
        );
      case DownloadStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        );
    }
  }

  /// Get progress bar color based on status
  Color _getProgressColor() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.pending:
        return Colors.grey;
    }
  }

  /// Get status text
  String _getStatusText() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return 'Downloaden...';
      case DownloadStatus.pending:
        return 'Wachten op start';
      case DownloadStatus.paused:
        return 'Gepauzeerd';
      case DownloadStatus.failed:
        return 'Mislukt';
      case DownloadStatus.completed:
        return 'Voltooid';
    }
  }

  /// Get status color
  Color _getStatusColor() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.pending:
        return Colors.grey;
    }
  }

  /// Format duration for display
  String _formatDuration(DateTime startTime) {
    final now = DateTime.now();
    final difference = now.difference(startTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      return '${hours}u ${minutes}m';
    }
  }
}

/// Compact version of the download progress widget for lists
class CompactDownloadProgressWidget extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onCancel;

  const CompactDownloadProgressWidget({
    super.key,
    required this.task,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        task.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearPercentIndicator(
            percent: task.progress / 100,
            lineHeight: 4,
            backgroundColor: Colors.grey[200],
            progressColor: _getProgressColor(),
            barRadius: const Radius.circular(2),
          ),
          const SizedBox(height: 4),
          Text(
            '${task.progressText} • ${_getStatusText()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: onCancel != null
          ? IconButton(
              icon: const Icon(Icons.cancel, size: 20),
              onPressed: onCancel,
              tooltip: 'Annuleren',
            )
          : null,
    );
  }

  Color _getProgressColor() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.pending:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return 'bezig';
      case DownloadStatus.pending:
        return 'wachtend';
      case DownloadStatus.paused:
        return 'gepauzeerd';
      case DownloadStatus.failed:
        return 'mislukt';
      case DownloadStatus.completed:
        return 'voltooid';
    }
  }
}