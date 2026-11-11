#!/usr/bin/env bash
# Installs the ASCII background shader for Ghostty.
# Usage: curl -fsSL https://raw.githubusercontent.com/AppleAyaan/ghostty-ascii-shader/main/install.sh | bash
#   Optional: ... | bash -s -- classic   (or aurora)
set -euo pipefail

VARIANT="${1:-ascii}"
case "$VARIANT" in
  ascii|classic|aurora) ;;
  *) echo "Unknown variant '$VARIANT' (use ascii, classic or aurora)"; exit 1 ;;
esac
[ "$VARIANT" = "classic" ] && FILE="ascii-classic.glsl" || FILE="$VARIANT.glsl"

REPO_RAW="https://raw.githubusercontent.com/AppleAyaan/ghostty-ascii-shader/main/shaders"
SHADER_DIR="$HOME/.config/ghostty/shaders"
SHADER_PATH="$SHADER_DIR/$FILE"

# 1. Download the shader
mkdir -p "$SHADER_DIR"
curl -fsSL "$REPO_RAW/$FILE" -o "$SHADER_PATH"
echo "Saved shader to $SHADER_PATH"

# 2. Find the Ghostty config file (first one that exists wins)
CONFIG=""
for f in \
  "$HOME/.config/ghostty/config.ghostty" \
  "$HOME/.config/ghostty/config" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config"; do
  if [ -f "$f" ]; then CONFIG="$f"; break; fi
done
if [ -z "$CONFIG" ]; then
  CONFIG="$HOME/.config/ghostty/config"
  touch "$CONFIG"
fi

# 3. Back up, comment out any old shader lines, append the new ones
cp "$CONFIG" "$CONFIG.backup-$(date +%Y%m%d%H%M%S)"
sed -i.tmp -E 's/^(custom-shader[a-z-]* *=)/# \1/' "$CONFIG" && rm -f "$CONFIG.tmp"
{
  echo ""
  echo "# Animated ASCII background (github.com/AppleAyaan/ghostty-ascii-shader)"
  [ "$VARIANT" != "ascii" ] && echo "background = #0b0d14"
  echo "custom-shader = $SHADER_PATH"
  echo "custom-shader-animation = true"
} >> "$CONFIG"
echo "Updated $CONFIG (backup saved next to it)"

echo ""
echo "Done. Reload Ghostty with Cmd+Shift+, (macOS) or Ctrl+Shift+, (Linux), or restart it."
