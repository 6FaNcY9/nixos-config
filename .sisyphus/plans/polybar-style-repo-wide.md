# Polybar Style Repo-Wide + KISS Repo Cleanup

## TL;DR

> **Quick Summary**: Unify the visual theme across the entire nixos-config repo using the Polybar two-tone block-segment motif as the design anchor. Promote hardcoded color tokens to the shared palette, restyle i3 focus/tabs, align tmux + starship to the block motif, and do a moderate KISS restructure of the home-modules layout.
>
> **Deliverables**:
> - Expanded shared palette with "bright alt" tokens
> - i3 focus borders + tabbed/stacking titlebars using `palette.accent`
> - tmux status line restyled with block segments
> - starship prompt minor alignment
> - Polybar + rofi deduplicated onto shared palette tokens
> - Moderate home-modules restructure (move stray flat files into category dirs)
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Task 1 (branch) -> Task 2 (palette) -> Tasks 3-6 (consumers) -> Task 7 (restructure) -> Task 8 (verify)

---

## Context

### Original Request
Apply the Polybar visual style (two-tone block segments, palette-driven colors, Iosevka fonts) across the entire nixos-config repo. Improve i3 focus visibility and tabbed/stacking bars. Moderate repo restructuring following KISS.

### Interview Summary
**Key Discussions**:
- Theme scope: Desktop + Terminal/CLI (not just desktop widgets)
- Apply to both Home Manager and NixOS host(s)
- Restructure: moderate — move files + update imports, not sweeping
- Verification: `nix flake check` / `nix eval` only
- Polybar "block segment" motif mirrored in tmux + starship
- Hardcoded "alt" hex colors promoted to shared palette tokens
- i3 focus highlight switched from `palette.warn` to `palette.accent`
- i3 titlebars: clean default + per-container keybinding toggle (`border toggle`)
- i3 package: upstream `pkgs.i3` already includes gaps (since 4.22), no change needed
- Git workflow: create `newdev` branch from clean `main` HEAD

**Research Findings**:
- Shared palette (`shared-modules/palette.nix`) already defines `bg/bgAlt/text/accent/accent2/warn/danger/muted`
- 5 hardcoded "alt" hex colors in `home-modules/desktop/polybar/colors.nix` and 2 in `home-modules/desktop/rofi/default.nix`
- Fonts centralized via Stylix (`IosevkaTerm Nerd Font`); polybar uses plain `Iosevka Term` + FA6 deliberately
- `_module.args` injects `c`, `palette`, `stylixFonts`, `i3Pkg`, `cfgLib`, `workspaces` to all home modules
- Desktop modules gated by `config.profiles.desktop`; NixOS roles by `config.roles.desktop`
- tmux status line already palette-driven but uses inline separators, not block segments
- starship already uses `c.base01` background — close to block motif, minor tweaks only
- Alacritty colors managed by Stylix target — no manual color config needed
- dunst, picom, flameshot already palette-aligned — no changes needed

### Metis Review
**Identified Gaps** (addressed):
- i3 titlebar toggle semantics clarified: per-container (`border toggle`) — simple, no config-reload hacks
- CLI scope locked: tmux + starship only (not fzf/bat/zsh/etc.)
- Palette token naming: use `palette.bright.*` pattern to keep KISS
- Restructure limited to moving stray flat modules into existing category dirs
- Font/icon collisions: keep polybar's deliberate plain-Iosevka + FA6 exception unchanged
- Rofi `element-bg` alpha handling: keep as rofi-local (intentional transparency)
- Contrast: accept theme-defined outcomes (Gruvbox palette inherently has good contrast)

---

## Work Objectives

### Core Objective
Make every visible UI surface (polybar, i3, tmux, starship, rofi) feel like one cohesive theme by centralizing color tokens and applying the Polybar block-segment motif consistently, while keeping the repo simple and well-organized.

### Concrete Deliverables
- `shared-modules/palette.nix` — expanded with `bright.*` tokens
- `home-modules/desktop/polybar/colors.nix` — refactored to use shared `palette.bright.*`
- `home-modules/desktop/rofi/default.nix` — refactored to use shared `palette.bright.*`
- `home-modules/desktop/i3/config.nix` — new focus colors + titlebar font + border toggle keybinding
- `home-modules/terminal/tmux.nix` — status line restyled with block segments
- `home-modules/shell/starship.nix` — minor block-motif alignment
- `home-modules/default.nix` — updated imports after restructure

