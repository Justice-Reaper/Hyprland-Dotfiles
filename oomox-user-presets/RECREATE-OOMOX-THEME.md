# Oomox/Themix - Tokyo Night Dark User Presets

User presets for [Themix/Oomox](https://github.com/themix-project/themix-gui) that generate a complete Tokyo Night Dark theme for GTK3, GTK4, Qt5, Qt6 and Papirus icons

## Contents

```
presets/
  base16-project/tokyo-night-dark   ← Preset for GTK3 (BG/FG colors swapped)
  tokyo-night-dark-gtk4              ← Preset for GTK4 + Qt5 + Qt6 (real colors)
oomox-patches/
  gtk.scss                           ← Patch: $variant: "dark"
  change_color.sh                    ← Patch: fix symbolic directories in Papirus
```

## Requirements

- [themix-full-git](https://aur.archlinux.org/packages/themix-full-git) (AUR)

```bash
paru -S themix-full-git
```

## Oomox Patches (apply before exporting)

Oomox needs two modifications to its system files so that themes are generated correctly

### 1. Dark variant in SCSS (`gtk.scss`)

The GTK3 SCSS template compiles with `$variant: "light"` by default. This causes backdrop colors to use `darken()` instead of `lighten()`, producing incorrect results for dark themes

Replace the file:

```
/opt/oomox/plugins/theme_oomox/src/gtk-3.20/scss/gtk.scss
```

With the contents of `oomox-patches/gtk.scss` (or simply change the first line from `$variant: "light"` to `$variant: "dark"`)

### 2. Symbolic icons fix in Papirus (`change_color.sh`)

The icon generation script looks for the `Papirus/symbolic` directory which does not exist. Symbolic icons are located inside the size folders (`16x16`, `22x22`, `24x24`)

Replace the file:

```
/opt/oomox/plugins/icons_papirus/change_color.sh
```

With the contents of `oomox-patches/change_color.sh`. The change is on line 149:

```diff
- "$tmp_dir"/Papirus/symbolic
+ "$tmp_dir"/Papirus/{16x16,22x22,24x24}/symbolic
```

## Import the Presets

Copy the presets to the oomox configuration folder:

```bash
cp presets/base16-project/tokyo-night-dark ~/.config/oomox/colors/base16-project/
cp presets/tokyo-night-dark-gtk4 ~/.config/oomox/colors/
```

When opening Themix, they will appear under **User Presets**:

- `base16-project: tokyo-night-dark`
- `tokyo-night-dark-gtk4`

## Export the Themes

### Preset `base16-project: tokyo-night-dark` (GTK3 only)

This preset has the BG/FG, TXT_BG/TXT_FG and BTN_BG/BTN_FG colors **swapped** because the SCSS template with `$variant: "dark"` inverts them during compilation. The remaining colors (HDR, SEL, MENU, ICONS, TERMINAL) use the real Tokyo Night values

Export from Themix:

1. **Theme** (GTK3) → installs to `~/.themes/oomox-tokyo-night-dark/`
2. **Icons** (Papirus) → installs to `~/.icons/oomox-tokyo-night-dark/`

### Preset `tokyo-night-dark-gtk4` (GTK4 + Qt5 + Qt6)

This preset has the **real colors without swap** because the Base16 plugin reads them directly without any variant logic

Export from Themix:

1. **Base16 > gtk4-oodwaita** → generates the CSS for GTK4/libadwaita
2. **Base16 > qt5ct (fusion)** → generates the color scheme for Qt5
3. **Base16 > qt6ct (fusion)** → generates the color scheme for Qt6

## Difference Between the Two Presets

| Field   | `tokyo-night-dark` (GTK3) | `tokyo-night-dark-gtk4` (GTK4/Qt) |
|---------|--------------------------|-----------------------------------|
| BG      | `d8e2ec` (swap)          | `171d23` (real)                   |
| FG      | `171d23` (swap)          | `d8e2ec` (real)                   |
| TXT_BG  | `f6f6f8` (swap)          | `1d252c` (real)                   |
| TXT_FG  | `1d252c` (swap)          | `f6f6f8` (real)                   |
| BTN_BG  | `fbfbfd` (swap)          | `1d252c` (real)                   |
| BTN_FG  | `1d252c` (swap)          | `fbfbfd` (real)                   |
| Rest    | real values              | real values                       |

The swap is necessary because the GTK3 SCSS with `$variant: "dark"` automatically inverts these pairs during compilation. The Base16 plugin (used for GTK4 and Qt) does not perform any inversion
