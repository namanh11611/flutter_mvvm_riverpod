# Module Contribution Guide

This guide defines how group members should add a feature module to GoBuddy.

## Before You Start

1. Pull the latest `main` branch.
2. Create a branch for one module only, for example `feature/chat` or `feature/trip-booking`.
3. Do not edit another member's feature files unless the change has been agreed with that member.
4. Do not commit `.env` or secrets.

## Required Feature Structure

Create each module inside `lib/features/<feature_name>/` using lowercase snake_case.

```text
lib/features/<feature_name>/
  model/             # Domain data classes only
  repository/        # Supabase, local database, or API access
  ui/
    <feature>_screen.dart
    state/           # Immutable state objects
    view_model/      # Riverpod Notifiers / AsyncNotifiers
    widgets/         # Reusable widgets private to this feature
```

Example:

```text
lib/features/chat/
  model/message.dart
  repository/chat_repository.dart
  ui/chat_screen.dart
  ui/state/chat_state.dart
  ui/view_model/chat_view_model.dart
  ui/widgets/message_bubble.dart
```

## MVVM Responsibilities

| Layer | Responsibility | Must not contain |
|---|---|---|
| Model | Typed feature data, serialization, enums | Widgets, Supabase calls |
| Repository | Reads and writes data through Supabase, API, or local storage | UI state, navigation, widgets |
| View model | Riverpod state, validation, user actions, calls to repositories | Widget layout, direct navigation widgets |
| State | Immutable values rendered by the UI, loading and error state | Network calls, mutable collections |
| UI | Renders state and forwards user actions to the view model | Supabase calls, business rules, feature-wide `setState` |

Use a Riverpod provider for each repository and view model. Keep `setState` only for small, temporary widget concerns such as an animation controller or a text-field visibility toggle.

## Shared Code Rules

- Shared Supabase access belongs in `lib/features/common/remote/supabase_client.dart`.
- Shared widgets belong in `lib/features/common/ui/widgets/` only when they are used by more than one feature.
- App-wide routes belong in `lib/routing/routes.dart` and `lib/routing/router.dart`.
- Do not import one feature's UI into another feature's repository or view model.
- Do not put feature screens, global variables, or business logic in `lib/main.dart`.

## Adding a Route

1. Add a route constant in `lib/routing/routes.dart`.
2. Import the feature screen in `lib/routing/router.dart`.
3. Add a `GoRoute` that creates the screen.
4. Pass IDs or small typed route data only. Fetch full data through the feature view model.

## Adding Backend Data

1. Add or update a model under the feature's `model/` directory.
2. Put Supabase queries in the feature repository.
3. Return typed models, not raw `Map<String, dynamic>` values, to the view model.
4. Handle loading and error states in the view model state.
5. Keep table names and common database keys in `lib/constants/` when they are shared.

## Quality Checklist

Before opening a pull request, run:

```bash
dart format lib test
flutter test
flutter analyze
```

Add focused tests for view-model actions and repository behavior. Do not change generated `.g.dart` or `.freezed.dart` files manually; regenerate them with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Pull Request Checklist

- The branch contains one feature or one focused bug fix.
- The module follows the required folder structure.
- UI does not call Supabase, APIs, or databases directly.
- View-model state covers loading, success, and error states where data is asynchronous.
- Routes and localization keys are added when needed.
- Tests and analysis have been run; mention any existing warnings in the pull request.
- No secrets, environment values, or unrelated formatting changes are included.

## Prompt for an AI Coding Assistant

Copy and adapt this prompt when asking an AI to add a module:

```text
Add a <feature name> module to this Flutter project using its existing MVVM and Riverpod patterns.

Create the feature only under lib/features/<feature_name>/ with model, repository, ui/state, ui/view_model, and ui/widgets folders as needed. Keep models typed, place all Supabase/API access in the repository, keep state and actions in a Riverpod view model, and keep UI widgets free of backend calls and business logic.

Add any required GoRouter route in lib/routing/routes.dart and lib/routing/router.dart. Reuse common services and widgets instead of importing another feature's UI. Do not modify lib/main.dart except when app-wide initialization is genuinely required. Do not edit generated files manually.

After implementation, run dart format, focused Flutter tests, and flutter analyze. Report changed files, test results, and any pre-existing analyzer warnings separately.
```