### Definition of Done
- [ ] `nix flake check` passes (exit code 0)
- [ ] `nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath --raw` returns a store path
- [ ] `nix eval .#homeConfigurations.vino.activationPackage.drvPath --raw` returns a store path (format may vary with flake-parts/ez-configs — adjust eval path if needed)
- [ ] No hardcoded hex colors outside `shared-modules/palette.nix` and explicitly allowed locations

### Must Have
- `palette.accent` as the repo-wide "focused/active" color
- Block-segment motif in polybar, tmux, i3 tabs
- All "alt" colors in shared palette, not scattered across modules
- i3 per-container titlebar toggle keybinding
- All work on `newdev` branch

### Must NOT Have (Guardrails)
- No restyling of apps already handled by Stylix (alacritty, btop, fzf, gtk, qt)
- No new theming frameworks or color-generation pipelines
- No changes to profiles/roles gating semantics
- No font changes to polybar (keep plain Iosevka + FA6 deliberate exception)
- No restructure of `nixos-modules/`, `nixos-configurations/`, or `shared-modules/`
- No changes to `hardware-configuration.nix`, secrets, or flake inputs
- No scope creep into dunst/picom/flameshot (already palette-aligned)
- No "taxonomy overhaul" — only move genuinely stray flat files

---

## Verification Strategy (MANDATORY)

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
>
> ALL tasks in this plan MUST be verifiable WITHOUT any human action.

### Test Decision
- **Infrastructure exists**: YES (nix flake check, treefmt, statix, deadnix)
- **Automated tests**: None (Nix config repo; no unit test framework)
- **Framework**: `nix flake check` + `nix eval` as acceptance gate

### Agent-Executed QA Scenarios (MANDATORY — ALL tasks)

**Verification Tool by Deliverable Type:**

| Type | Tool | How Agent Verifies |
|------|------|-------------------|
| Nix module changes | Bash (`nix flake check`) | Run check, assert exit 0 |
| Nix eval correctness | Bash (`nix eval`) | Eval config outputs, assert store path |
| Hardcoded color audit | Bash (grep) | Search for hex outside allowed files |
| Import correctness | Bash (`nix flake show`) | Assert expected outputs enumerate |

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 0 (Start):
  Task 1: Create newdev branch from main

Wave 1 (Foundation):
  Task 2: Expand shared palette with bright.* tokens

Wave 2 (Consumers — parallel after Wave 1):
  Task 3: Refactor polybar colors to use shared tokens
  Task 4: Refactor rofi colors to use shared tokens
  Task 5: Restyle i3 focus + tabs + titlebar toggle
  Task 6: Restyle tmux + starship block motif

Wave 3 (Cleanup — after Wave 2):
  Task 7: Moderate home-modules restructure
  Task 8: Final verification + commit
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 2-8 | None |
| 2 | 1 | 3, 4, 5, 6 | None |
| 3 | 2 | 7 | 4, 5, 6 |
| 4 | 2 | 7 | 3, 5, 6 |
| 5 | 2 | 7 | 3, 4, 6 |
| 6 | 2 | 7 | 3, 4, 5 |
| 7 | 3, 4, 5, 6 | 8 | None |
| 8 | 7 | None | None |

### Agent Dispatch Summary

| Wave | Tasks | Recommended Agents |
|------|-------|-------------------|
| 0 | 1 | task(category="quick", load_skills=["git-master"]) |
| 1 | 2 | task(category="unspecified-low", load_skills=[]) |
| 2 | 3, 4, 5, 6 | dispatch parallel, task(category="unspecified-low", load_skills=[]) |
| 3 | 7 | task(category="unspecified-low", load_skills=[]) |
| 3 | 8 | task(category="quick", load_skills=["git-master"]) |

---

## TODOs

