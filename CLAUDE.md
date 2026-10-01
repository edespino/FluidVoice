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

Upstream `main` ships betas. Sync on 2026-10-01 moved 1.6.10 (build 22) to 1.6.10-beta.7 (build 26), 250 commits.

## Build and install

No Apple Development cert on this Mac. Unsigned only.

```
cd /Users/eespino/workspace/FluidVoice
git checkout local/spoken-send-terminals
./build.sh unsigned
ditto "DerivedData/Build/Products/Debug/FluidVoice Debug.app" "/Applications/FluidVoice Debug.app"
open "/Applications/FluidVoice Debug.app"
```

Quit FluidVoice Debug before `ditto` if it is running.

Unsigned builds are ad-hoc linker-signed. Each rebuild has a new code hash, so macOS privacy grants can drop. Re-grant for FluidVoice Debug (`com.FluidApp.app.debug`), not `com.FluidApp.app`.

Microphone after rebuild (seen 2026-10-01):
- Symptom: hotkey seems dead. `Fluid.log` shows `Hotkey route ... action=start` then `START() blocked - mic not authorized` on every press.
- The hotkey path never prompts for the mic. Reset, relaunch, then grant from the UI:
  1. `tccutil reset Microphone com.FluidApp.app.debug`
  2. Quit and reopen FluidVoice Debug.
  3. Settings, Dictation, Grant Access (or Dashboard, Finish setup, Microphone). Allow.
- Success in log: `reason=permission_granted`, then `START() completed successfully`.

Accessibility can also drop. Hotkey events in the log mean the event tap works; delivery failures mean re-grant Accessibility.

The `build.log` line `No locator class for device extension 'Xcode.Device.CoreDevice', error: ...` is an Xcode plugin message. Ignore it; check for `** BUILD SUCCEEDED **`.

The main window may open on the left display (DELL U2720Q), behind other windows. Click FluidVoice Debug in the Dock to bring it forward. 1.6.10-beta UI: Dashboard replaces Getting Started; Settings split into pages (Dictation, Shortcuts, ...).

Rebuild in this repo does not update `/Applications`. Recopy with `ditto` after each build.

Cask was removed with `brew uninstall --cask fluidvoice`. Restore with `brew install --cask fluidvoice` if needed.

## Spoken Send (as configured)

- Enabled. Phrase: `send it`. Key: Enter.
- Send Immediately: off. Phrase still sends after the hotkey stops recording.
- Empty phrase does not mean always-Enter.
- Speech model in Debug prefs: Parakeet TDT v2.
- Primary hotkey in Debug prefs: Left Control (keyCode 59). Keychron K6 bottom-left Control. Not Right Command.
- Debug prefs domain: `com.FluidApp.app.debug`.

Verified 2026-10-01 in Ghostty: "..., send it." pasted the text, then pressed Enter. Log outcome `insertedAndActionDispatched`.

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

## AI enhancement

OSS Debug has no Fluid Intelligence (`fluid-1`).
If needed: FluidVoice Debug window, Configure, AI Providers, Groq.
Do not use Hermes xAI OAuth as the FluidVoice key.

## Not done

- Always-Enter after every recording
- Second hotkey that submits
- Signed builds
- Allowlisting Hermes/Ghostty instead of `return false` for every terminal
