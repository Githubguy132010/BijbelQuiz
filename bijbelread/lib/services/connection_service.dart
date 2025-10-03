import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'logger.dart';

/// Network quality enumeration
enum NetworkQuality {
  excellent, // < 100ms
  good,      // 100-300ms
  fair,      // 300-1000ms
  poor,      // > 1000ms
  unknown,
}

/// Connection information model
class ConnectionInfo {
  final bool isOnline;
  final NetworkQuality quality;
  final DateTime? lastSuccessfulRequest;
  final int consecutiveFailures;

  const ConnectionInfo({
    required this.isOnline,
    required this.quality,
    this.lastSuccessfulRequest,
    this.consecutiveFailures = 0,
  });

  /// Get localized quality string
  String getQualityString() {
    switch (quality) {
      case NetworkQuality.excellent:
        return 'Uitstekend';
      case NetworkQuality.good:
        return 'Goed';
      case NetworkQuality.fair:
        return 'Redelijk';
      case NetworkQuality.poor:
        return 'Slecht';
      case NetworkQuality.unknown:
        return 'Onbekend';
    }
  }

  /// Check if network quality is acceptable for large downloads
  bool get isGoodForDownloads =>
    quality == NetworkQuality.excellent || quality == NetworkQuality.good;

  @override
  String toString() =>
    'ConnectionInfo(online: $isOnline, quality: $quality, failures: $consecutiveFailures)';
}

/// Service to monitor network connectivity with enhanced offline detection
class ConnectionService {
  static const Duration _checkInterval = Duration(seconds: 30);
  static const Duration _qualityCheckInterval = Duration(seconds: 10);
  static const String _testUrl = 'https://www.online-bijbel.nl/api.php?action=books';

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheck;
  Timer? _qualityCheck;

  bool _isOnline = true;
  bool _isInitialized = false;
  NetworkQuality _networkQuality = NetworkQuality.unknown;
  DateTime? _lastSuccessfulRequest;
  int _consecutiveFailures = 0;

  /// Stream controllers for different types of updates
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<NetworkQuality> _qualityController = StreamController<NetworkQuality>.broadcast();
  final StreamController<ConnectionInfo> _infoController = StreamController<ConnectionInfo>.broadcast();

  /// Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<NetworkQuality> get qualityStream => _qualityController.stream;
  Stream<ConnectionInfo> get infoStream => _infoController.stream;

  /// Current connection status
  bool get isOnline => _isOnline;
  NetworkQuality get networkQuality => _networkQuality;
  ConnectionInfo get currentInfo => ConnectionInfo(
    isOnline: _isOnline,
    quality: _networkQuality,
    lastSuccessfulRequest: _lastSuccessfulRequest,
    consecutiveFailures: _consecutiveFailures,
  );

  /// Initialize the connection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('Initializing enhanced connection service...');

    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = _isConnectivityResultOnline(result);

      // Perform initial network quality check
      await _checkNetworkQuality();

      // Listen for connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        final wasOnline = _isOnline;
        _isOnline = _isConnectivityResultOnline(result);