- [ ] 1. Create `newdev` branch from clean `main` HEAD

  **What to do**:
  - Ensure working tree is clean (stash or commit any WIP)
  - Create and switch to `newdev` branch from current `main` HEAD
  - Verify branch is active

  **Must NOT do**:
  - Do not force-push or reset `main`
  - Do not carry uncommitted changes into `newdev`

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single git operation, trivial task
  - **Skills**: [`git-master`]
    - `git-master`: Safe branch creation workflow

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 0)
  - **Blocks**: Tasks 2-8
  - **Blocked By**: None

  **References**:
  - No file references needed — pure git operation

  **Acceptance Criteria**:

  **Agent-Executed QA Scenarios:**

  ```
  Scenario: Branch newdev exists and is checked out
    Tool: Bash
    Preconditions: Repo at /home/vino/src/nixos-config
    Steps:
      1. git stash --include-untracked (if dirty)
      2. git switch main && git pull --ff-only origin main (if remote exists)
      3. git switch -c newdev
      4. git branch --show-current
      5. Assert: output is "newdev"
      6. git log -1 --oneline
      7. Assert: matches main HEAD
    Expected Result: On newdev branch, identical to main HEAD
    Failure Indicators: Branch already exists error, merge conflicts
  ```

  **Commit**: NO (branch creation only)

---

- [ ] 2. Expand shared palette with `bright.*` tokens

  **What to do**:
  - Edit `shared-modules/palette.nix` to add a `bright` submodule inside the existing `palette` option
  - Add these tokens (derived from Gruvbox bright variants, matching the polybar "alt" colors):
    - `bright.red` — default `"#fb4934"` (currently hardcoded in polybar as `red-alt`)
    - `bright.green` — default `"#b8bb26"` (currently `green-alt`)
    - `bright.yellow` — default `"#fabd2f"` (currently `yellow-alt`)
    - `bright.blue` — default `"#83a598"` (currently `blue-alt`)
    - `bright.aqua` — default `"#8ec07c"` (currently `aqua-alt`)
  - Keep existing palette fields untouched
  - Ensure the new tokens follow the same `lib.mkOption { type = lib.types.str; default = ...; }` pattern

  **Must NOT do**:
  - Do not rename or remove existing palette fields
  - Do not change how `c` (base16 raw colors) is derived
  - Do not add tokens beyond the 5 listed (KISS)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Single-file additive edit to a Nix module
  - **Skills**: `[]`
    - No special skills needed

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 1)
  - **Blocks**: Tasks 3, 4, 5, 6
  - **Blocked By**: Task 1

  **References**:

  **Pattern References**:
  - `shared-modules/palette.nix` — Current palette option definition; follow exact same `lib.mkOption` + `lib.types.str` pattern for new tokens

  **API/Type References**:
  - `shared-modules/palette.nix:options.theme.palette` — The submodule type to extend with `bright.*`

  **Acceptance Criteria**:
  - [ ] `shared-modules/palette.nix` contains `palette.bright.{red,green,yellow,blue,aqua}` options
  - [ ] Each has a string type with a hex default value
  - [ ] `nix flake check` passes (exit 0)

  **Agent-Executed QA Scenarios:**

  ```
  Scenario: Palette bright tokens are evaluable
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. nix flake check
      2. Assert: exit code 0
      3. grep -c "bright" shared-modules/palette.nix
      4. Assert: count >= 5 (one per token)
    Expected Result: Flake check passes, 5 bright tokens defined
    Evidence: Command output captured

  Scenario: No existing palette fields broken
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath --raw
      2. Assert: prints /nix/store/... path (no eval error)
    Expected Result: NixOS config still evaluates
    Evidence: Store path output
  ```

  **Commit**: YES
  - Message: `feat(palette): add bright color tokens for repo-wide theme consistency`
  - Files: `shared-modules/palette.nix`
  - Pre-commit: `nix flake check`

---

