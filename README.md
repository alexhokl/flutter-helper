# flutter-helper

Shared infrastructure for the Flutter apps (cbt, expense-tracker,
nihongo_geemu, photos, time-logger, todo-cli), so that a fix or an upgrade is
made once instead of in every app. Screens, protos, local storage and state
management stay in each app.

| Library | Contents |
|---|---|
| `package:flutter_helper/grpc.dart` | `GrpcChannelHolder` (lazy channel, TLS for every host except loopback), `ServiceException`, `guardGrpc`, `describeError` |
| `package:flutter_helper/config.dart` | `BackendConfig` (the `backend_url` setting, parsed into host and port), `BuildInfo.gitCommit` |
| `package:flutter_helper/intents.dart` | `IntentChannel<T>` for intents forwarded by `MainActivity`, plus `nonEmpty`, `squashWhitespace`, `splitList` |
| `package:flutter_helper/ui.dart` | `themesFromSeed`, `LoadingView`, `EmptyState`, `ErrorState`, `showMessage`, `confirmDialog`, `GitCommitFooter`, `GitCommitField` |
| `package:flutter_helper/format.dart` | `formatDuration`, `formatStopwatch`, `formatBytes`, `formatIsoDate`, `formatDay`, `formatDate`, `formatTime`, `formatDateTime`, `twoDigits` |
| `package:flutter_helper/testing.dart` | `setUpInMemoryPrefs`, `wrapForTest` (test code only) |
| `package:flutter_helper/analysis_options.yaml` | `flutter_lints` plus the excludes every app needs |
| `taskfiles/flutter.yml` | `apk`, `mac`, `run-flutter`, `run-android`, signing key and `tag` tasks |

## Using it in an app

```yaml
# pubspec.yaml
dependencies:
  flutter_helper:
    git:
      url: https://github.com/alexhokl/flutter-helper.git
      ref: v0.1.0
```

```yaml
# analysis_options.yaml
include: package:flutter_helper/analysis_options.yaml
```

```yaml
# Taskfile.yml at the repo root
includes:
  flutter:
    taskfile: ../flutter-helper/taskfiles/flutter.yml
    flatten: true
    vars:
      APP: todo-cli
      MAC_APP: todo.app
```

The Taskfile include relies on `flutter-helper` being checked out next to the
app's repo, which is how `~/git` is laid out; it is only used locally.

### Developing against a local checkout

To try a change before it is tagged, add `pubspec_overrides.yaml` next to the
app's `pubspec.yaml`. It is git-ignored in the apps, but pub records the path
in `pubspec.lock`, so delete the override and run `flutter pub get` again
(after tagging and bumping `ref:`) before committing the app.

```yaml
dependency_overrides:
  flutter_helper:
    path: ../../flutter-helper   # ../flutter-helper for nihongo_geemu
```

## Releasing

1. Bump `version` in `pubspec.yaml` and add a `CHANGELOG.md` entry.
2. `task lint test`
3. Commit, `task tag`, and push the commit and the tag.
4. Bump `ref:` in the apps that need the change.

## Development

```sh
task test
task lint
```
