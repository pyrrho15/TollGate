# TollGate

An Android-only app that blocks short-form feeds — **YouTube Shorts** and **Instagram
Reels** — by bouncing you back out the instant you open them, while leaving the rest of
those apps fully usable.

## How it works

Android sandboxes apps: no app can see inside another app. The **only** sanctioned way
to observe another app's screen is the **AccessibilityService** API (the same API that
powers screen readers like TalkBack). TollGate uses it exclusively:

1. **Scoped by the OS.** `accessibility_service_config.xml` lists only
   `com.google.android.youtube` and `com.instagram.android`. Android itself only
   delivers screen events for those packages — TollGate physically cannot see your
   bank app, messages, or keyboard.
2. **Detect by layout, not content.** When the screen changes, the service walks the
   view tree and looks for structural resource ids (`reel_recycler`,
   `reel_player_page_container`, `clips_viewer_view_pager`, …). Resource ids are
   language-independent; it never reads captions, messages, or video content.
3. **Act.** On a match it calls `performGlobalAction(GLOBAL_ACTION_BACK)` — the same
   thing as pressing the Back button — so you land back in the app's normal UI.
4. **Stay alive.** A `specialUse` foreground service keeps the process out of Android's
   frozen state, and a boot receiver re-arms it after a restart.

**Privacy is structural:** the app declares **no `INTERNET` permission**. Android will
not let it open a network connection, so there is nowhere for data to go. It is also
open for you to read.

## Architecture

The blocker cannot be written in Dart — accessibility services are native Android
components. So the split is:

```
Flutter (Dart)   →  UI, onboarding, settings state            [lib/]
   │  MethodChannel / EventChannel
Kotlin (native)  →  accessibility service, detection, action   [android/app/src/main/kotlin/]
```

- `lib/` — Flutter UI only. `data/services/blocker_platform_service.dart` is the single
  place that touches platform channels.
- `android/.../blocker/` — the engine:
  - `ShortVideoBlockerService.kt` — the `AccessibilityService` (event plumbing, throttle, Back)
  - `detection/ShortFeedDetector.kt` — pure matching rules, no Android UI dependency
  - `TargetApp.kt` — the registry of supported feeds and their view-id markers
  - `stats/UsageStatsTracker.kt` — on-device screen-time/block counting (see Stats below)
  - `UnblockSchedule.kt` — the daily break budget and the 12am–10am hard schedule
  - `BlockerPrefs.kt` — one source of truth for settings (native owns SharedPreferences)
  - `KeepAliveService.kt`, `UnblockActionReceiver.kt` — process keeping + the pinned notice
  - `BootReceiver.kt` — re-arm after reboot

### Commitment, not a switch

A self-control app is only as strong as the friction around turning it off, so "disable
the block" is deliberately not a switch:

- **1h30m of break time per day.** Pausing blocking starts a timed break that spends from
  a fixed daily budget. Once it is gone, blocking is back until midnight.