- [ ] 3. Refactor polybar colors to use shared `palette.bright.*` tokens

  **What to do**:
  - Edit `home-modules/desktop/polybar/colors.nix`
  - Replace each hardcoded "alt" hex value with the corresponding `palette.bright.*` token:
    - `green-alt = "#b8bb26"` -> `green-alt = palette.bright.green`
    - `yellow-alt = "#fabd2f"` -> `yellow-alt = palette.bright.yellow`
    - `blue-alt = "#83a598"` -> `blue-alt = palette.bright.blue`
    - `aqua-alt = "#8ec07c"` -> `aqua-alt = palette.bright.aqua`
    - `red-alt = "#fb4934"` -> `red-alt = palette.bright.red`
  - Ensure `palette` is available in the module args (it should already be via `_module.args`)

  **Must NOT do**:
  - Do not change other color mappings (the ones already using `palette.*` / `c.*`)
  - Do not modify polybar module definitions or bar layout
  - Do not touch the `black` or `transparent` tokens (those are polybar-local and fine)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Small file edit, direct string replacements
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: Task 2

  **References**:

  **Pattern References**:
  - `home-modules/desktop/polybar/colors.nix` — Current color definitions; shows existing pattern of `palette.*` and `c.*` usage alongside hardcoded hex

  **API/Type References**:
  - `shared-modules/palette.nix:palette.bright.*` — The new tokens to reference (created in Task 2)

  **Acceptance Criteria**:
  - [ ] No hardcoded 6-digit hex values remain in `home-modules/desktop/polybar/colors.nix` except `black = "#000000"` and `transparent = "#00000000"`
  - [ ] `nix flake check` passes (exit 0)

  **Agent-Executed QA Scenarios:**

  ```
  Scenario: No stray hex colors in polybar colors
    Tool: Bash
    Preconditions: On newdev branch, Task 2 committed
    Steps:
      1. grep -E '#[0-9a-fA-F]{6}' home-modules/desktop/polybar/colors.nix
      2. Assert: only matches are "#000000" and/or "#00000000"
      3. grep -c 'palette.bright' home-modules/desktop/polybar/colors.nix
      4. Assert: count >= 5
      5. nix flake check
      6. Assert: exit code 0
    Expected Result: All alt colors reference palette.bright.*, flake passes
    Evidence: grep output + flake check output
  ```

  **Commit**: YES (groups with Task 4)
  - Message: `refactor(polybar,rofi): use shared palette.bright tokens instead of hardcoded hex`
  - Files: `home-modules/desktop/polybar/colors.nix`, `home-modules/desktop/rofi/default.nix`
  - Pre-commit: `nix flake check`

---

- [ ] 4. Refactor rofi colors to use shared `palette.bright.*` tokens

  **What to do**:
  - Edit `home-modules/desktop/rofi/default.nix`
  - Replace hardcoded "alt" hex values with `palette.bright.*`:
    - `yellow-alt = "#fabd2f"` -> `palette.bright.yellow`
    - `red-alt = "#fb4934"` -> `palette.bright.red`
  - Keep the `element-bg = "#1b1b1b"` or similar intentional transparency/alpha values as-is (these are rofi-local design choices, not shared theme tokens)
  - Ensure `palette` is available in module args

  **Must NOT do**:
  - Do not restyle rofi layout or Rasi template structure
  - Do not change rofi's Stylix opt-out (`stylix.targets.rofi.enable = false`)
  - Do not touch colors already using `palette.*` / `c.*`

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Small file edit, 2 replacements
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 3, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: Task 2

  **References**:

  **Pattern References**:
  - `home-modules/desktop/rofi/default.nix` — Current rofi color definitions; shows which values are hardcoded vs palette-driven

  **API/Type References**:
  - `shared-modules/palette.nix:palette.bright.*` — New tokens (Task 2)

  **Acceptance Criteria**:
  - [ ] `yellow-alt` and `red-alt` in rofi reference `palette.bright.*`
  - [ ] `nix flake check` passes (exit 0)

  **Agent-Executed QA Scenarios:**

  ```
  Scenario: Rofi alt colors use shared tokens
    Tool: Bash
    Preconditions: On newdev branch, Task 2 committed
    Steps:
      1. grep 'palette.bright' home-modules/desktop/rofi/default.nix
      2. Assert: at least 2 matches (yellow, red)
      3. grep -E '#fabd2f|#fb4934' home-modules/desktop/rofi/default.nix
      4. Assert: 0 matches (hex removed)
      5. nix flake check
      6. Assert: exit code 0
    Expected Result: Rofi uses shared tokens, flake passes
    Evidence: grep output
  ```

  **Commit**: YES (groups with Task 3)
  - Message: `refactor(polybar,rofi): use shared palette.bright tokens instead of hardcoded hex`
  - Files: `home-modules/desktop/polybar/colors.nix`, `home-modules/desktop/rofi/default.nix`
  - Pre-commit: `nix flake check`

---

