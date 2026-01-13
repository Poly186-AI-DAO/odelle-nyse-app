# Odelle NYSE - Architecture Guide

## Overview

This document defines the app architecture for Odelle NYSE. **All agents implementing features should follow these patterns.**

**Architecture Pattern:** MVVM with Riverpod  
**State Management:** Riverpod 2.x  
**Data Layer:** Repository Pattern with SQLite (drift)

---

## Why Riverpod?

We migrated from `provider` to `riverpod` for these reasons:

| Feature | Provider | Riverpod |
|---------|----------|----------|
| Compile-time safety | ❌ Runtime errors | ✅ Compile-time errors |
| BuildContext required | ✅ Always needed | ❌ Use `ref` anywhere |
| Testing | Harder | ✅ Easy provider overrides |
| Combining providers | Manual | ✅ Built-in `ref.watch` |
| Auto-dispose | Manual | ✅ Automatic |
| Boilerplate | Medium | ✅ Less |

---

## Layer Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ODELLE ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         UI LAYER                                     │   │
│   │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐              │   │
│   │  │   Screens   │    │   Widgets   │    │   Dialogs   │              │   │
│   │  │ (Consumer   │    │ (Consumer   │    │             │              │   │
│   │  │  Widget)    │    │  Widget)    │    │             │              │   │
│   │  └──────┬──────┘    └──────┬──────┘    └─────────────┘              │   │
│   │         │                  │                                         │   │
│   │         └────────┬─────────┘                                         │   │
│   │                  │ ref.watch() / ref.read()                          │   │
│   │                  ▼                                                   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      STATE LAYER (Riverpod)                          │   │
│   │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐              │   │
│   │  │ ViewModels  │    │  Notifiers  │    │  Providers  │              │   │
│   │  │ (Notifier)  │    │ (state)     │    │ (services)  │              │   │
│   │  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘              │   │
│   │         │                  │                  │                      │   │
│   │         └────────┬─────────┴──────────────────┘                      │   │
│   │                  │ ref.read(repositoryProvider)                      │   │
│   │                  ▼                                                   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         DATA LAYER                                   │   │
│   │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐              │   │
│   │  │Repositories │───►│  Services   │───►│  Database   │              │   │
│   │  │             │    │  (API,      │    │  (SQLite)   │              │   │
│   │  │             │    │   Voice)    │    │             │              │   │
│   │  └─────────────┘    └─────────────┘    └─────────────┘              │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## File Structure

> *"Your Soul Bonds Now with Health and Wealth"*

```
lib/
├── main.dart                      # App entry, ProviderScope wrapper
│
├── providers/                     # Riverpod providers (STATE LAYER)
│   ├── providers.dart             # Core service providers (exported)
│   ├── service_providers.dart     # Service instances
│   ├── repository_providers.dart  # Repository instances
│   └── viewmodels/               # Feature ViewModels
│       ├── soul_viewmodel.dart    # Identity, sleep, meditation
│       ├── bonds_viewmodel.dart   # Contacts, interactions
│       ├── now_viewmodel.dart     # Voice/AI conversation
│       ├── health_viewmodel.dart  # Meals, workouts, supplements
│       ├── wealth_viewmodel.dart  # Bills, subscriptions, income
│       ├── dose_viewmodel.dart
│       ├── workout_viewmodel.dart
│       └── ...
│
├── repositories/                  # Data access layer
│   ├── dose_repository.dart
│   ├── workout_repository.dart
│   ├── meal_repository.dart
│   ├── contact_repository.dart    # [NEW] Bonds
│   ├── bill_repository.dart       # [NEW] Wealth
│   ├── subscription_repository.dart # [NEW] Wealth
│   └── ...
│
├── services/                      # External services
│   ├── azure_speech_service.dart
│   ├── backend_api_service.dart
│   ├── google_auth_service.dart
│   └── poly_auth_service.dart
│
├── models/                        # Data models (see DATA_MODELS.md)
│   ├── tracking/                  # Health domain (meals, workouts, supps)
│   ├── wealth/                    # [NEW] Finance domain
│   │   ├── bill.dart
│   │   ├── subscription.dart
│   │   └── income.dart
│   ├── relationships/             # [NEW] Bonds domain
│   │   ├── contact.dart
│   │   └── interaction.dart
│   ├── content/                   # Learning content
│   └── ...
│
├── database/                      # SQLite database
│   └── app_database.dart
│
├── screens/                       # UI screens (5 Pillars)
│   ├── home_screen.dart           # PageView with 5 pillars
│   ├── soul_screen.dart           # Pillar 0: Identity, meditation, mantras
│   ├── bonds_screen.dart          # Pillar 1: Relationships, contacts
│   ├── now_screen.dart            # Pillar 2: Voice AI, digital twin (CENTER)
│   ├── health_screen.dart         # Pillar 3: Body tracking
│   └── wealth_screen.dart         # Pillar 4: Finance
│
├── widgets/                       # Reusable widgets
│   └── ...
│
└── constants/                     # App constants
    └── ...
```

