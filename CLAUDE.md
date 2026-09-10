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

## Sync main, then rebase the patch branch

```
cd /Users/eespino/workspace/FluidVoice
./sync-from-upstream.sh
```

Fast-forwards `main` from `upstream/main`, pushes `origin/main`, rebases `local/spoken-send-terminals` onto `main`, force-with-lease pushes the patch branch. Aborts if the working tree is dirty. On conflict, keep `isSpokenSendBlockedApp` returning false, then `git rebase --continue` and `git push --force-with-lease origin local/spoken-send-terminals`.

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

Unsigned rebuilds can drop Accessibility. Re-grant for FluidVoice Debug (`com.FluidApp.app.debug`), not `com.FluidApp.app`.

Rebuild in this repo does not update `/Applications`. Recopy with `ditto` after each build.

Cask was removed with `brew uninstall --cask fluidvoice`. Restore with `brew install --cask fluidvoice` if needed.

## Spoken Send (as configured)

- Enabled. Phrase: `send it`. Key: Enter.
- Send Immediately: off. Phrase still sends after the hotkey stops recording.
- Empty phrase does not mean always-Enter.
- Speech model in Debug prefs: Parakeet TDT v2.
- Primary hotkey in Debug prefs: Left Control (keyCode 59). Keychron K6 bottom-left Control. Not Right Command.
- Debug prefs domain: `com.FluidApp.app.debug`.

## AI enhancement

OSS Debug has no Fluid Intelligence (`fluid-1`).
If needed: FluidVoice Debug window, Configure, AI Providers, Groq.
Do not use Hermes xAI OAuth as the FluidVoice key.

## Not done

- Always-Enter after every recording
- Second hotkey that submits
- Signed builds
- Allowlisting Hermes/iTerm instead of `return false` for every terminal