- [ ] 5. Restyle i3 focus, tabs, and add titlebar toggle

  **What to do**:
  - Edit `home-modules/desktop/i3/config.nix`:
    - **Focus border color**: Change `focused` border/childBorder/indicator from `palette.warn` to `palette.accent`
    - **Border width**: Increase `window.border` from `2` to `3` for better visibility
    - **Tab/titlebar font**: Add `fonts` config to i3 settings: `{ names = [ "IosevkaTerm Nerd Font" ]; size = 10.0; }` — this controls how tabbed/stacking titlebars look
    - **Focused tab styling**: The `focused` color block already controls tab highlight — switching to `palette.accent` with `c.base00` text makes the active tab pop against the muted unfocused tabs
    - **Focused-inactive distinction**: Make `focusedInactive` more clearly different from `unfocused`: use `c.base01` background (slightly lighter than `c.base00`) so you can tell which container had focus in a split
  - Edit `home-modules/desktop/i3/keybindings.nix`:
    - Add titlebar toggle keybinding: `"${mod}+t" = "border toggle"` — cycles between `none | pixel N | normal` to show/hide titlebars per container

  **Must NOT do**:
  - Do not change i3 package (`pkgs.i3` is correct, gaps included since 4.22)
  - Do not change gap values, floating rules, or workspace assignments
  - Do not add complex titlebar toggle scripts or config-reload hacks
  - Do not change modifier key or reorganize other keybindings

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Focused edits to 2 files in same module
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 3, 4, 6)
  - **Blocks**: Task 7
  - **Blocked By**: Task 2

  **References**:

  **Pattern References**:
  - `home-modules/desktop/i3/config.nix` — Current i3 color definitions (focused/unfocused/urgent), window border, gaps config
  - `home-modules/desktop/i3/keybindings.nix` — Current keybinding structure; follow same `"${mod}+key" = "command"` pattern
  - `home-modules/desktop/polybar/default.nix:font-0` — Reference for font name used repo-wide (Iosevka Term); but for i3 titlebars use the Nerd Font variant since no FA6 conflict applies

  **API/Type References**:
  - `shared-modules/palette.nix:palette.accent` — The focus highlight color
  - Home Manager i3 module: `xsession.windowManager.i3.config.fonts` — Accepts `{ names = [...]; size = N; }`

  **Acceptance Criteria**:
  - [ ] i3 focused color uses `palette.accent` (not `palette.warn`)
  - [ ] `window.border = 3`
  - [ ] `fonts` is set with IosevkaTerm Nerd Font
  - [ ] Keybinding `${mod}+t = "border toggle"` exists
  - [ ] `nix flake check` passes (exit 0)

  **Agent-Executed QA Scenarios:**

  ```
  Scenario: i3 focus color is palette.accent
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. grep 'palette.accent' home-modules/desktop/i3/config.nix
      2. Assert: appears in focused.border, focused.childBorder, focused.indicator
      3. grep 'palette.warn' home-modules/desktop/i3/config.nix
      4. Assert: 0 matches (warn no longer used for focus)
      5. grep 'border toggle' home-modules/desktop/i3/keybindings.nix
      6. Assert: 1 match (the new keybinding)
      7. grep 'IosevkaTerm' home-modules/desktop/i3/config.nix
      8. Assert: at least 1 match (font config)
      9. nix flake check
      10. Assert: exit code 0
    Expected Result: Focus uses accent, toggle binding exists, font set, flake passes
    Evidence: grep outputs

  Scenario: No keybinding conflict on mod+t
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. grep -c 'mod}+t' home-modules/desktop/i3/keybindings.nix
      2. Assert: exactly 1 match (only the new border toggle)
    Expected Result: No existing binding on mod+t
    Evidence: grep count output
  ```

  **Commit**: YES
  - Message: `style(i3): accent-colored focus borders, titlebar font, and border toggle keybinding`
  - Files: `home-modules/desktop/i3/config.nix`, `home-modules/desktop/i3/keybindings.nix`
  - Pre-commit: `nix flake check`

---

