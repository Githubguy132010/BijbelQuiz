# Services Documentation

This document provides detailed information about the services used in the BijbelQuiz application.

## Overview

The BijbelQuiz app follows a service-oriented architecture with modular services that handle different aspects of the application functionality. Services are designed to be reusable, testable, and maintain separation of concerns.

## Core Services

### QuizSoundService

**Location:** `bijbelquiz/lib/services/quiz_sound_service.dart`

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

### NotificationService

**Location:** `app/lib/services/notification_service.dart`

**Purpose:** Local notification management for daily motivation reminders.

**Key Features:**

- Scheduled daily notifications
- Platform-specific notification handling
- User preference integration
- Time zone support

### ProgressiveQuestionSelector

**Location:** `bijbelquiz/lib/services/progressive_question_selector.dart`

**Purpose:** Intelligent question selection algorithm that adapts difficulty based on user performance.

**Key Features:**

- Dynamic difficulty adjustment based on performance metrics
- Progressive Question Up-selection (PQU) algorithm
- Anti-repetition mechanisms to avoid showing recent questions
- Performance tracking and analysis
- Adaptive batching for optimal performance

### AnalyticsService

**Location:** `bijbelquiz/lib/services/analytics_service.dart`

**Purpose:** Analytics and telemetry service for tracking user interactions and app performance.

**Key Features:**

- Event tracking with user consent management
- Integration with PostHog analytics platform
- Screen view tracking
- User preference respecting (opt-in/out)
- Performance impact monitoring

### FeatureFlagsService

**Location:** `bijbelquiz/lib/services/feature_flags_service.dart`

**Purpose:** Feature flag management for controlling app functionality remotely.

**Key Features:**

- Remote feature toggles
- Gradual feature rollouts
- User targeting capabilities
- Real-time configuration updates

### GeminiService

**Location:** `bijbelquiz/lib/services/gemini_service.dart`

**Purpose:** Integration with Google's Gemini AI for enhanced app features.

**Key Features:**

- AI-powered assistance
- Natural language processing
- Contextual help and suggestions
- API rate limiting and error handling

### LessonService

**Location:** `bijbelquiz/lib/services/lesson_service.dart`

**Purpose:** Lesson management and progression tracking.

**Key Features:**

- Lesson unlock mechanics
- Progress persistence
- Achievement tracking
- Lesson completion validation

### PlatformFeedbackService

**Location:** `bijbelquiz/lib/services/platform_feedback_service.dart`

**Purpose:** Platform-specific feedback and haptic responses.

**Key Features:**

- Haptic feedback on supported devices
- Platform-specific UI adaptations
- Accessibility support
- Performance optimizations per platform

### QuizAnswerHandler

**Location:** `bijbelquiz/lib/services/quiz_answer_handler.dart`

**Purpose:** Quiz answer processing and validation logic.

**Key Features:**

- Answer validation and scoring
- Streak calculation and management
- Performance metrics computation
- Integration with game statistics

### QuizTimerManager

**Location:** `bijbelquiz/lib/services/quiz_timer_manager.dart`

**Purpose:** Quiz timer functionality and time management.

**Key Features:**

- Countdown timer management
- Time-based scoring adjustments
- Pause/resume functionality
- Integration with quiz flow

### Logger

**Location:** `bijbelquiz/lib/services/logger.dart`

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
