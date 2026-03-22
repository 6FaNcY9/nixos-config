# Qutebrowser Color Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add targeted color overrides to `qutebrowser.nix` so all UI areas match the Gruvbox Dark Pale palette using Option B (subtle warm — orange accents via text, not filled blocks).

**Architecture:** Single file change — extend `programs.qutebrowser.settings` in `home-modules/features/desktop/qutebrowser.nix` with ~40 color keys grouped by UI area. Stylix handles the base; we override only where it diverges. All values reference the injected `c` arg (raw base16 slots).

**Tech Stack:** Nix / Home Manager — `programs.qutebrowser.settings` maps directly to qutebrowser's `config.py` settings namespace.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `home-modules/features/desktop/qutebrowser.nix` | Modify | Add color overrides to `settings` block |

---

### Task 1: Tab Bar Colors

**Files:**
- Modify: `home-modules/features/desktop/qutebrowser.nix` — `programs.qutebrowser.settings`

- [ ] **Step 1: Add tab bar color overrides**

Inside `programs.qutebrowser.settings`, add a new `# --- Tab bar ---` section after the existing caret block:

```nix
        # --- Tab bar ---
        # Active tab: bgAlt bg + orange text to match system accent
        # Inactive tabs: primary bg + muted text so they recede
        "colors.tabs.bar.bg" = c.base00;
        "colors.tabs.even.bg" = c.base00;
        "colors.tabs.odd.bg" = c.base00;
        "colors.tabs.even.fg" = c.base03;
        "colors.tabs.odd.fg" = c.base03;
        "colors.tabs.selected.even.bg" = c.base01;
        "colors.tabs.selected.odd.bg" = c.base01;
        "colors.tabs.selected.even.fg" = c.base09;
        "colors.tabs.selected.odd.fg" = c.base09;
        "colors.tabs.indicator.start" = c.base0D;
        "colors.tabs.indicator.stop" = c.base0B;
        "colors.tabs.indicator.error" = c.base08;
```

- [ ] **Step 2: Verify it evaluates**

```bash
just qa
```

Expected: no errors. Fix any Nix syntax issues before continuing.

- [ ] **Step 3: Commit**

```bash
git add home-modules/features/desktop/qutebrowser.nix
git commit -m "feat(qutebrowser): add tab bar color overrides"
```

---

### Task 2: Status Bar Mode Colors

**Files:**
- Modify: `home-modules/features/desktop/qutebrowser.nix` — `programs.qutebrowser.settings`

- [ ] **Step 1: Add status bar mode overrides**

Add after the tab bar block:

```nix
        # --- Status bar modes ---
        # Each mode gets a distinct text color; bg stays dark across all modes.
        # Normal: green | Insert: teal | Command: yellow | Private: pink
        "colors.statusbar.normal.bg" = c.base00;
        "colors.statusbar.normal.fg" = c.base0B;
        "colors.statusbar.insert.bg" = c.base00;
        "colors.statusbar.insert.fg" = c.base0D;
        "colors.statusbar.command.bg" = c.base00;
        "colors.statusbar.command.fg" = c.base0A;
        "colors.statusbar.command.private.bg" = c.base00;
        "colors.statusbar.command.private.fg" = c.base0E;
        "colors.statusbar.private.bg" = c.base01;
        "colors.statusbar.private.fg" = c.base0E;
        "colors.statusbar.progress.bg" = c.base0B;
```

- [ ] **Step 2: Verify it evaluates**

```bash
just qa
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add home-modules/features/desktop/qutebrowser.nix
git commit -m "feat(qutebrowser): add status bar mode color overrides"
```

---

### Task 3: URL Colors

**Files:**
- Modify: `home-modules/features/desktop/qutebrowser.nix` — `programs.qutebrowser.settings`

- [ ] **Step 1: Add URL color overrides**

Add after the status bar modes block:

```nix
        # --- URL colors ---
        # Warm beige default; green=https (secure), yellow=http (warn),
        # orange=hover (callout), red=error
        "colors.statusbar.url.fg" = c.base05;
        "colors.statusbar.url.success.https.fg" = c.base0B;
        "colors.statusbar.url.success.http.fg" = c.base0A;
        "colors.statusbar.url.hover.fg" = c.base09;
        "colors.statusbar.url.error.fg" = c.base08;
```

- [ ] **Step 2: Verify it evaluates**