- [ ] 6. Restyle tmux status line with block-segment motif + starship minor alignment

  **What to do**:
  - Edit `home-modules/terminal/tmux.nix`:
    - Restyle `status-left` to use solid-background segments with dark (`palette.bg` / `#000000`) foreground text — matching Polybar's "icon-bg + label-bg" two-tone blocks
    - Restyle `status-right` with the same pattern: each info segment (time, host, battery, etc.) gets a colored bg from `palette.*` / `palette.bright.*` with dark text
    - Use simple pipe `|` or space separators between blocks (no powerline glyphs — KISS)
    - Restyle `window-status-current-format` to use `palette.accent` bg with dark text (matching i3 focused = accent)
    - Restyle `window-status-format` to use `palette.muted` or `palette.bgAlt` (matching i3 unfocused)
    - Keep all existing tmux plugins, prefix key, and pane bindings untouched
  - Edit `home-modules/shell/starship.nix`:
    - Minor alignment: ensure the segment background color (`c.base01`) is consistent and the overall feel matches (blocky segments with clear boundaries)
    - If segments already use bg tokens from base16, this may be a no-op; verify and leave unchanged if already aligned
    - Do NOT overhaul starship config — minor tweaks only

  **Must NOT do**:
  - Do not change tmux plugins, prefix key, or terminal settings
  - Do not introduce powerline fonts or complex separator glyphs
  - Do not overhaul starship prompt format or add/remove segments
  - Do not change tmux-which-key configuration

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Focused edits to 2 terminal config files
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 3, 4, 5)
  - **Blocks**: Task 7
  - **Blocked By**: Task 2

  **References**:

  **Pattern References**:
  - `home-modules/terminal/tmux.nix` — Current tmux status line formatting; shows existing `palette.*` usage in `status-left/right` and `window-status-*` formats
  - `home-modules/shell/starship.nix` — Current starship segment formatting; uses `c.baseXX` tokens with `bg:${c.base01}` pattern
  - `home-modules/desktop/polybar/modules.nix` — The Polybar block-segment motif to replicate: colored background, dark/black foreground text, minimal padding

  **API/Type References**:
  - `shared-modules/palette.nix:palette.*` and `palette.bright.*` — Color tokens to use
  - tmux format strings: `#[fg=X,bg=Y,bold]` syntax for styled segments

  **Acceptance Criteria**:
  - [ ] tmux status line uses `palette.*` / `palette.bright.*` for segment backgrounds
  - [ ] tmux active window uses `palette.accent` bg (matching i3 focus)
  - [ ] No powerline glyphs introduced
  - [ ] starship config still uses base16 bg tokens (verify, adjust if needed)
  - [ ] `nix flake check` passes (exit 0)

  **Agent-Executed QA Scenarios:**

  ```
  Scenario: tmux status uses palette tokens for blocks
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. grep -c 'palette\.' home-modules/terminal/tmux.nix
      2. Assert: count >= 8 (multiple segment references)
      3. grep 'palette.accent' home-modules/terminal/tmux.nix
      4. Assert: at least 1 match (active window)
      5. grep -E '\\\\ue0b|\\\\uf0' home-modules/terminal/tmux.nix
      6. Assert: 0 matches (no powerline glyphs)
      7. nix flake check
      8. Assert: exit code 0
    Expected Result: Block segments use palette tokens, no powerline, flake passes
    Evidence: grep outputs

  Scenario: Starship config unchanged or minimally adjusted
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. git diff home-modules/shell/starship.nix | wc -l
      2. Assert: line count < 30 (minor changes only)
      3. grep 'c.base01' home-modules/shell/starship.nix
      4. Assert: at least 1 match (bg token preserved)
    Expected Result: Starship has minimal or no changes
    Evidence: diff stats
  ```

  **Commit**: YES
  - Message: `style(tmux,starship): apply block-segment motif matching polybar theme`
  - Files: `home-modules/terminal/tmux.nix`, `home-modules/shell/starship.nix`
  - Pre-commit: `nix flake check`

---

