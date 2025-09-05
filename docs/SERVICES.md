# Services Documentation

This document provides detailed information about the services used in the BijbelQuiz application.

## Overview

The BijbelQuiz app follows a service-oriented architecture with modular services that handle different aspects of the application functionality. Services are designed to be reusable, testable, and maintain separation of concerns.

## Core Services

### QuizSoundService

**Location:** `app/lib/services/quiz_sound_service.dart`

**Purpose:** Centralized sound management for quiz-related audio feedback with mute support.

**Key Features:**

- Plays correct/incorrect answer sounds
- Respects user mute settings
- Handles sound playback errors gracefully
- Integrates with SettingsProvider for mute state

**Usage:**

```dart
final quizSoundService = QuizSoundService(soundService);

// Play correct answer sound (checks mute setting automatically)
await quizSoundService.playCorrectAnswerSound(context);

// Play incorrect answer sound (checks mute setting automatically)
await quizSoundService.playIncorrectAnswerSound(context);
```

### QuestionLoadingService

**Location:** `app/lib/services/question_loading_service.dart`

**Purpose:** Advanced background question loading with predictive caching and adaptive batching.

**Key Features:**

- Simple background loading for quiz screen
- Advanced loading with predictive candidates
- Adaptive batch sizing based on memory usage
- Automatic continuation of loading in background
- Error handling and logging

**Usage:**

```dart
final questionLoadingService = QuestionLoadingService(questionCacheService);

// Simple background loading
await questionLoadingService.loadMoreQuestionsInBackground(
  context: context,
  lessonMode: false,
  questions: questions,
  setState: setState,
);

// Advanced loading with predictive caching
await questionLoadingService.loadMoreQuestionsAdvanced(
  context: context,
  questions: questions,
  setState: setState,
  mounted: mounted,
);
```

### SoundService

**Location:** `app/lib/services/sound_service.dart`

**Purpose:** Low-level audio playback service using just_audio package.

**Key Features:**

- Cross-platform audio playback
- Support for different audio formats
- Error handling for audio operations
- Audio session management

### ConnectionService

**Location:** `app/lib/services/connection_service.dart`

**Purpose:** Network connectivity monitoring and management.

**Key Features:**

- Real-time connectivity status
- Automatic retry mechanisms
- Connection type detection (WiFi, mobile, etc.)
- Integration with connectivity_plus package

### QuestionCacheService

**Location:** `app/lib/services/question_cache_service.dart`

**Purpose:** Intelligent question caching for offline functionality.

**Key Features:**

- Local question storage
- Cache invalidation strategies
- Memory usage monitoring
- Predictive loading candidate identification

### EmergencyService

**Location:** `app/lib/services/emergency_service.dart`

**Purpose:** Emergency message system for broadcasting important notifications to all users.

**Key Features:**

- Polls emergency API every 5 minutes
- Displays blocking or dismissible messages
- Handles message expiration
- Integrates with dialog system

### NotificationService

**Location:** `app/lib/services/notification_service.dart`

**Purpose:** Local notification management for daily motivation reminders.

**Key Features:**

- Scheduled daily notifications
- Platform-specific notification handling
- User preference integration
- Time zone support

### Logger

**Location:** `app/lib/services/logger.dart`

**Purpose:** Centralized logging system with configurable levels.

**Key Features:**

- Multiple log levels (debug, info, warning, error)
- Platform-specific log output
- Performance logging
- Error tracking

## Service Architecture

### Dependency Injection

Services are typically instantiated at the app level and passed down through the widget tree or accessed via Provider:

```dart
// In main.dart or app initialization
final soundService = SoundService();
final quizSoundService = QuizSoundService(soundService);

// Make services available via Provider
runApp(
  MultiProvider(
    providers: [
      Provider<SoundService>.value(value: soundService),
      Provider<QuizSoundService>.value(value: quizSoundService),
    ],
    child: MyApp(),
  ),
);
```

### Error Handling

All services include comprehensive error handling:

- Try-catch blocks around critical operations
- Graceful degradation when services fail
- Logging of errors for debugging
- User-friendly error messages when appropriate

### Testing

Services are designed to be easily testable:

- Dependency injection allows for mock services
- Pure functions where possible
- Clear separation of concerns
- Comprehensive error scenarios covered

## Best Practices

1. **Single Responsibility:** Each service has one primary responsibility
2. **Dependency Injection:** Services receive dependencies rather than creating them
3. **Error Handling:** All services handle errors gracefully
4. **Logging:** Important operations are logged for debugging
5. **Performance:** Services consider performance impact on low-end devices
6. **Testing:** Services are designed to be easily unit tested

## Future Enhancements

- Service health monitoring
- Automatic service restart on failure
- Service performance metrics
- Enhanced caching strategies
- Background service synchronization
