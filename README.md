# omarchy-bb-theme-sync

`omarchy-bb-theme-sync` is a small Omarchy-to-BB integration. It is not a BB
plugin. When an Omarchy theme changes, it reads that theme's `colors.toml`,
generates one stable BB custom palette named `omarchy-sync`, and activates it
with `bb theme set`.

[![Verify](https://github.com/mikhaiIy/omarchy-bb-theme-sync/actions/workflows/verify.yml/badge.svg)](https://github.com/mikhaiIy/omarchy-bb-theme-sync/actions/workflows/verify.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`omarchy-bb-theme-sync` is intentionally small: it owns one stable palette,
`omarchy-sync`, and never mutates BB's other themes. The integration is useful
for anyone who wants a BB window to follow the active Omarchy desktop theme.

## Architecture

```text
Omarchy theme change
        ↓
~/.config/omarchy/hooks/theme-set.d/omarchy-bb-theme-sync
        ↓
bin/omarchy-bb-theme-sync sync <theme-slug>
        ↓
read <user-theme>/colors.toml or <stock-theme>/colors.toml
        ↓
map colours → BB CSS variables
        ↓
write <bb-theme-dir>/omarchy-sync/theme.css atomically
        ↓
bb theme set omarchy-sync
```

The command supports a normal `bb` on `PATH`, a packaged BB installation, and
the CLI exposed by a running BB AppImage. A dry run never writes to BB.

## What the integration guarantees

- Stock Omarchy files are read-only to this project.
- The generated theme has one stable id, so old generated files do not accumulate.
- The stylesheet is written to a temporary file and renamed into place.
- Installation and removal only manage symlinks that point to this checkout.
- Uninstall refuses to remove an unmarked theme or an active `omarchy-sync` theme.

## Project layout

```text
bin/omarchy-bb-theme-sync                 Main CLI and theme generator
hooks/theme-set.d/omarchy-bb-theme-sync   Omarchy change hook
install.sh                                  Safe symlink installer
uninstall.sh                                Scoped uninstaller
tests/verify.sh                             Isolated end-to-end verification
tests/fixtures/                             Portable colour fixture
```

## Requirements

- Bash, `awk`, `sed`, `tr`, `mktemp`, `mv`, `mkdir`, and other usual POSIX-ish
  shell utilities.
- Omarchy with `omarchy theme current` and the `theme-set.d` hook directory.
- BB with `bb theme dir` and `bb theme set`. A normal `bb` command on `PATH`
  is preferred. For packaged BB installs, the command can discover the CLI
  exported by the running app or stored in its versioned app bundle.

No TOML parser, package manager, `sudo`, or changes under `/usr/share/omarchy`
are required.

## Quick install

From a checked-out copy of this project, run:

```sh
./install.sh
```

The installer creates two symlinks:

```text
~/.local/bin/omarchy-bb-theme-sync
~/.config/omarchy/hooks/theme-set.d/omarchy-bb-theme-sync
```

The symlinks point back to this checkout. This makes updating the checkout
enough to update the integration. Existing non-symlink paths are never
overwritten. Installation does not generate a theme, activate BB, or edit the
current user's live configuration; run a sync explicitly when ready.

## Automatic behavior

Omarchy passes the changed theme slug as the first argument to a
`theme-set.d` hook. The hook invokes the sync command with that slug. The
effective colors file is resolved in this order:

1. `~/.config/omarchy/themes/<slug>/colors.toml`
2. `/usr/share/omarchy/themes/<slug>/colors.toml`

The generated stylesheet is written atomically to the directory printed by
`bb theme dir`:

```text
<bb-theme-dir>/omarchy-sync/theme.css
```

The command then runs `bb theme set omarchy-sync`, which applies the palette to
open BB windows. The generated theme is overwritten on the next sync; other BB
themes and files are not touched.

For an AppImage-only BB installation, keep the BB desktop app open when a sync
runs. The sync command discovers the bundled CLI from the live AppImage mount
or from the versioned extracted app directory under `~/.local/share/bb-*` and
never stores an update-sensitive path. A standalone `bb` command on `PATH`, an
exported `BB_CLI`, or an explicit `BB_BIN=/path/to/bb` takes precedence.

## Manual sync and status

After installation, either form works:

```sh
omarchy-bb-theme-sync matte-black
omarchy-bb-theme-sync sync matte-black
```

With no slug, the command uses `omarchy theme current` and slugifies its display
name, such as `Matte Black` to `matte-black`:

```sh
omarchy-bb-theme-sync
```

Useful safe checks:

```sh
omarchy-bb-theme-sync --dry-run matte-black > /tmp/omarchy-sync.css
omarchy-bb-theme-sync sync matte-black --no-activate
omarchy-bb-theme-sync status
```

`--dry-run` prints CSS without writing BB data. `--no-activate` writes the
generated CSS but does not select it.

## Uninstall

From the same checkout:

```sh
./uninstall.sh
```

This removes only symlinks that point to this checkout and leaves the generated
BB theme in place. To also remove the generated `omarchy-sync` stylesheet:

```sh
./uninstall.sh --remove-theme
```

Removal is limited to a stylesheet marked as generated by this project, refuses
to remove an unmarked theme, and refuses to remove `omarchy-sync` while BB
reports it as active. Uninstall never changes BB's active theme for you.

## Supported color mapping

The source is the simple top-level scalar format used by Omarchy's
`colors.toml`; values must be six-digit hex colors. The main mappings are:

| Omarchy color | BB token(s) |
| --- | --- |
| `background`, `foreground` | `--canvas`, `--ink` |
| `accent` | `--primary`, `--file-accent` |
| `selection`, `muted` | selected and muted BB surfaces |
| `red`, `yellow`, `orange`, `green`, `magenta` | destructive, warning, attention, success, and merged-PR semantics |
| `red`, `green` | diff removed and diff added |
| all named colors and bright variants | `--ansi-0` through `--ansi-15` plus readable ANSI foregrounds |

The generated CSS also sets BB's secondary text tiers (`--muted-foreground`,
`--subtle-foreground`, and `--readback-foreground`), semantic text/fill
foregrounds, file accent, neutral surfaces, borders, focus ring, and sidebar
aliases. Fill foregrounds choose black or white based on the source color;
text-only semantic colors are adjusted toward the canvas for readability.

## Light/dark limitation

BB's light/dark appearance is a separate per-client setting. A custom palette
therefore needs both `:root, .light` and `.dark` blocks. If Omarchy's
`mode = "dark"`, the dark block uses the source neutral palette and the light
block is a deterministic lightened counterpart. For `mode = "light"`, the
light block uses the source palette and the dark block is darkened. An omitted
or unknown mode is inferred from the background brightness.

This preserves the Omarchy hue relationships, but it cannot reproduce a true
designer-authored light counterpart when the Omarchy theme only supplies one
mode. Check both BB appearance modes after installing a new theme.

## Safety and update behavior

- The project only reads stock files under `/usr/share/omarchy/themes`; it
  never edits them.
- The hook and command are installed as symlinks to the checkout, so updates are
  easy to review and roll back by changing the checkout.
- CSS is generated in a temporary file inside the target theme directory and
  renamed into place, avoiding a partially written stylesheet.
- The stable theme id is always `omarchy-sync`; old generated files do not
  accumulate.
- Installation alone has no BB or Omarchy appearance side effects. A sync is an
  explicit activation operation, whether run manually or by a later theme hook.

## Verification and troubleshooting

Run the repeatable local verification:

```sh
./tests/verify.sh
```

It validates Bash syntax, uses the installed Matte Black palette as a copied
fixture, checks user-theme precedence over stock-theme fallback, checks both
CSS mode blocks and ANSI output, verifies activation through a fake BB command,
and exercises the hook. It uses temporary directories and does not modify live
Omarchy or BB data.

For a live diagnosis:

```sh
bb theme dir
omarchy theme current
omarchy-bb-theme-sync status
omarchy-bb-theme-sync --dry-run <theme-slug>
```

If a sync cannot find a theme, check that the slug directory contains a
`colors.toml`. If the hook does not run, check that the symlink exists under
`~/.config/omarchy/hooks/theme-set.d/`, is executable, and that the checkout
still exists. If BB does not apply the result, run `bb theme dir` and
`bb theme list` to verify that `omarchy-sync/theme.css` is under BB's reported
custom-theme directory. If the command says BB is not found and you use the
BB AppImage, open BB first. Otherwise install its CLI on `PATH` or set
`BB_BIN` to the absolute path of a stable BB CLI executable. For a non-standard
extracted install root, set `OMARCHY_BB_APP_DATA_ROOT` to the directory
containing `bb-<version>` folders.
