#!/bin/bash
# Run with: bash tools/install-eos-macos.sh (Godot must be closed).
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer is for macOS. On Windows use tools/install-eos.ps1." >&2
  exit 1
fi
project_root="$(cd "$(dirname "$0")/.." && pwd)"
stage="$(mktemp -d "${TMPDIR:-/tmp}/holy-ship-eos.XXXXXX")"
archive="$stage/eosg-macos.zip"
curl --fail --location --retry 3 --output "$archive" \
  'https://github.com/3ddelano/epic-online-services-godot/releases/download/2.3.1/epic-online-services-godot-macos-56238973e2cd7ac9ac99ca14f88934465f0a8997.zip'
echo "9b61338266dd883f8ff05be72322e0c54e618078c1269bc8952220e4002c33f7  $archive" | shasum -a 256 -c -
unzip -q "$archive" -d "$stage/unpacked"
source_dir="$stage/unpacked/epic-online-services-godot/addons/epic-online-services-godot/bin/macos"
test -d "$source_dir/libeosg.macos.template_debug.framework"
mkdir -p "$project_root/addons/epic-online-services-godot/bin/macos"
ditto "$source_dir" "$project_root/addons/epic-online-services-godot/bin/macos"
echo 'EOSG 2.3.1 installed. Reopen the project in Godot.'
if [[ ! -f "$project_root/.local/eos.cfg" ]]; then
  echo 'Also copy .local/eos.cfg from your Windows project to this project privately.'
fi
echo "Downloaded archive retained at: $archive"
