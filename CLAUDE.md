# FluidVoice fork (edespino)

This checkout is a fork of `altic-dev/FluidVoice` with two branches.

- Fork: `https://github.com/edespino/FluidVoice`
- Upstream: `https://github.com/altic-dev/FluidVoice`
- Remotes: `origin` = fork, `upstream` = altic-dev
- `main`: clean mirror of `upstream/main`. Default branch. Local `main` tracks `upstream/main`.
- `local/spoken-send-terminals`: the Spoken Send terminal patch. Build this.

Do not open a PR to altic-dev. Spoken Send Enter in a real shell can execute a command.
GitHub "Sync fork" is safe only onto `main`. Never sync into `local/spoken-send-terminals`.

`AGENTS.md` is gitignored upstream. This file is the agent/operator note for the fork.

## Patch

File: `Sources/Fluid/ContentView.swift`
Function: `isSpokenSendBlockedApp`
Change: always return `false`.

Upstream blocks Terminal, iTerm, Warp, Ghostty, Kitty, Alacritty so Spoken Send cannot execute a shell command. This Debug build allows terminals so Hermes CLI can receive Enter. Same risk in a real shell.

Hermes CLI runs in Ghostty (previously iTerm).

## Sync main, then rebase the patch branch

```
cd /Users/eespino/workspace/FluidVoice
./sync-from-upstream.sh
```

Fast-forwards `main` from `upstream/main`, pushes `origin/main`, rebases `local/spoken-send-terminals` onto `main`, force-with-lease pushes the patch branch. Aborts if the working tree is dirty. On conflict, keep `isSpokenSendBlockedApp` returning false, then `git rebase --continue` and `git push --force-with-lease origin local/spoken-send-terminals`.

The script fetches only `upstream main`. Upstream has branches differing only by case (`B/...` vs `b/...`). A full `git fetch upstream` exits 1 on case-insensitive APFS and aborts the script under `set -e`. Do not use `git refs migrate --ref-format=reftable` (changes repo config).

Preview before syncing: `git fetch upstream main && git log --oneline main..upstream/main`. Test the patch rebase without touching branches: `git merge-tree --write-tree --name-only upstream/main local/spoken-send-terminals`.

Upstream `main` ships betas. Sync on 2026-10-01 moved 1.6.10 (build 22) to 1.6.10-beta.7 (build 26), 250 commits. Sync on 2026-10-30 moved 1.6.10-beta.7 (build 26) to 1.6.13-beta.1 (build 31), 54 commits; patch rebased without conflict.

## Build and install

No Apple Development cert on this Mac. Unsigned only.

```
cd /Users/eespino/workspace/FluidVoice
git checkout local/spoken-send-terminals
./build.sh unsigned
ditto "DerivedData/Build/Products/Debug/FluidVoice Debug.app" "/Applications/FluidVoice Debug.app"
open "/Applications/FluidVoice Debug.app"
```

Quit FluidVoice Debug before `ditto` if it is running: `osascript -e 'tell application "FluidVoice Debug" to quit'`. Wait for the process to exit before `open`; opening while it is still terminating fails with `_LSOpenURLsWithCompletionHandler() failed with error -609`.