- [ ] 7. Moderate home-modules restructure

  **What to do**:
  - Review the flat modules currently imported directly by `home-modules/default.nix`:
    - `devices.nix` — device flags (battery, network adapters)
    - `nixpkgs.nix` — nixpkgs config (allowUnfree, etc.)
    - `package-managers.nix` — nix/nh/nix-index config
    - `profiles.nix` — profile definitions (core/dev/desktop)
    - `secrets.nix` — sops-nix HM secrets
  - Create a new category directory `home-modules/core/` for infrastructure/plumbing modules
  - Move these files into `home-modules/core/`:
    - `devices.nix` -> `home-modules/core/devices.nix`
    - `nixpkgs.nix` -> `home-modules/core/nixpkgs.nix`
    - `package-managers.nix` -> `home-modules/core/package-managers.nix`
    - `profiles.nix` -> `home-modules/core/profiles.nix`
    - `secrets.nix` -> `home-modules/core/secrets.nix`
  - Create `home-modules/core/default.nix` that imports all 5 files
  - Update `home-modules/default.nix` to replace the 5 individual imports with a single `./core` import
  - Result: `home-modules/default.nix` imports exactly: `./core`, `./desktop`, `./editor`, `./shell`, `./terminal` (plus external modules stylix/sops/nixvim and shared modules)

  **Must NOT do**:
  - Do not rename files — only move them
  - Do not restructure `nixos-modules/`, `nixos-configurations/`, or `shared-modules/`
  - Do not change module contents — only their file paths and imports
  - Do not create additional category directories beyond `core/`
  - Do not move `desktop/`, `editor/`, `shell/`, `terminal/` — they're already organized

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: File moves + import updates, no logic changes
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 3)
  - **Blocks**: Task 8
  - **Blocked By**: Tasks 3, 4, 5, 6

  **References**:

  **Pattern References**:
  - `home-modules/default.nix` — Current import list; shows the 5 flat files to move and the category dirs to keep
  - `home-modules/desktop/default.nix` — Example of how a category `default.nix` imports its children (follow this pattern for `core/default.nix`)
  - `home-modules/shell/default.nix` — Another example of category default.nix

  **Acceptance Criteria**:
  - [ ] `home-modules/core/` directory exists with `default.nix`, `devices.nix`, `nixpkgs.nix`, `package-managers.nix`, `profiles.nix`, `secrets.nix`
  - [ ] `home-modules/default.nix` imports `./core` instead of 5 individual files
  - [ ] No stray flat `.nix` files remain in `home-modules/` root (except `default.nix`)
  - [ ] `nix flake check` passes (exit 0)
  - [ ] `nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath --raw` returns a store path

  **Agent-Executed QA Scenarios:**

  ```
  Scenario: Restructured imports evaluate correctly
    Tool: Bash
    Preconditions: On newdev branch, all prior tasks committed
    Steps:
      1. ls home-modules/core/
      2. Assert: contains default.nix, devices.nix, nixpkgs.nix, package-managers.nix, profiles.nix, secrets.nix
      3. ls home-modules/*.nix
      4. Assert: only default.nix remains at root level
      5. grep './core' home-modules/default.nix
      6. Assert: 1 match (the new import)
      7. grep -E '\./devices|./nixpkgs|./package-managers|./profiles|./secrets' home-modules/default.nix
      8. Assert: 0 matches (old imports removed)
      9. nix flake check
      10. Assert: exit code 0
      11. nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath --raw
      12. Assert: prints /nix/store/... path
    Expected Result: Clean structure, all evals pass
    Evidence: ls and grep outputs, eval output

  Scenario: No broken imports after moves
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. nix flake show 2>&1
      2. Assert: lists nixosConfigurations.bandit and homeConfigurations (vino or similar)
      3. Assert: no "error" or "undefined" in output
    Expected Result: All flake outputs still enumerate
    Evidence: flake show output
  ```

  **Commit**: YES
  - Message: `refactor(home-modules): move infra modules into core/ directory`
  - Files: `home-modules/core/*`, `home-modules/default.nix`
  - Pre-commit: `nix flake check`

---

