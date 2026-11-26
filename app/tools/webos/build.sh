#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

if [[ ! -f webos/CMakeLists.txt ]]; then
  flutter-webos create --no-pub --platforms=webos .
fi

version=
for argument in "$@"; do
  case "$argument" in
    --build-name=*) version="${argument#*=}" ;;
  esac
done

# ares-package uses the manifest version when installing updates on the TV.
python3 - "$version" <<'PY'
import json
from pathlib import Path
import sys

manifest = json.loads(Path('tools/webos/appinfo.json').read_text())
if sys.argv[1]:
    manifest['version'] = sys.argv[1]
Path('webos/meta/appinfo.json').write_text(json.dumps(manifest, indent=2) + '\n')
PY

cp assets/icons/icon.png webos/meta/icon.png
cp tools/webos/runner/main.cc webos/runner/main.cc

if [[ -z "${CC:-}" && -n "${WEBOS_FLUTTER_NDK_ENV:-}" ]]; then
  # The Qt-style SDK environment scripts reference optional variables.
  set +u
  source "$WEBOS_FLUTTER_NDK_ENV"
  set -u
fi
bash tools/webos/build-seek-frames.sh webos/runner/zauxoflix-seek-frames.o
if ! grep -Fq 'runner/zauxoflix-seek-frames.o' webos/CMakeLists.txt; then
  cat >> webos/CMakeLists.txt <<'CMAKE'

target_sources(${BINARY_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/runner/zauxoflix-seek-frames.o")
target_link_libraries(${BINARY_NAME} PRIVATE ${CMAKE_DL_LIBS})
CMAKE
fi

flutter-webos build webos --release --dart-define=ZAUXOFLIX_WEBOS=true "$@"
bash tools/webos/package-trailer.sh "$version"
