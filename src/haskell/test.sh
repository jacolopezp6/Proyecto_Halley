#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
mkdir -p .build/test
ghc -Wall -Wcompat -Werror -isrc -outputdir .build/test ../../tests/haskell/Spec.hs -o .build/test/member1-tests
./.build/test/member1-tests
