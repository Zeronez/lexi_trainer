@echo off
setlocal EnableExtensions EnableDelayedExpansion

pushd "%~dp0"

echo ==========================================
echo   Lexi Trainer - quick run and tests
echo ==========================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter not found in PATH.
  echo Install Flutter and add it to PATH.
  echo.
  pause
  popd
  exit /b 1
)

echo [1/2] Running flutter pub get...
flutter pub get
if errorlevel 1 (
  echo.
  echo [ERROR] flutter pub get failed.
  echo Check internet connection and dependencies.
  echo.
  pause
  popd
  exit /b 1
)

:menu
echo.
echo Choose mode (default in 10s: Chrome):
echo   1 - Run in Chrome
echo   2 - Run for Windows
echo   3 - Run with Supabase dart-define
echo   4 - flutter analyze
echo   5 - flutter test
echo   0 - Exit
echo.
choice /c 123450 /t 10 /d 1 /n /m "Enter mode number: "
set "choice=%errorlevel%"

if "%choice%"=="6" goto exit
if "%choice%"=="5" goto run_test
if "%choice%"=="4" goto analyze
if "%choice%"=="3" goto run_define
if "%choice%"=="2" goto run_windows
if "%choice%"=="1" goto run_web
goto exit

:run_web
echo.
echo [RUN] flutter run -d chrome
flutter run -d chrome
if errorlevel 1 (
  echo.
  echo [ERROR] Failed to run in Chrome.
)
goto menu

:run_windows
echo.
echo [RUN] flutter run -d windows
flutter run -d windows
if errorlevel 1 (
  echo.
  echo [ERROR] Failed to run Windows app.
  echo Try: flutter config --enable-windows-desktop
)
goto menu

:run_define
echo.
set /p SUPABASE_URL=Enter SUPABASE_URL: 
set /p SUPABASE_PUBLISHABLE_KEY=Enter SUPABASE_PUBLISHABLE_KEY: 
echo.
echo [RUN] flutter run with Supabase dart-define
flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY%
if errorlevel 1 (
  echo.
  echo [ERROR] Run with dart-define failed.
)
goto menu

:analyze
echo.
echo [CHECK] flutter analyze
flutter analyze
goto menu

:run_test
echo.
echo [CHECK] flutter test
flutter test
goto menu

:exit
echo.
echo Done.
echo.
pause
popd
endlocal