        if (wasOnline != _isOnline) {
          AppLogger.info('Connection status changed: $_isOnline');
          _connectionController.add(_isOnline);

          // Check network quality when connectivity changes
          if (_isOnline) {
            _checkNetworkQuality();
          } else {
            _networkQuality = NetworkQuality.unknown;
            _qualityController.add(_networkQuality);
          }

          _infoController.add(currentInfo);
        }
      });

      // Start periodic connectivity checks
      _periodicCheck = Timer.periodic(_checkInterval, (_) {
        _performConnectivityCheck();
      });

      // Start network quality checks (more frequent)
      _qualityCheck = Timer.periodic(_qualityCheckInterval, (_) {
        if (_isOnline) {
          _checkNetworkQuality();
        }
      });

      _isInitialized = true;
      AppLogger.info('Enhanced connection service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize connection service: $e');
      _isOnline = false;
      _isInitialized = true;
      rethrow;
    }
  }

  /// Check if connectivity result indicates online status
  bool _isConnectivityResultOnline(List<ConnectivityResult> results) {
    if (kIsWeb) {
      // On web, we can't reliably detect connectivity, assume online
      return true;
    }

    // If any result is not none, consider online
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Perform a connectivity check
  Future<void> _performConnectivityCheck() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = _isConnectivityResultOnline(result);

      if (wasOnline != _isOnline) {
        AppLogger.info('Periodic check - Connection status changed: $_isOnline');
        _connectionController.add(_isOnline);

        if (_isOnline) {
          _checkNetworkQuality();
        }

        _infoController.add(currentInfo);
      }
    } catch (e) {
      AppLogger.warning('Periodic connectivity check failed: $e');
    }
  }

  /// Check network quality by measuring response time
  Future<void> _checkNetworkQuality() async {
    if (!_isOnline) return;

    try {
      final stopwatch = Stopwatch()..start();
      final client = http.Client();

      try {
        final response = await client.get(Uri.parse(_testUrl)).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final responseTime = stopwatch.elapsedMilliseconds;
          final newQuality = _determineNetworkQuality(responseTime);

          if (newQuality != _networkQuality) {
            _networkQuality = newQuality;
            _qualityController.add(_networkQuality);
            AppLogger.info('Network quality updated: $_networkQuality (${responseTime}ms)');
          }

          _lastSuccessfulRequest = DateTime.now();
          _consecutiveFailures = 0;
        } else {
          _handleNetworkFailure('HTTP ${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      _handleNetworkFailure(e.toString());
    }
  }

  /// Determine network quality based on response time
  NetworkQuality _determineNetworkQuality(int responseTimeMs) {
    if (responseTimeMs < 100) return NetworkQuality.excellent;
    if (responseTimeMs < 300) return NetworkQuality.good;
    if (responseTimeMs < 1000) return NetworkQuality.fair;
    return NetworkQuality.poor;
  }

  /// Handle network failure
  void _handleNetworkFailure(String reason) {
    _consecutiveFailures++;
    _networkQuality = NetworkQuality.unknown;

    AppLogger.warning('Network check failed: $reason (failures: $_consecutiveFailures)');

    // If we have too many consecutive failures, consider offline
    if (_consecutiveFailures >= 3) {
      final wasOnline = _isOnline;
      _isOnline = false;

      if (wasOnline != _isOnline) {
        _connectionController.add(_isOnline);
        AppLogger.info('Marked as offline due to consecutive failures');
      }
    }

    _qualityController.add(_networkQuality);
    _infoController.add(currentInfo);
  }

  /// Manually check current connectivity status
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _isConnectivityResultOnline(result);
      _connectionController.add(_isOnline);
      return _isOnline;
    } catch (e) {
      AppLogger.error('Manual connectivity check failed: $e');
      return false;
    }
  }

  /// Test actual connectivity with a real request
  Future<bool> testActualConnectivity() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri.parse(_testUrl)).timeout(const Duration(seconds: 5));

      final wasOnline = _isOnline;
      _isOnline = response.statusCode == 200;

      if (wasOnline != _isOnline) {
        _connectionController.add(_isOnline);
        if (_isOnline) {
          _checkNetworkQuality();
        }
      }

      client.close();
      return _isOnline;
    } catch (e) {
      _handleNetworkFailure('Test request failed: $e');
      return false;
    }
  }

  /// Get detailed connection information
  ConnectionInfo getDetailedInfo() {
    return currentInfo;
  }

  /// Check if network is suitable for large downloads
  bool get isSuitableForDownloads {
    return _isOnline && currentInfo.isGoodForDownloads;
  }

  /// Reset failure count (call when a successful request is made)
  void resetFailureCount() {
    _consecutiveFailures = 0;
    _infoController.add(currentInfo);
  }

  /// Dispose of the service
  void dispose() {
    AppLogger.info('Disposing enhanced connection service...');
    _subscription?.cancel();
    _periodicCheck?.cancel();
    _qualityCheck?.cancel();
    _connectionController.close();
    _qualityController.close();
    _infoController.close();
    _isInitialized = false;
    AppLogger.info('Enhanced connection service disposed');
  }
}