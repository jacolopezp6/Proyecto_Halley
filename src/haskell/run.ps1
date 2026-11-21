param(
  [Parameter(Position = 0)][string]$DataDirectory = 'tests/fixtures/member1-demo',
  [Parameter(Position = 1)][string]$ReportOutput = 'docs/member1/informe-demostracion.md',
  [Parameter(Position = 2)][string]$EventsOutput = 'docs/member1/eventos-demostracion.jsonl',
  [Parameter(Position = 3)][string]$QueriesInput = 'tests/fixtures/member1-demo/queries.jsonl'
)
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $packageRoot '..\..')).Path
$dataPath = if ([IO.Path]::IsPathRooted($DataDirectory)) { $DataDirectory } else { Join-Path $repoRoot $DataDirectory }
$reportPath = if ([IO.Path]::IsPathRooted($ReportOutput)) { $ReportOutput } else { Join-Path $repoRoot $ReportOutput }
$eventsPath = if ([IO.Path]::IsPathRooted($EventsOutput)) { $EventsOutput } else { Join-Path $repoRoot $EventsOutput }
$queriesPath = if ([string]::IsNullOrWhiteSpace($QueriesInput)) { $null } elseif ([IO.Path]::IsPathRooted($QueriesInput)) { $QueriesInput } else { Join-Path $repoRoot $QueriesInput }
Push-Location $packageRoot
try {
  New-Item -ItemType Directory -Force -Path .build\app | Out-Null
  ghc -Wall -Wcompat -Werror -isrc -iapp -outputdir .build\app app\Main.hs -o .build\app\halley-member1.exe
  if ($LASTEXITCODE -ne 0) { throw "GHC compilation failed with exit code $LASTEXITCODE" }
  if ($null -eq $queriesPath) {
    & .build\app\halley-member1.exe $dataPath $reportPath $eventsPath
  } else {
    & .build\app\halley-member1.exe $dataPath $reportPath $eventsPath $queriesPath
  }
  $appExitCode = $LASTEXITCODE
} finally {
  Pop-Location
}
if ($appExitCode -ne 0) { exit $appExitCode }
