param(
  [ValidateSet('web','windows','analyze','test')]
  [string]$Mode = 'web',
  [string]$SupabaseUrl = '',
  [string]$SupabaseKey = ''
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

Write-Host '=== Lexi Trainer PowerShell Launcher ==='

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host 'Flutter not found in PATH.' -ForegroundColor Red
  Read-Host 'Press Enter to exit'
  exit 1
}

flutter pub get

switch ($Mode) {
  'web' {
    if ($SupabaseUrl -and $SupabaseKey) {
      flutter run -d chrome --dart-define=SUPABASE_URL=$SupabaseUrl --dart-define=SUPABASE_PUBLISHABLE_KEY=$SupabaseKey
    } else {
      flutter run -d chrome
    }
  }
  'windows' { flutter run -d windows }
  'analyze' { flutter analyze }
  'test' { flutter test }
}
