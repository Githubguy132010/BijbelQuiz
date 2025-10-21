import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import '../services/logger.dart';
import '../models/quiz_question.dart';
import '../providers/game_stats_provider.dart';
import '../providers/lesson_progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/question_cache_service.dart';

/// Service for running a local HTTP API server
class ApiService {
  static const String _defaultBindAddress = '0.0.0.0';
  static const String _apiVersion = 'v1';
  static const int _maxRequestsPerMinute = 100;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  HttpServer? _server;
  bool _isRunning = false;
  final Map<String, List<DateTime>> _requestLog = {};

  /// Whether the API server is currently running
  bool get isRunning => _isRunning;

  /// Gets the current server port if running
  int? get currentPort => _server?.port;

  /// Gets the server address if running
  String? get serverAddress => _server?.address.host;

  /// Clean up old rate limit entries periodically
  Timer? _cleanupTimer;

  /// Start the cleanup timer for rate limiting
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _cleanupOldRequests();
    });
  }

  /// Stop the cleanup timer
  void _stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Clean up old request entries for rate limiting
  void _cleanupOldRequests() {
    final now = DateTime.now();
    final cutoff = now.subtract(_rateLimitWindow);

    _requestLog.removeWhere((ip, requests) {
      requests.removeWhere((timestamp) => timestamp.isBefore(cutoff));
      return requests.isEmpty;
    });
  }

  /// Starts the API server on the specified port with authentication
  Future<void> startServer({
    required int port,
    required String apiKey,
    required SettingsProvider settingsProvider,
    required GameStatsProvider gameStatsProvider,
    required LessonProgressProvider lessonProgressProvider,
    required QuestionCacheService questionCacheService,
  }) async {
    if (_isRunning) {
      AppLogger.warning('API server is already running');
      return;
    }

    try {
      AppLogger.info('Starting API server on port $port...');

      final app = shelf_router.Router()
        ..get('/$_apiVersion/health', _handleHealth)
        ..get('/$_apiVersion/questions', _handleGetQuestions(questionCacheService))
        ..get('/$_apiVersion/questions/<category>', _handleGetQuestionsByCategory(questionCacheService))
        ..get('/$_apiVersion/progress', _handleGetProgress(lessonProgressProvider))
        ..get('/$_apiVersion/stats', _handleGetStats(gameStatsProvider))
        ..get('/$_apiVersion/settings', _handleGetSettings(settingsProvider));

      final handler = const Pipeline()
          .addMiddleware(_createSecurityHeadersMiddleware())
          .addMiddleware(_createRateLimitingMiddleware())
          .addMiddleware(_createPublicEndpointMiddleware(apiKey))
          .addMiddleware(_createCorsMiddleware())
          .addMiddleware(_createValidationMiddleware())
          .addMiddleware(_createLoggingMiddleware())
          .addHandler(app);

      _server = await shelf_io.serve(handler, _defaultBindAddress, port);
      _isRunning = true;
      _startCleanupTimer();

      AppLogger.info('API server started successfully on ${_server!.address.host}:${_server!.port}');
      AppLogger.info('API server is accessible at http://localhost:$port/$_apiVersion and http://${_server!.address.host}:$port/$_apiVersion');
    } catch (e) {
      AppLogger.error('Failed to start API server: $e');
      _isRunning = false;
      throw Exception('Failed to start API server: $e');
    }
  }

  /// Stops the API server
  Future<void> stopServer() async {
    if (!_isRunning || _server == null) {
      AppLogger.info('API server stop requested but server is not running');
      return;
    }

    try {
      AppLogger.info('Stopping API server...');
      _stopCleanupTimer();
      await _server!.close(force: true); // Force close to ensure cleanup
      _isRunning = false;
      _server = null;
      _requestLog.clear();
      AppLogger.info('API server stopped successfully');
    } catch (e) {
      AppLogger.error('Failed to stop API server: $e');
      _isRunning = false;
      _server = null;
      _requestLog.clear();
      // Don't throw exception on stop failure to avoid crashes during app shutdown
      AppLogger.warning('API server stopped with errors but continuing');
    }
  }

  /// Middleware for API key authentication (allows public access to /health)
  Middleware _createPublicEndpointMiddleware(String expectedApiKey) {
    return (Handler innerHandler) {
      return (Request request) async {
        // Allow public access to health endpoint
        if (request.url.path.endsWith('/health')) {
          return await innerHandler(request);
        }

        // Require authentication for all other endpoints
        final authHeader = request.headers['authorization'];
        final apiKeyHeader = request.headers['x-api-key'];

        String? providedKey;

        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          providedKey = authHeader.substring(7);
        } else if (apiKeyHeader != null) {
          providedKey = apiKeyHeader;
        }

        if (providedKey == null || providedKey != expectedApiKey) {
          AppLogger.warning('API authentication failed from ${request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown IP'}');
          return Response.forbidden(json.encode({
            'error': 'Invalid or missing API key',
            'message': 'Please provide a valid API key via Authorization header (Bearer token) or X-API-Key header',
            'timestamp': DateTime.now().toIso8601String(),
          }), headers: {'Content-Type': 'application/json'});
        }

        return await innerHandler(request);
      };
    };
  }

  /// Middleware for rate limiting
  Middleware _createRateLimitingMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Skip rate limiting for health checks
        if (request.url.path.endsWith('/health')) {
          return await innerHandler(request);
        }

        final clientIp = _getClientIp(request);
        final now = DateTime.now();

        // Clean up old requests for this IP
        if (_requestLog.containsKey(clientIp)) {
          _requestLog[clientIp]!.removeWhere((timestamp) => now.difference(timestamp) > _rateLimitWindow);
        } else {
          _requestLog[clientIp] = [];
        }

        // Check rate limit
        if (_requestLog[clientIp]!.length >= _maxRequestsPerMinute) {
          AppLogger.warning('Rate limit exceeded for IP: $clientIp');
          return Response(429, body: json.encode({
            'error': 'Rate limit exceeded',
            'message': 'Too many requests. Maximum $_maxRequestsPerMinute requests per minute allowed.',
            'retry_after': _rateLimitWindow.inSeconds,
            'timestamp': now.toIso8601String(),
          }), headers: {'Content-Type': 'application/json'});
        }

        // Add current request to log
        _requestLog[clientIp]!.add(now);

        return await innerHandler(request);
      };
    };
  }

  /// Middleware for security headers
  Middleware _createSecurityHeadersMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);

        return response.change(headers: {
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
          'X-XSS-Protection': '1; mode=block',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Content-Security-Policy': "default-src 'self'",
          'Server': 'BijbelQuiz-API',
        });
      };
    };
  }

  /// Middleware for request validation
  Middleware _createValidationMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Validate request size (prevent large payloads)
        final contentLength = request.contentLength;
        if (contentLength != null && contentLength > 1024 * 1024) { // 1MB limit
          return Response(413, body: json.encode({
            'error': 'Request too large',
            'message': 'Request payload exceeds maximum allowed size of 1MB',
            'timestamp': DateTime.now().toIso8601String(),
          }), headers: {'Content-Type': 'application/json'});
        }

        return await innerHandler(request);
      };
    };
  }

  /// Enhanced logging middleware
  Middleware _createLoggingMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final startTime = DateTime.now();
        final clientIp = _getClientIp(request);
        final userAgent = request.headers['user-agent'] ?? 'Unknown';

        AppLogger.info('API Request: ${request.method} ${request.url.path} from $clientIp (UA: $userAgent)');

        try {
          final response = await innerHandler(request);
          final duration = DateTime.now().difference(startTime);

          AppLogger.info('API Response: ${response.statusCode} for ${request.method} ${request.url.path} (${duration.inMilliseconds}ms)');
          return response;
        } catch (e) {
          final duration = DateTime.now().difference(startTime);
          AppLogger.error('API Error: ${request.method} ${request.url.path} failed after ${duration.inMilliseconds}ms - $e');
          rethrow;
        }
      };
    };
  }

  /// Get client IP address from request
  String _getClientIp(Request request) {
    // Try X-Forwarded-For header first (for proxies/load balancers)
    final forwardedFor = request.headers['x-forwarded-for'];
    if (forwardedFor != null && forwardedFor.isNotEmpty) {
      return forwardedFor.split(',').first.trim();
    }

    // Try X-Real-IP header
    final realIp = request.headers['x-real-ip'];
    if (realIp != null && realIp.isNotEmpty) {
      return realIp;
    }

    // Fallback to connection info (safer approach)
    try {
      final connectionInfo = request.context['shelf.io.connection.info'];
      if (connectionInfo != null) {
        // Use string representation as fallback
        return connectionInfo.toString();
      }
    } catch (e) {
      // Ignore errors and use fallback
    }

    return 'unknown';
  }

  /// Middleware for CORS support
  Middleware _createCorsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);

        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
          'Access-Control-Max-Age': '86400', // 24 hours
        });
      };
    };
  }

  /// Health check endpoint
  Future<Response> _handleHealth(Request request) async {
    try {
      return Response.ok(json.encode({
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'service': 'BijbelQuiz API',
        'version': _apiVersion,
        'uptime': _isRunning ? 'running' : 'stopped',
      }), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      AppLogger.error('Health check failed: $e');
      return Response.internalServerError(body: json.encode({
        'status': 'unhealthy',
        'timestamp': DateTime.now().toIso8601String(),
        'error': 'Health check failed',
        'message': 'An internal error occurred during health check',
      }), headers: {'Content-Type': 'application/json'});
    }
  }

  /// Get questions endpoint
  Future<Response> Function(Request) _handleGetQuestions(QuestionCacheService questionCacheService) {
    return (Request request) async {
      final startTime = DateTime.now();

      try {
        final category = request.url.queryParameters['category'];
        final limitParam = request.url.queryParameters['limit'] ?? '10';
        final difficulty = request.url.queryParameters['difficulty'];

        // Validate and parse limit parameter
        final limit = int.tryParse(limitParam);
        if (limit == null || limit < 1 || limit > 50) {
          return Response.badRequest(body: json.encode({
            'error': 'Invalid limit parameter',
            'message': 'Limit must be a number between 1 and 50',
            'timestamp': DateTime.now().toIso8601String(),
            'valid_range': '1-50',
          }), headers: {'Content-Type': 'application/json'});
        }

        // Validate difficulty parameter if provided
        if (difficulty != null && difficulty.isNotEmpty) {
          final validDifficulties = ['1', '2', '3', '4', '5'];
          if (!validDifficulties.contains(difficulty.toLowerCase())) {
            return Response.badRequest(body: json.encode({
              'error': 'Invalid difficulty parameter',
              'message': 'Difficulty must be a number between 1 and 5',
              'timestamp': DateTime.now().toIso8601String(),
              'valid_values': validDifficulties,
            }), headers: {'Content-Type': 'application/json'});
          }
        }

        List<QuizQuestion> questions;

        if (category != null && category.isNotEmpty) {
          questions = await questionCacheService.getQuestionsByCategory('nl', category, count: limit);
        } else {
          questions = await questionCacheService.getQuestions('nl', count: limit);
        }

        // Filter by difficulty if specified
        if (difficulty != null && difficulty.isNotEmpty) {
          questions = questions.where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase()).toList();
        }

        final questionsData = questions.map((q) => {
          'question': q.question,
          'correctAnswer': q.correctAnswer,
          'incorrectAnswers': q.incorrectAnswers,
          'difficulty': q.difficulty,
          'type': q.type.name,
          'categories': q.categories,
          'biblicalReference': q.biblicalReference,
          'allOptions': q.allOptions,
          'correctAnswerIndex': q.correctAnswerIndex,
        }).toList();

        final response = {
          'questions': questionsData,
          'count': questions.length,
          'category': category,
          'difficulty': difficulty,
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
        };

        AppLogger.info('Questions endpoint: Retrieved ${questions.length} questions in ${DateTime.now().difference(startTime).inMilliseconds}ms');
        return Response.ok(json.encode(response), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.error('Error in questions endpoint after ${duration.inMilliseconds}ms: $e');
        return Response.internalServerError(body: json.encode({
          'error': 'Failed to load questions',
          'message': 'An internal error occurred while processing your request',
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': duration.inMilliseconds,
        }), headers: {'Content-Type': 'application/json'});
      }
    };
  }

  /// Get questions by category endpoint
  Future<Response> Function(Request) _handleGetQuestionsByCategory(QuestionCacheService questionCacheService) {
    return (Request request) async {
      final startTime = DateTime.now();

      try {
        final category = request.params['category'];
        if (category == null || category.isEmpty) {
          return Response.badRequest(body: json.encode({
            'error': 'Missing category parameter',
            'message': 'Category parameter is required in the URL path',
            'timestamp': DateTime.now().toIso8601String(),
          }), headers: {'Content-Type': 'application/json'});
        }

        final limitParam = request.url.queryParameters['limit'] ?? '10';
        final difficulty = request.url.queryParameters['difficulty'];

        // Validate and parse limit parameter
        final limit = int.tryParse(limitParam);
        if (limit == null || limit < 1 || limit > 50) {
          return Response.badRequest(body: json.encode({
            'error': 'Invalid limit parameter',
            'message': 'Limit must be a number between 1 and 50',
            'timestamp': DateTime.now().toIso8601String(),
            'valid_range': '1-50',
          }), headers: {'Content-Type': 'application/json'});
        }

        // Validate difficulty parameter if provided
        if (difficulty != null && difficulty.isNotEmpty) {
          final validDifficulties = ['1', '2', '3', '4', '5'];
          if (!validDifficulties.contains(difficulty.toLowerCase())) {
            return Response.badRequest(body: json.encode({
              'error': 'Invalid difficulty parameter',
              'message': 'Difficulty must be a number between 1 and 5',
              'timestamp': DateTime.now().toIso8601String(),
              'valid_values': validDifficulties,
            }), headers: {'Content-Type': 'application/json'});
          }
        }

        final questions = await questionCacheService.getQuestionsByCategory('nl', category, count: limit);

        // Filter by difficulty if specified
        final filteredQuestions = difficulty != null && difficulty.isNotEmpty
            ? questions.where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase()).toList()
            : questions;

        final questionsData = filteredQuestions.map((q) => {
          'question': q.question,
          'correctAnswer': q.correctAnswer,
          'incorrectAnswers': q.incorrectAnswers,
          'difficulty': q.difficulty,
          'type': q.type.name,
          'categories': q.categories,
          'biblicalReference': q.biblicalReference,
          'allOptions': q.allOptions,
          'correctAnswerIndex': q.correctAnswerIndex,
        }).toList();

        final response = {
          'questions': questionsData,
          'count': filteredQuestions.length,
          'category': category,
          'difficulty': difficulty,
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
        };

        AppLogger.info('Questions by category endpoint: Retrieved ${filteredQuestions.length} questions for category "$category" in ${DateTime.now().difference(startTime).inMilliseconds}ms');
        return Response.ok(json.encode(response), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.error('Error in questions by category endpoint after ${duration.inMilliseconds}ms: $e');
        return Response.internalServerError(body: json.encode({
          'error': 'Failed to load questions for category',
          'message': 'An internal error occurred while processing your request',
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': duration.inMilliseconds,
        }), headers: {'Content-Type': 'application/json'});
      }
    };
  }

  /// Get user progress endpoint
  Future<Response> Function(Request) _handleGetProgress(LessonProgressProvider progressProvider) {
    return (Request request) async {
      final startTime = DateTime.now();

      try {
        final exportData = progressProvider.getExportData();
        final progressData = {
          'unlockedCount': progressProvider.unlockedCount,
          'bestStarsByLesson': exportData['bestStarsByLesson'],
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
        };

        AppLogger.info('Progress endpoint: Retrieved progress data in ${DateTime.now().difference(startTime).inMilliseconds}ms');
        return Response.ok(json.encode(progressData), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.error('Error in progress endpoint after ${duration.inMilliseconds}ms: $e');
        return Response.internalServerError(body: json.encode({
          'error': 'Failed to get progress data',
          'message': 'An internal error occurred while retrieving progress data',
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': duration.inMilliseconds,
        }), headers: {'Content-Type': 'application/json'});
      }
    };
  }

  /// Get game stats endpoint
  Future<Response> Function(Request) _handleGetStats(GameStatsProvider statsProvider) {
    return (Request request) async {
      final startTime = DateTime.now();

      try {
        final statsData = {
          'score': statsProvider.score,
          'currentStreak': statsProvider.currentStreak,
          'longestStreak': statsProvider.longestStreak,
          'incorrectAnswers': statsProvider.incorrectAnswers,
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
        };

        AppLogger.info('Stats endpoint: Retrieved stats data in ${DateTime.now().difference(startTime).inMilliseconds}ms');
        return Response.ok(json.encode(statsData), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.error('Error in stats endpoint after ${duration.inMilliseconds}ms: $e');
        return Response.internalServerError(body: json.encode({
          'error': 'Failed to get stats data',
          'message': 'An internal error occurred while retrieving statistics',
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': duration.inMilliseconds,
        }), headers: {'Content-Type': 'application/json'});
      }
    };
  }

  /// Get settings endpoint
  Future<Response> Function(Request) _handleGetSettings(SettingsProvider settingsProvider) {
    return (Request request) async {
      final startTime = DateTime.now();

      try {
        final settingsData = {
          'themeMode': settingsProvider.themeMode.name,
          'gameSpeed': settingsProvider.gameSpeed,
          'mute': settingsProvider.mute,
          'analyticsEnabled': settingsProvider.analyticsEnabled,
          'notificationEnabled': settingsProvider.notificationEnabled,
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
        };

        AppLogger.info('Settings endpoint: Retrieved settings data in ${DateTime.now().difference(startTime).inMilliseconds}ms');
        return Response.ok(json.encode(settingsData), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.error('Error in settings endpoint after ${duration.inMilliseconds}ms: $e');
        return Response.internalServerError(body: json.encode({
          'error': 'Failed to get settings data',
          'message': 'An internal error occurred while retrieving settings',
          'timestamp': DateTime.now().toIso8601String(),
          'processing_time_ms': duration.inMilliseconds,
        }), headers: {'Content-Type': 'application/json'});
      }
    };
  }
}