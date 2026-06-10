# Oomox/Themix - Tokyo Night Dark User Presets

Presets de usuario para [Themix/Oomox](https://github.com/themix-project/themix-gui) que generan un tema completo Tokyo Night Dark para GTK3, GTK4, Qt5, Qt6 e iconos Papirus.

## Contenido

```
presets/
  base16-project/tokyo-night-dark   ← Preset para GTK3 (colores BG/FG swapeados)
  tokyo-night-dark-gtk4              ← Preset para GTK4 + Qt5 + Qt6 (colores reales)

oomox-patches/
  gtk.scss                           ← Parche: $variant: "dark"
  change_color.sh                    ← Parche: fix directorios symbolic en Papirus
```

## Requisitos

- [themix-full-git](https://aur.archlinux.org/packages/themix-full-git) (AUR)

```bash
paru -S themix-full-git
```

## Parches en Oomox (aplicar antes de exportar)

Oomox necesita dos modificaciones en sus archivos del sistema para que los temas se generen correctamente.

### 1. Variante oscura en SCSS (`gtk.scss`)

El template SCSS de GTK3 compila por defecto con `$variant: "light"`. Esto hace que los colores de backdrop usen `darken()` en vez de `lighten()`, dando resultados incorrectos para temas oscuros.

Reemplazar el archivo:

```
/opt/oomox/plugins/theme_oomox/src/gtk-3.20/scss/gtk.scss
```

Con el contenido de `oomox-patches/gtk.scss` (o simplemente cambiar la primera línea de `$variant: "light"` a `$variant: "dark"`).

### 2. Fix de iconos simbólicos en Papirus (`change_color.sh`)

El script de generación de iconos busca el directorio `Papirus/symbolic` que no existe. Los iconos simbólicos están dentro de las carpetas de tamaño (`16x16`, `22x22`, `24x24`).

Reemplazar el archivo:

```
/opt/oomox/plugins/icons_papirus/change_color.sh
```

Con el contenido de `oomox-patches/change_color.sh`. El cambio está en la línea 149:

```diff
- "$tmp_dir"/Papirus/symbolic
+ "$tmp_dir"/Papirus/{16x16,22x22,24x24}/symbolic
```

## Importar los presets

Copiar los presets a la carpeta de configuración de oomox:

```bash
cp presets/base16-project/tokyo-night-dark ~/.config/oomox/colors/base16-project/
cp presets/tokyo-night-dark-gtk4 ~/.config/oomox/colors/
```

Al abrir Themix, aparecerán en **User Presets**:
- `base16-project: tokyo-night-dark`
- `tokyo-night-dark-gtk4`

## Exportar los temas

### Preset `base16-project: tokyo-night-dark` (solo GTK3)

Este preset tiene los colores BG/FG, TXT_BG/TXT_FG y BTN_BG/BTN_FG **swapeados** porque el template SCSS con `$variant: "dark"` los invierte al compilar. El resto de colores (HDR, SEL, MENU, ICONS, TERMINAL) son los valores reales de Tokyo Night.

Exportar desde Themix:
1. **Theme** (GTK3) → se instala en `~/.themes/oomox-tokyo-night-dark/`
2. **Icons** (Papirus) → se instala en `~/.icons/oomox-tokyo-night-dark/`

### Preset `tokyo-night-dark-gtk4` (GTK4 + Qt5 + Qt6)

Este preset tiene los colores **reales sin swap** porque el plugin Base16 los lee directamente sin lógica de variante.

Exportar desde Themix:
1. **Base16 > gtk4-oodwaita** → genera el CSS para GTK4/libadwaita
2. **Base16 > qt5ct (fusion)** → genera el color scheme para Qt5
3. **Base16 > qt6ct (fusion)** → genera el color scheme para Qt6

## Diferencia entre los dos presets

| Campo | `tokyo-night-dark` (GTK3) | `tokyo-night-dark-gtk4` (GTK4/Qt) |
|-------|--------------------------|-----------------------------------|
| BG | `d8e2ec` (swap) | `171d23` (real) |
| FG | `171d23` (swap) | `d8e2ec` (real) |
| TXT_BG | `f6f6f8` (swap) | `1d252c` (real) |
| TXT_FG | `1d252c` (swap) | `f6f6f8` (real) |
| BTN_BG | `fbfbfd` (swap) | `1d252c` (real) |
| BTN_FG | `1d252c` (swap) | `fbfbfd` (real) |
| Resto | valores reales | valores reales |

El swap es necesario porque el SCSS de GTK3 con `$variant: "dark"` invierte automáticamente estos pares al compilar. El plugin Base16 (usado para GTK4 y Qt) no hace ninguna inversión.
