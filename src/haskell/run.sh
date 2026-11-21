#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
package_root="$PWD"
repo_root="$(cd "$package_root/../.." && pwd)"
data_dir="${1:-tests/fixtures/member1-demo}"
report_path="${2:-src/haskell/.build/output/informe.md}"
events_path="${3:-src/haskell/.build/output/eventos.jsonl}"
queries_path="${4:-tests/fixtures/member1-demo/queries.jsonl}"
case "$data_dir" in /*) ;; *) data_dir="$repo_root/$data_dir" ;; esac
case "$report_path" in /*) ;; *) report_path="$repo_root/$report_path" ;; esac
case "$events_path" in /*) ;; *) events_path="$repo_root/$events_path" ;; esac
case "$queries_path" in /*) ;; *) queries_path="$repo_root/$queries_path" ;; esac
mkdir -p .build/app "$(dirname "$report_path")" "$(dirname "$events_path")"
ghc -Wall -Wcompat -Werror -isrc -iapp -outputdir .build/app app/Main.hs -o .build/app/halley-member1
./.build/app/halley-member1 "$data_dir" "$report_path" "$events_path" "$queries_path"