Metal Toolchain required. Upstream `87d2655c` (#1206, synced 2026-10-30) added `Sources/Fluid/UI/DictionaryVoiceWave.metal`. Without the toolchain the build fails with `error: cannot execute tool 'metal' due to missing Metal Toolchain`. Install: `xcodebuild -downloadComponent MetalToolchain` (838.9 MB). Installed 2026-10-30: Metal Toolchain 27B47 for Xcode 27.2 (27B52). Check: `xcrun metal --version`.

Unsigned builds are ad-hoc linker-signed. Each rebuild has a new code hash, so macOS privacy grants can drop. Re-grant for FluidVoice Debug (`com.FluidApp.app.debug`), not `com.FluidApp.app`.

Microphone after rebuild (seen 2026-10-01):
- Symptom: hotkey seems dead. `Fluid.log` shows `Hotkey route ... action=start` then `START() blocked - mic not authorized` on every press.
- The hotkey path never prompts for the mic. Reset, relaunch, then grant from the UI:
  1. `tccutil reset Microphone com.FluidApp.app.debug`
  2. Quit and reopen FluidVoice Debug.
  3. Settings, Dictation, Grant Access (or Dashboard, Finish setup, Microphone). Allow.
- Success in log: `reason=permission_granted`, then `START() completed successfully`.
- 2026-10-30 (macOS 27.2, 1.6.13-beta.1): after reset and relaunch, no macOS prompt appeared; log showed `reason=permission_granted`. Open the pane directly: `open "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"`.

Accessibility can also drop. Hotkey events in the log mean the event tap works; delivery failures mean re-grant Accessibility.
- Missing: `[GlobalHotkeyManager] Accessibility permissions not granted` about every 0.5 s.
- Granted: `Event tap successfully created and enabled`. On 2026-10-30 this appeared in the running process after the re-grant; no relaunch needed.
- Open the pane directly (same URL the app uses): `open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"`. On macOS 27.2 the System Settings menu path is not documented here; use the URL.

Keychain prompt after rebuild (seen 2026-10-30): "FluidVoice Debug wants to use your confidential information stored in "com.fluidvoice.provider-api-keys" in your keychain."
- Password: the login keychain password (Mac login password). Click Always Allow.
- Item: login keychain, generic password, service `com.fluidvoice.provider-api-keys`, account `fluidApiKeys`. Holds a JSON map of AI provider API keys (`KeychainService.swift`). Groq key last modified 2026-10-01.
- The keychain item trusts the binary that created or last allowed it. Each unsigned rebuild has a new code hash, so the prompt returns.
- Deny: untested. Expected to disable AI providers (Groq) only; dictation cleanup is off.

The `build.log` lines `No locator class for device extension 'Xcode.Device.CoreDevice', error: ...` and `CoreSimulator is out of date ... Simulator device support disabled.` are Xcode messages. Ignore them; check for `** BUILD SUCCEEDED **`.

The main window may open on the left display (DELL U2720Q), behind other windows. Click FluidVoice Debug in the Dock to bring it forward. 1.6.10-beta UI: Dashboard replaces Getting Started; Settings split into pages (Dictation, Shortcuts, ...).

Rebuild in this repo does not update `/Applications`. Recopy with `ditto` after each build.

Cask was removed with `brew uninstall --cask fluidvoice`. Restore with `brew install --cask fluidvoice` if needed.

## Spoken Send (as configured)

- Enabled. Phrase: `send it`. Key: Enter.
- Send Immediately: on (since 2026-10-01). Hotkey mode: toggle (`HotkeyMode = toggle`).
- With Send Immediately off, the phrase still sends after the hotkey stops recording.
- Empty phrase does not mean always-Enter.
- Speech model in Debug prefs: Parakeet TDT v2.
- Primary hotkey in Debug prefs: Left Control (keyCode 59). Keychron K6 bottom-left Control. Not Right Command.
- Debug prefs domain: `com.FluidApp.app.debug`.

Verified 2026-10-01 in Ghostty: "..., send it." pasted the text, then pressed Enter. Log outcome `insertedAndActionDispatched`.

2026-10-30, 1.6.13-beta.1: plain dictation verified (clipboard paste into a terminal text area, `outcome=success`). Spoken Send in Ghostty not yet re-verified on this build.

Send Immediately timing (measured 2026-10-01):
- First live partial ending in the phrase starts a fixed 1.5 s countdown (`SpokenSendParser.immediateStopSettleNanoseconds`, `ContentView.swift` `handleSpokenSendPartialTranscription`). Then it needs >= 0.35 s quiet and the phrase still at the end, else it cancels and keeps recording.
- Live partials arrive about every 0.75 s, so phrase detection can lag speech by up to that.
- Phrase detected to Enter: about 1.7 s (1.55 s countdown, ~80 ms final ASR, ~10 ms paste, ~70 ms to Enter).
- Same countdown in every app; no per-app logic.
- Skip the wait: press Left Control right after the phrase (toggle stop, sends at once).
- Shortening it means patching `immediateStopSettleNanoseconds` and `immediateStopSettleDuration` (overlay bar) in `SpokenSendParser.swift`; `SpokenSendTests.swift` uses them. Not done.

Phrase misses: 1 of 13 "send it" dictations on 2026-10-01 came back as "Sandit". Typed as text, not sent (never armed, so no near-miss match). A longer, rarer phrase (e.g. "over and out", "end message") is the candidate fix; untested.

## Text insertion

- `TextInsertionMode` (Settings, Dictation): `reliablePaste` = "Clipboard Paste (Recommended)" (temp clipboard, Cmd+V, restore clipboard). `standard` = "Direct Paste" (key events, no clipboard; clipboard fallback).
- 1.6.10-beta forces `reliablePaste` once on first launch (`TextInsertionModeMigratedToReliablePasteV1`). Does not re-run.
- Ghostty (`com.mitchellh.ghostty`) always uses clipboard paste regardless of mode (`TypingService.swift`). Mode only matters for other apps.
- Spoken Send skips the paste read-back check when Enter follows, so no false "Text wasn't inserted".

## Logs

- App log: `~/Library/Logs/Fluid/Fluid.log` (rotates to `Fluid.log.1`).
- Useful greps: `START()`, `mic not authorized`, `FOCUS_ASSESS`, `TYPING_BENCH`, `PIPELINE_SUMMARY`, `Transcription completed`.
- Saved hotkey: `PrimaryDictationShortcuts` (JSON data). Left Control = `keyCode 59`.
- One-off seen 2026-10-01: capture start stalled 2.7 s, then `Direct Core Audio capture failed ... CancellationError` on key release. Next attempt worked. Investigate if it repeats.
- One-off seen 2026-10-30: the running 1.6.10-beta.7 instance logged repeated `Failed to create CGEvent tap`, then `Application will terminate` at 11:51:41, during a build, with no quit sent. Cause unknown.

## Analytics

- PostHog key is in `Info.plist`; no Debug-build exemption. Batches go to `eu.i.posthog.com`.
- "Share Detailed Anonymous Analytics" (`ShareAnonymousAnalytics`) is unset, so on by default.
- Turning it off stops detailed events only; basic activity is still recorded (`AnalyticsService.swift` `writeDetailed` `fallbackActivity`). Stopping all analytics needs the key removed from `Info.plist` in the fork patch. Not done.
- Automatic Updates is off (`AutoUpdateCheckEnabled = 0`). Keep off: updater checks altic-dev releases, which lack the terminal patch.

## AI enhancement

OSS Debug has no Fluid Intelligence (`fluid-1`).
If needed: FluidVoice Debug window, Configure, AI Providers, Groq.
Do not use Hermes xAI OAuth as the FluidVoice key.

State 2026-10-01: Groq verified, model `openai/gpt-oss-120b`. Dictation cleanup off (`DictationPromptOff = 1`; log `aiMs=-1`). Providers are used only for dictation cleanup, Command Mode, and Rewrite (chat completions); never for transcription. Spoken Send strips the phrase before AI; if AI fails, text is typed but not sent. If cleanup is wanted for prose apps, scope it to "selected apps only" so Ghostty stays raw.

## Not done

- Always-Enter after every recording
- Second hotkey that submits
- Signed builds
- Allowlisting Hermes/Ghostty instead of `return false` for every terminal