```bash
just qa
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add home-modules/features/desktop/qutebrowser.nix
git commit -m "feat(qutebrowser): add URL color overrides"
```

---

### Task 4: Completion Popup Colors

**Files:**
- Modify: `home-modules/features/desktop/qutebrowser.nix` — `programs.qutebrowser.settings`

Note: `colors.completion.item.selected.bg/border.top/border.bottom` are **already set** to `c.base02` — do not duplicate them.

- [ ] **Step 1: Add completion popup color overrides**

Add after the existing completion selected-item block (after line `"colors.completion.item.selected.border.bottom" = c.base02;`):

```nix
        # --- Completion popup (extended) ---
        # Alternating rows, orange category headers and match highlights.
        # Selected item bg/borders already set above (base02).
        "colors.completion.fg" = c.base05;
        "colors.completion.odd.bg" = c.base00;
        "colors.completion.even.bg" = c.base01;
        "colors.completion.category.fg" = c.base09;
        "colors.completion.category.bg" = c.base00;
        "colors.completion.category.border.top" = c.base00;
        "colors.completion.category.border.bottom" = c.base01;
        "colors.completion.item.selected.fg" = c.base05;
        "colors.completion.item.selected.match.fg" = c.base09;
        "colors.completion.match.fg" = c.base09;
        "colors.completion.scrollbar.fg" = c.base03;
        "colors.completion.scrollbar.bg" = c.base00;
```

- [ ] **Step 2: Verify it evaluates**

```bash
just qa
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add home-modules/features/desktop/qutebrowser.nix
git commit -m "feat(qutebrowser): add completion popup color overrides"
```

---

### Task 5: Hints, Downloads, Messages, Keyhint

**Files:**
- Modify: `home-modules/features/desktop/qutebrowser.nix` — `programs.qutebrowser.settings`

- [ ] **Step 1: Add remaining UI area color overrides**

Add after the completion block:

```nix
        # --- Hints ---
        # Yellow bg with dark text: high visibility for keyboard navigation
        "colors.hints.bg" = c.base0A;
        "colors.hints.fg" = c.base00;
        "colors.hints.match.fg" = c.base09;

        # --- Downloads bar ---
        # Teal=in progress, green=done, red text=error
        "colors.downloads.bar.bg" = c.base00;
        "colors.downloads.start.fg" = c.base00;
        "colors.downloads.start.bg" = c.base0D;
        "colors.downloads.stop.fg" = c.base00;
        "colors.downloads.stop.bg" = c.base0B;
        "colors.downloads.error.fg" = c.base08;
        "colors.downloads.error.bg" = c.base00;

        # --- Messages ---
        # Info: teal | Warning: yellow | Error: red — each with dark fg for contrast
        "colors.messages.info.bg" = c.base0D;
        "colors.messages.info.fg" = c.base00;
        "colors.messages.info.border" = c.base0D;
        "colors.messages.warning.bg" = c.base0A;
        "colors.messages.warning.fg" = c.base00;
        "colors.messages.warning.border" = c.base0A;
        "colors.messages.error.bg" = c.base08;
        "colors.messages.error.fg" = c.base00;
        "colors.messages.error.border" = c.base08;

        # --- Keyhint overlay ---
        # bgAlt bg so it lifts above content; orange suffix to highlight the key
        "colors.keyhint.bg" = c.base01;
        "colors.keyhint.fg" = c.base05;
        "colors.keyhint.suffix.fg" = c.base09;
```

- [ ] **Step 2: Verify it evaluates**

```bash
just qa
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add home-modules/features/desktop/qutebrowser.nix
git commit -m "feat(qutebrowser): add hints, downloads, messages, keyhint color overrides"
```

---

### Task 6: Apply and Verify

- [ ] **Step 1: Switch Home Manager**

```bash
just home-switch
```

Expected: activation completes without errors.

- [ ] **Step 2: Open qutebrowser and check each area visually**

- Open a new tab — check inactive tabs are muted, active tab has orange text on bgAlt
- Type `:open` — check command mode label is yellow
- Click into a text field — check insert mode label is teal
- Type a URL — check https URL is green, http is yellow
- Press `f` to trigger hints — check yellow bg with dark text
- Open completion (`:`) and type — check orange category headers and match highlights

- [ ] **Step 3: Final commit if any tweaks were needed**

```bash
git add home-modules/features/desktop/qutebrowser.nix
git commit -m "fix(qutebrowser): tweak color overrides after visual check"
```