- **You must type a sentence.** Every break — and every attempt to stop blocking a
  specific feed — requires retyping `I'll regret this later` exactly (checked natively,
  so Dart can't skip it).
- **12am–10am is a hard schedule.** No Reels or Shorts, and no breaks, in that window.
- **The reminder is pinned.** While a break runs, an ongoing notification shows the time
  left; if you clear it, it comes straight back, and it has a "Block now" action.

The master on/off switch is gone on purpose: protection is armed once and can only be
paused through the budgeted break. (The nuclear option — revoking the accessibility
permission in Android Settings — always remains, as it must on a phone you own.)

### Stats (no extra permission)

The Stats tab shows time spent in each app and how many scrolls were blocked. It is
counted **without any new permission**, from the same accessibility events the blocker
already receives:

- A session starts when the app becomes active and ends when it leaves the foreground
  (confirmed by a 2-second poll of the focused window) or after a 15-second idle gap.
- Totals are stored per day in SharedPreferences (kept for ~13 months).
- A GitHub-style **consistency grid** turns a day green when that day's YouTube +
  Instagram time stayed under the daily budget.
- Because Android only hands us events for the two scoped packages, this is deliberately
  an *estimate* of foreground time, not a forensic measurement. The UI says so.

This is why the accessibility config also sets `flagRetrieveInteractiveWindows` — it is
only used to read the *package name* of the focused window.

## UI at a glance

Three tabs, switched from a bottom navigation bar:

**Block** (the controls)
- **Status hero** — one of `Not set up yet`, `Paused`, `On a break`, `Locked until 10am`,
  `Nothing selected`, or `Protecting`, always reflecting the real OS + settings state.
- **Setup card** (only until permission is granted) — numbered steps, including the
  Android 13+ "Allow restricted settings" gotcha, and a button that opens the OS screen.
- **Break card** — remaining break time for the day, plus the budgeted "Take a break"
  button (behind the commitment sentence) or "Block now" while a break is running.
- **Blocked feeds** — per-target switches with brand icons; turning one **off** needs the
  sentence and is blocked during the hard schedule.
- A short privacy footer.

**Stats** (what it counted)
- Today's total time in YouTube + Instagram and how many scrolls were blocked.
- Per-app breakdown (time, opens, blocked) and a summary of breaks taken today.
- A seven-day bar chart and a GitHub-style consistency grid. All on-device.

**How it works** (the explanation)
- Why the accessibility layer is needed, the three-step explanation, what TollGate *can't*
  see, the privacy guarantee, and an About card with the app version.

Styling lives in `lib/core/theme/app_theme.dart`; reusable widgets in
`lib/core/widgets/`; each feature owns its own `features/<name>/` folder with a screen and
its `widgets/`. Widgets read styling through `Theme.of(context)`. The launcher icon is an
adaptive icon (a shield with a "back" arrow): see
`android/app/src/main/res/mipmap-anydpi-v26/` and the `ic_launcher_*` drawables.

### Running the UI tests

The widget tests render every screen state into a narrow phone viewport and fail on any
layout overflow, so they run without a device:

```bash
flutter test
```

## Testing on your phone

> **Toolchain already installed on this machine** (no sudo needed):
> - Flutter 3.47.7 → `~/development/flutter`
> - JDK 17 (Temurin) → `~/development/jdk-17`
> - Android SDK → `~/Android/Sdk`
>
> `~/.bashrc` was updated, so a fresh terminal has `flutter`/`adb` on `PATH` and
> `JAVA_HOME`/`ANDROID_HOME` set. If you're in a shell opened before this was added,
> run `source ~/.bashrc` or open a new terminal.
>
> Build the installable APK with:
> ```bash
> cd ~/Desktop/vibecode/TollGate
> flutter build apk --release
> # → build/app/outputs/flutter-apk/app-release.apk
> ```

There is **no Expo Go for Flutter** (Flutter compiles to native code; there is no runtime
shell to inject into). The normal workflow replaces it:

### First time

1. On the phone: **Settings → About phone → tap "Build number" 7 times** to unlock
   Developer options.
2. **Settings → Developer options → USB debugging → On.**
3. Plug the phone into this computer and accept the "Allow USB debugging?" prompt.
4. Verify: `flutter devices` shows your phone.

### Daily development (hot reload)

```bash
flutter run            # pick your device if more than one
```
While running: press `r` to hot reload, `R` to hot restart, `q` to quit.

> Hot reload only applies to Dart/UI. **Changes to the Kotlin blocker require a full
> rebuild** — stop and `flutter run` again.

### Wireless (Android 11+, no cable)

```bash
adb pair <ip>:<port>    # code shown in Developer options → Wireless debugging
adb connect <ip>:<port>
flutter run
```

### Build an installable APK (test the real thing)

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```
Copy it to the phone and tap to install (allow "install unknown apps"), or
`adb install -r build/app/outputs/flutter-apk/app-release.apk`.

Test the blocker against a **release** build on a **physical device** — emulators and
debug builds behave differently for background services.

### On the phone, after installing

> Android 13+ blocks enabling an accessibility service for a freshly sideloaded app.
> If the toggle is greyed out: **Settings → Apps → TollGate → ⋮ → "Allow restricted
> settings"**, then try again.

1. Open TollGate → **Open accessibility settings** → enable **TollGate Short Block**.
2. Back in the app, the status should say **Protecting**; tap **Turn on protection**.
3. Open YouTube → swipe into a Short → you should be bounced back. Normal videos still play.
4. Same for Instagram → Reels tab.
5. To take a break, tap **Take a break** and type the sentence. The pinned notification
   appears; it disappears when you re-block or the budget runs out.

## Phase 1 scope

- [x] Per-target blocking (YouTube Shorts, Instagram Reels) with view-id detection
- [x] Accessibility permission onboarding that reflects the *real* OS state
- [x] Silent auto-back blocking with event throttling
- [x] Settings persisted and re-armed after reboot
- [x] On-device stats: time in app, opens, and scrolls blocked (no extra permission)
- [x] Commitment layer: daily break budget, typed phrase, hard schedule, pinned notice
- [x] Consistency grid (GitHub-style) on the Stats tab
- [ ] Phase 2 candidates: "blocked" overlay with a breathing pause, TikTok/Facebook,
      quick-settings tile, battery-optimisation nudge, Device-Owner hardening

## Known limitations

Resource ids are internal to the target apps and **rotate between releases**. Detection
is best-effort: if a target app ships a redesign, the marker lists in `TargetApp.kt`
need updating. This is inherent to the approach — any app claiming otherwise is
overselling.
