$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $packageRoot
try {
  New-Item -ItemType Directory -Force -Path .build\test | Out-Null
  ghc -Wall -Wcompat -Werror -isrc -outputdir .build\test ..\..\tests\haskell\Spec.hs -o .build\test\member1-tests.exe
  if ($LASTEXITCODE -ne 0) { throw "GHC compilation failed with exit code $LASTEXITCODE" }
  & .build\test\member1-tests.exe
  $testExitCode = $LASTEXITCODE
} finally {
  Pop-Location
}
if ($testExitCode -ne 0) { exit $testExitCode }
