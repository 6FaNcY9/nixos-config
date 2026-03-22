# Qutebrowser Color Overhaul — Design Spec

**Date:** 2026-03-22
**File:** `home-modules/features/desktop/qutebrowser.nix`
**Approach:** Stylix + targeted overrides (Option B — subtle warm Gruvbox)

## Goal

Override the Stylix-generated qutebrowser colors so every UI area matches the Gruvbox Dark Pale system palette. Style direction: subtle warmth — orange accents via text/underline, not filled blocks.

## Palette Reference

All values come from `c.*` args already injected via `_module.args`. No hardcoded hex.

| Slot | Value | Role |
|------|-------|------|
| base00 | #262626 | bg — primary background |
| base01 | #3a3a3a | bgAlt — secondary background |
| base02 | #4e4e4e | selection background |
| base03 | #8a8a8a | muted text |
| base05 | #dab997 | text — warm beige |
| base08 | #d75f5f | red — danger/error |
| base09 | #ff8700 | orange — active accent |
| base0A | #ffaf00 | yellow — warning/command |
| base0B | #afaf00 | green — success/normal mode |
| base0C | #85ad85 | sage — unused here |
| base0D | #83adad | teal — insert mode / caret (already set) |
| base0E | #d485ad | pink — private mode |

## Color Assignments by Area

### Tab Bar

| Key | Value | Reason |
|-----|-------|--------|
| `colors.tabs.bar.bg` | base00 | match window bg |
| `colors.tabs.even.bg` | base00 | inactive tabs blend with bar |
| `colors.tabs.odd.bg` | base00 | same |
| `colors.tabs.even.fg` | base03 | muted — inactive tabs recede |
| `colors.tabs.odd.fg` | base03 | same |
| `colors.tabs.selected.even.bg` | base01 | subtle lift from bg |
| `colors.tabs.selected.odd.bg` | base01 | same |
| `colors.tabs.selected.even.fg` | base09 | orange — active tab pops |
| `colors.tabs.selected.odd.fg` | base09 | same |
| `colors.tabs.indicator.start` | base0D | teal while loading |
| `colors.tabs.indicator.stop` | base0B | green when done |
| `colors.tabs.indicator.error` | base08 | red on error |

### Status Bar

| Key | Value | Reason |
|-----|-------|--------|
| `colors.statusbar.normal.bg` | base00 | dark, unobtrusive |
| `colors.statusbar.normal.fg` | base0B | green mode label |
| `colors.statusbar.insert.bg` | base00 | same bg across modes |
| `colors.statusbar.insert.fg` | base0D | teal — distinct from normal |
| `colors.statusbar.command.bg` | base00 | same bg |
| `colors.statusbar.command.fg` | base0A | yellow — command mode |
| `colors.statusbar.command.private.bg` | base00 | same bg |
| `colors.statusbar.command.private.fg` | base0E | pink — private |
| `colors.statusbar.private.bg` | base01 | slightly lifted to signal mode |
| `colors.statusbar.private.fg` | base0E | pink |
| `colors.statusbar.progress.bg` | base0B | green progress bar |

Caret colors already set (`base0D` bg, `base00` fg) — kept as-is.

### URL Colors

| Key | Value | Reason |
|-----|-------|--------|
| `colors.statusbar.url.fg` | base05 | warm beige default |
| `colors.statusbar.url.success.https.fg` | base0B | green — secure |
| `colors.statusbar.url.success.http.fg` | base0A | yellow — warn, not secure |
| `colors.statusbar.url.hover.fg` | base09 | orange — hover callout |
| `colors.statusbar.url.error.fg` | base08 | red — error |

### Completion Popup

Selected item bg/borders already set (`base02`) — extended with:

| Key | Value | Reason |
|-----|-------|--------|
| `colors.completion.fg` | base05 | readable warm text |
| `colors.completion.odd.bg` | base00 | alternating rows |
| `colors.completion.even.bg` | base01 | slight contrast |
| `colors.completion.category.fg` | base09 | orange category headers stand out |
| `colors.completion.category.bg` | base00 | stays dark |
| `colors.completion.category.border.top` | base00 | no visible border |
| `colors.completion.category.border.bottom` | base01 | subtle separator |
| `colors.completion.item.selected.fg` | base05 | readable on base02 |
| `colors.completion.item.selected.match.fg` | base09 | orange match highlight |
| `colors.completion.match.fg` | base09 | orange for unselected matches |
| `colors.completion.scrollbar.fg` | base03 | muted scrollbar |
| `colors.completion.scrollbar.bg` | base00 | blends with bg |

### Hints

| Key | Value | Reason |
|-----|-------|--------|
| `colors.hints.bg` | base0A | yellow — high visibility |
| `colors.hints.fg` | base00 | dark text on yellow |
| `colors.hints.match.fg` | base09 | orange for typed chars |

### Downloads Bar

| Key | Value | Reason |
|-----|-------|--------|
| `colors.downloads.bar.bg` | base00 | match status bar |
| `colors.downloads.start.fg` | base00 | dark text on teal |
| `colors.downloads.start.bg` | base0D | teal — in progress |
| `colors.downloads.stop.fg` | base00 | dark text on green |
| `colors.downloads.stop.bg` | base0B | green — complete |
| `colors.downloads.error.fg` | base08 | red text — error |
| `colors.downloads.error.bg` | base00 | no bg block for errors |

### Messages

| Key | Value | Reason |
|-----|-------|--------|
| `colors.messages.info.bg` | base0D | teal info |
| `colors.messages.info.fg` | base00 | dark text |
| `colors.messages.info.border` | base0D | matching border |
| `colors.messages.warning.bg` | base0A | yellow warning |
| `colors.messages.warning.fg` | base00 | dark text |
| `colors.messages.warning.border` | base0A | matching border |
| `colors.messages.error.bg` | base08 | red error |
| `colors.messages.error.fg` | base00 | dark text |
| `colors.messages.error.border` | base08 | matching border |

### Keyhint

| Key | Value | Reason |
|-----|-------|--------|
| `colors.keyhint.bg` | base01 | slightly lifted bg |
| `colors.keyhint.fg` | base05 | warm beige text |
| `colors.keyhint.suffix.fg` | base09 | orange suffix highlight |

## Implementation

All overrides go into `programs.qutebrowser.settings` in `qutebrowser.nix` using the existing `c` arg. No new imports needed. Existing caret, completion selected-bg, and context menu overrides are kept.

Context menu already set (`base02` bg, `base05` fg) — no change needed.

## Out of Scope

- Webpage dark mode settings (already configured)
- Cloudflare / privacy settings (handled separately)
- Font changes
