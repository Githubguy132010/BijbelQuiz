import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/connection_service.dart';
import '../l10n/strings_nl.dart';

/// Widget for displaying offline/connection status
class OfflineIndicator extends StatefulWidget {
  final bool showText;
  final bool showQuality;
  final double size;
  final Color? onlineColor;
  final Color? offlineColor;
  final EdgeInsetsGeometry? padding;

  const OfflineIndicator({
    super.key,
    this.showText = true,
    this.showQuality = false,
    this.size = 16,
    this.onlineColor,
    this.offlineColor,
    this.padding,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with TickerProviderStateMixin {
  late ConnectionService _connectionService;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _qualitySubscription;

  bool _isOnline = true;
  NetworkQuality _networkQuality = NetworkQuality.unknown;

  @override
  void initState() {
    super.initState();
    _connectionService = Provider.of<ConnectionService>(context, listen: false);

    _isOnline = _connectionService.isOnline;
    _networkQuality = _connectionService.networkQuality;

    _setupListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _qualitySubscription?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    _connectionSubscription = _connectionService.connectionStream.listen((isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
    });

    _qualitySubscription = _connectionService.qualityStream.listen((quality) {
      setState(() {
        _networkQuality = quality;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(theme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(theme),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Connection status icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _getStatusIcon(),
              key: ValueKey<bool>(_isOnline),
              size: widget.size,
              color: _getIconColor(theme),
            ),
          ),

          if (widget.showText) ...[
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getTextColor(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (widget.showQuality && _isOnline && _networkQuality != NetworkQuality.unknown) ...[
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getQualityColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get status icon based on connection state
  IconData _getStatusIcon() {
    if (!_isOnline) {
      return Icons.wifi_off;
    }

    switch (_networkQuality) {
      case NetworkQuality.excellent:
        return Icons.wifi;
      case NetworkQuality.good:
        return Icons.wifi;
      case NetworkQuality.fair:
        return Icons.wifi;
      case NetworkQuality.poor:
        return Icons.wifi_1_bar;
      case NetworkQuality.unknown:
        return Icons.wifi;
    }
  }

  /// Get status text
  String _getStatusText() {
    if (!_isOnline) {
      return 'Offline';
    }

    if (!widget.showQuality) {
      return 'Online';
    }

    switch (_networkQuality) {
      case NetworkQuality.excellent:
        return 'Uitstekend';
      case NetworkQuality.good:
        return 'Goed';
      case NetworkQuality.fair:
        return 'Redelijk';
      case NetworkQuality.poor:
        return 'Slecht';
      case NetworkQuality.unknown:
        return 'Online';
    }
  }

  /// Get background color
  Color _getBackgroundColor(ThemeData theme) {
    if (!_isOnline) {
      return widget.offlineColor ?? Colors.orange[50]!;
    }

    switch (_networkQuality) {
      case NetworkQuality.excellent:
        return Colors.green[50]!;
      case NetworkQuality.good:
        return Colors.lightGreen[50]!;
      case NetworkQuality.fair:
        return Colors.yellow[50]!;
      case NetworkQuality.poor:
        return Colors.red[50]!;
      case NetworkQuality.unknown:
        return Colors.blue[50]!;
    }
  }

  /// Get border color
  Color _getBorderColor(ThemeData theme) {
    if (!_isOnline) {
      return widget.offlineColor ?? Colors.orange[200]!;
    }

    switch (_networkQuality) {
      case NetworkQuality.excellent:
        return Colors.green[200]!;
      case NetworkQuality.good:
        return Colors.lightGreen[200]!;
      case NetworkQuality.fair:
        return Colors.yellow[200]!;
      case NetworkQuality.poor:
        return Colors.red[200]!;
      case NetworkQuality.unknown:
        return Colors.blue[200]!;
    }
  }

  /// Get icon color
  Color _getIconColor(ThemeData theme) {
    if (!_isOnline) {
      return widget.offlineColor ?? Colors.orange[700]!;
    }

    switch (_networkQuality) {
      case NetworkQuality.excellent:
        return Colors.green[700]!;
      case NetworkQuality.good:
        return Colors.lightGreen[700]!;
      case NetworkQuality.fair:
        return Colors.yellow[700]!;
      case NetworkQuality.poor:
        return Colors.red[700]!;
      case NetworkQuality.unknown:
        return Colors.blue[700]!;
    }
  }

  /// Get text color
  Color _getTextColor(ThemeData theme) {
    if (!_isOnline) {
      return widget.offlineColor ?? Colors.orange[700]!;
    }

    switch (_networkQuality) {
      case NetworkQuality.excellent:
        return Colors.green[700]!;
      case NetworkQuality.good:
        return Colors.lightGreen[700]!;
      case NetworkQuality.fair:
        return Colors.yellow[700]!;
      case NetworkQuality.poor:
        return Colors.red[700]!;
      case NetworkQuality.unknown:
        return Colors.blue[700]!;
    }
  }

  /// Get quality indicator color
  Color _getQualityColor() {
    switch (_networkQuality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.lightGreen;
      case NetworkQuality.fair:
        return Colors.yellow;
      case NetworkQuality.poor:
        return Colors.red;
      case NetworkQuality.unknown:
        return Colors.blue;
    }
  }
}

/// Compact offline indicator for app bars
class CompactOfflineIndicator extends StatelessWidget {
  final Color? onlineColor;
  final Color? offlineColor;

  const CompactOfflineIndicator({
    super.key,
    this.onlineColor,
    this.offlineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, child) {
        final isOnline = connectionService.isOnline;

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline
                ? (onlineColor ?? Colors.green)
                : (offlineColor ?? Colors.orange),
          ),
        );
      },
    );
  }
}

/// Floating offline indicator that appears when going offline
class FloatingOfflineIndicator extends StatefulWidget {
  final Duration showDuration;

  const FloatingOfflineIndicator({
    super.key,
    this.showDuration = const Duration(seconds: 3),
  });

  @override
  State<FloatingOfflineIndicator> createState() => _FloatingOfflineIndicatorState();
}

class _FloatingOfflineIndicatorState extends State<FloatingOfflineIndicator>
    with TickerProviderStateMixin {
  late ConnectionService _connectionService;
  StreamSubscription? _connectionSubscription;

  bool _showIndicator = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _connectionService = Provider.of<ConnectionService>(context, listen: false);

    _setupListener();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _setupListener() {
    _connectionSubscription = _connectionService.connectionStream.listen((isOnline) {
      if (!isOnline) {
        setState(() {
          _showIndicator = true;
        });

        _hideTimer?.cancel();
        _hideTimer = Timer(widget.showDuration, () {
          setState(() {
            _showIndicator = false;
          });
        });
      } else {
        setState(() {
          _showIndicator = false;
        });
        _hideTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showIndicator) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Je bent offline. Sommige functies zijn mogelijk niet beschikbaar.',
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.orange[700]),
                onPressed: () {
                  setState(() {
                    _showIndicator = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Connection status badge for overlay
class ConnectionStatusBadge extends StatelessWidget {
  final Alignment alignment;
  final bool showWhenOnline;

  const ConnectionStatusBadge({
    super.key,
    this.alignment = Alignment.topRight,
    this.showWhenOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, child) {
        final isOnline = connectionService.isOnline;

        if (isOnline && !showWhenOnline) return const SizedBox.shrink();

        return Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline ? Colors.green[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOnline ? Colors.green[300]! : Colors.orange[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: isOnline ? Colors.green[700] : Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOnline ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}