---

## Riverpod Patterns

### 1. Service Providers (Singleton services)

Use `Provider` for services that don't change state:

```dart
// lib/providers/service_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/azure_speech_service.dart';
import '../services/backend_api_service.dart';
import '../database/app_database.dart';

/// Voice/speech recognition service
final voiceServiceProvider = Provider<AzureSpeechService>((ref) {
  return AzureSpeechService();
});

/// Backend API service
final backendApiProvider = Provider<BackendApiService>((ref) {
  return BackendApiService(baseUrl: 'https://api.example.com');
});

/// Database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});
```

### 2. Repository Providers (Data access)

Repositories depend on database/services:

```dart
// lib/providers/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/dose_repository.dart';
import '../repositories/workout_repository.dart';
import 'service_providers.dart';

/// Dose/supplement repository
final doseRepositoryProvider = Provider<DoseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DoseRepository(db);
});

/// Workout repository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});
```

### 3. ViewModel/Notifier Providers (Stateful logic)

Use `Notifier` for ViewModels with mutable state:

```dart
// lib/providers/viewmodels/dose_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracking/dose_log.dart';
import '../../models/tracking/supplement.dart';
import '../repository_providers.dart';

/// State for dose tracking
class DoseState {
  final List<Supplement> supplements;
  final List<DoseLog> todaysDoses;
  final bool isLoading;
  final String? error;

  const DoseState({
    this.supplements = const [],
    this.todaysDoses = const [],
    this.isLoading = false,
    this.error,
  });

  DoseState copyWith({
    List<Supplement>? supplements,
    List<DoseLog>? todaysDoses,
    bool? isLoading,
    String? error,
  }) {
    return DoseState(
      supplements: supplements ?? this.supplements,
      todaysDoses: todaysDoses ?? this.todaysDoses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for dose tracking
class DoseViewModel extends Notifier<DoseState> {
  @override
  DoseState build() {
    // Initial state
    return const DoseState();
  }

  DoseRepository get _repository => ref.read(doseRepositoryProvider);

  /// Load supplements and today's doses
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final supplements = await _repository.getSupplements();
      final todaysDoses = await _repository.getTodaysDoses();
      
      state = state.copyWith(
        supplements: supplements,
        todaysDoses: todaysDoses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Log a dose
  Future<void> logDose(int supplementId, double amountMg) async {
    try {
      await _repository.logDose(
        supplementId: supplementId,
        amountMg: amountMg,
        timestamp: DateTime.now(),
      );
      await load(); // Refresh
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for dose ViewModel
final doseViewModelProvider = NotifierProvider<DoseViewModel, DoseState>(
  DoseViewModel.new,
);
```

### 4. Using Providers in Widgets

Extend `ConsumerWidget` or `ConsumerStatefulWidget`:

```dart
// lib/screens/body_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/viewmodels/dose_viewmodel.dart';

class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state - rebuilds when state changes
    final doseState = ref.watch(doseViewModelProvider);
    
    // Read ViewModel for actions (doesn't rebuild)
    final doseVM = ref.read(doseViewModelProvider.notifier);

    if (doseState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Text('Supplements: ${doseState.supplements.length}'),
        Text('Today\'s doses: ${doseState.todaysDoses.length}'),
        ElevatedButton(
          onPressed: () => doseVM.logDose(1, 5000),
          child: const Text('Log Vitamin D'),
        ),
      ],
    );
  }
}
```

### 5. ConsumerStatefulWidget (for animations, controllers)

```dart
class AnimatedScreen extends ConsumerStatefulWidget {
  const AnimatedScreen({super.key});

  @override
  ConsumerState<AnimatedScreen> createState() => _AnimatedScreenState();
}

class _AnimatedScreenState extends ConsumerState<AnimatedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    
    // Can use ref in initState
    ref.read(doseViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doseViewModelProvider);
    // ... build UI
  }
}
```

---

## Repository Pattern

