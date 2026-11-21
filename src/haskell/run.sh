#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
package_root="$PWD"
repo_root="$(cd "$package_root/../.." && pwd)"
data_dir="${1:-tests/fixtures/member1-demo}"
report_path="${2:-docs/member1/informe-demostracion.md}"
events_path="${3:-docs/member1/eventos-demostracion.jsonl}"
case "$data_dir" in /*) ;; *) data_dir="$repo_root/$data_dir" ;; esac
case "$report_path" in /*) ;; *) report_path="$repo_root/$report_path" ;; esac
case "$events_path" in /*) ;; *) events_path="$repo_root/$events_path" ;; esac
mkdir -p .build/app
ghc -Wall -Wcompat -Werror -isrc -iapp -outputdir .build/app app/Main.hs -o .build/app/halley-member1
./.build/app/halley-member1 "$data_dir" "$report_path" "$events_path"