- [ ] 8. Final verification and format

  **What to do**:
  - Run full verification suite:
    - `nix flake check` — must pass
    - `nix fmt` — auto-format all Nix files (Alejandra via treefmt)
    - `nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath --raw` — must return store path
    - Hardcoded color audit: `grep -rn '#[0-9a-fA-F]\{6\}' home-modules/ shared-modules/` — only allowed in `shared-modules/palette.nix` fallbacks and `home-modules/desktop/polybar/colors.nix` (for `black` and `transparent`), `home-modules/desktop/rofi/default.nix` (for `element-bg` intentional)
  - If `nix fmt` changes any files, stage and amend the relevant commit or create a format commit
  - Verify git log on `newdev` shows clean commit history

  **Must NOT do**:
  - Do not push to remote unless user requests
  - Do not merge into main
  - Do not run `nixos-rebuild switch` or `home-manager switch`

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Verification commands only, no file edits expected
  - **Skills**: [`git-master`]
    - `git-master`: Clean commit history verification

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 3, final)
  - **Blocks**: None (final task)
  - **Blocked By**: Task 7

  **References**:

  **Documentation References**:
  - `CLAUDE.md` — Documents `nix run .#qa`, `nix fmt`, `nix flake check` as verification commands

  **Acceptance Criteria**:
  - [ ] `nix flake check` exit code 0
  - [ ] `nix fmt` produces no changes (already formatted)
  - [ ] `nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath --raw` returns store path
  - [ ] Hardcoded hex audit passes (only in allowed locations)
  - [ ] `git log --oneline` on `newdev` shows clean, descriptive commits

  **Agent-Executed QA Scenarios:**

  ```
  Scenario: Full flake health check
    Tool: Bash
    Preconditions: On newdev branch, all prior tasks committed
    Steps:
      1. nix flake check
      2. Assert: exit code 0
      3. nix fmt -- --check .
      4. Assert: exit code 0 (no formatting changes needed)
      5. nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath --raw
      6. Assert: output starts with /nix/store/
    Expected Result: All checks green
    Evidence: Command outputs

  Scenario: Hardcoded color audit
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. grep -rn --include='*.nix' -E '#[0-9a-fA-F]{6}' home-modules/ | grep -v 'palette.nix' | grep -v 'polybar/colors.nix.*black\|polybar/colors.nix.*transparent' | grep -v 'rofi/default.nix.*element-bg'
      2. Assert: 0 matches (no stray hardcoded hex)
    Expected Result: All colors are either palette-derived or in explicitly allowed locations
    Evidence: grep output (should be empty)

  Scenario: Clean commit history on newdev
    Tool: Bash
    Preconditions: On newdev branch
    Steps:
      1. git log --oneline main..newdev
      2. Assert: shows commits for palette, polybar/rofi, i3, tmux/starship, restructure
      3. Assert: no "fixup" or "WIP" commits
    Expected Result: Clean, descriptive commit history
    Evidence: git log output
  ```

  **Commit**: YES (only if `nix fmt` changed files)
  - Message: `chore: format nix files`
  - Files: any files changed by `nix fmt`
  - Pre-commit: `nix flake check`

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 2 | `feat(palette): add bright color tokens for repo-wide theme consistency` | `shared-modules/palette.nix` | `nix flake check` |
| 3+4 | `refactor(polybar,rofi): use shared palette.bright tokens instead of hardcoded hex` | `home-modules/desktop/polybar/colors.nix`, `home-modules/desktop/rofi/default.nix` | `nix flake check` |
| 5 | `style(i3): accent-colored focus borders, titlebar font, and border toggle keybinding` | `home-modules/desktop/i3/config.nix`, `home-modules/desktop/i3/keybindings.nix` | `nix flake check` |
| 6 | `style(tmux,starship): apply block-segment motif matching polybar theme` | `home-modules/terminal/tmux.nix`, `home-modules/shell/starship.nix` | `nix flake check` |
| 7 | `refactor(home-modules): move infra modules into core/ directory` | `home-modules/core/*`, `home-modules/default.nix` | `nix flake check` |
| 8 | `chore: format nix files` (if needed) | auto-formatted files | `nix flake check` |

---

## Success Criteria

### Verification Commands
```bash
nix flake check                                    # Expected: exit 0
nix fmt -- --check .                               # Expected: exit 0 (no changes)
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath --raw  # Expected: /nix/store/...
git log --oneline main..newdev                     # Expected: 4-6 clean commits
```

### Final Checklist
- [ ] `palette.bright.*` tokens exist and are used by polybar + rofi
- [ ] i3 focus uses `palette.accent` (not `palette.warn`)
- [ ] i3 has titlebar font + `border toggle` keybinding on `mod+t`
- [ ] tmux status line uses block-segment motif with palette colors
- [ ] starship is aligned (or confirmed already aligned)
- [ ] `home-modules/core/` contains infrastructure modules
- [ ] `home-modules/default.nix` has clean category-based imports
- [ ] No hardcoded hex outside allowed locations
- [ ] All changes on `newdev` branch with clean commit history
- [ ] `nix flake check` passes