Repositories abstract data access. They can combine database + API:

```dart
// lib/repositories/dose_repository.dart

import '../database/app_database.dart';
import '../models/tracking/supplement.dart';
import '../models/tracking/dose_log.dart';

class DoseRepository {
  final AppDatabase _db;

  DoseRepository(this._db);

  /// Get all active supplements
  Future<List<Supplement>> getSupplements() async {
    return await _db.getActiveSupplements();
  }

  /// Get doses logged today
  Future<List<DoseLog>> getTodaysDoses() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return await _db.getDosesAfter(startOfDay);
  }

  /// Log a new dose
  Future<void> logDose({
    required int supplementId,
    required double amountMg,
    required DateTime timestamp,
    String? notes,
  }) async {
    final log = DoseLog(
      supplementId: supplementId,
      amountMg: amountMg,
      timestamp: timestamp,
      source: DoseSource.manual,
      notes: notes,
    );
    await _db.insertDoseLog(log);
  }
}
```

---

## Testing with Riverpod

Override providers in tests easily:

```dart
void main() {
  testWidgets('logs dose correctly', (tester) async {
    // Create fake repository
    final fakeRepo = FakeDoseRepository();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the repository
          doseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: BodyScreen()),
      ),
    );

    // Test UI...
  });
}
```

---

## Common Patterns

### Async Initialization

```dart
final userProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

// In widget:
final userAsync = ref.watch(userProvider);
return userAsync.when(
  data: (user) => Text('Hello ${user?.name}'),
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error: $e'),
);
```

### Family Providers (Parameterized)

```dart
final supplementProvider = FutureProvider.family<Supplement?, int>((ref, id) async {
  final repo = ref.watch(doseRepositoryProvider);
  return await repo.getSupplementById(id);
});

// In widget:
final supplement = ref.watch(supplementProvider(42));
```

### Combining Providers

```dart
final dashboardProvider = Provider<DashboardData>((ref) {
  final doses = ref.watch(doseViewModelProvider);
  final workouts = ref.watch(workoutViewModelProvider);
  final habits = ref.watch(habitViewModelProvider);
  
  return DashboardData(
    dosesLogged: doses.todaysDoses.length,
    workoutsCompleted: workouts.todaysWorkouts.length,
    habitsCompleted: habits.completedToday,
  );
});
```

---

## Migration Checklist (From Provider)

For agents migrating existing code:

1. ✅ Replace `context.read<T>()` with `ref.read(tProvider)`
2. ✅ Replace `context.watch<T>()` with `ref.watch(tProvider)`
3. ✅ Replace `Consumer<T>` with `ref.watch()` in build method
4. ✅ Replace `ChangeNotifier` with `Notifier<State>`
5. ✅ Replace `ChangeNotifierProvider` with `NotifierProvider`
6. ✅ Change `StatelessWidget` to `ConsumerWidget`
7. ✅ Change `StatefulWidget` to `ConsumerStatefulWidget`

---

## Agent Instructions

### When Implementing a New Feature:

1. **Create Model** (in `lib/models/`) - See DATA_MODELS.md
2. **Create Repository** (in `lib/repositories/`) - Data access
3. **Create ViewModel** (in `lib/providers/viewmodels/`) - Business logic
4. **Create Provider** (in `lib/providers/`) - Wire it up
5. **Create/Update Screen** (in `lib/screens/`) - ConsumerWidget

### When Implementing a New Model:

1. Create the Dart class in appropriate `lib/models/` subfolder
2. Add database table in `lib/database/app_database.dart`
3. Create repository in `lib/repositories/`
4. Create provider in `lib/providers/repository_providers.dart`
5. **Do not create ViewModels yet** - Wait for UI requirements

### File Naming Conventions:

- Models: `supplement.dart`, `dose_log.dart` (snake_case)
- Repositories: `dose_repository.dart`
- ViewModels: `dose_viewmodel.dart`
- Providers: `service_providers.dart`, `repository_providers.dart`
- Screens: `body_screen.dart`

---

## Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5  # Optional: for code generation

dev_dependencies:
  riverpod_generator: ^2.4.0   # Optional: for code generation
  build_runner: ^2.4.9         # Optional: for code generation
```

---

## Related Documents

- [DATA_MODELS.md](./DATA_MODELS.md) - All data model definitions
- [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md) - UI components and styling

---

*Document created: 2026-01-10*  
*Architecture: MVVM + Riverpod*  
*Status: ACTIVE - Follow these patterns for all new features*
