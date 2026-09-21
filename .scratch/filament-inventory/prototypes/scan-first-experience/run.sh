#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
port=${1:-4173}

printf 'FilaManager prototype: http://127.0.0.1:%s/?variant=A\n' "$port"
exec python3 -m http.server "$port" --bind 127.0.0.1 --directory "$script_dir"

