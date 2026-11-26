#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

stage=build/webos/trailer-package
output=build/webos/trailers
mkdir -p "$stage/app" "$stage/service" "$output"
cp tools/webos/trailer/{index.html,appinfo.json} "$stage/app"
cp assets/icons/icon.png "$stage/app"
cp tools/webos/trailer_service/{host.js,services.json,package.json} assets/trailer/player.html "$stage/service"
python3 - "$stage/app/appinfo.json" "${1:-}" <<'PY'
import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
manifest = json.loads(path.read_text())
if sys.argv[2]:
    manifest['version'] = sys.argv[2]
path.write_text(json.dumps(manifest, indent=2) + '\n')
PY
ares-package "$stage/app" "$stage/service" -o "$output"
