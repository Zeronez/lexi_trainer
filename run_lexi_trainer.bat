@echo off
if /I "%~1" NEQ "__runner" (
  start "Lexi Trainer Launcher" cmd /k "\"%~f0\" __runner"
  exit /b
)
shift

setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"

set "LOG=%~dp0launcher.log"
>"%LOG%" echo [%date% %time%] Launcher started

echo ==========================================
echo   Lexi Trainer Launcher
echo ==========================================
echo Working dir: %CD%
echo Log file: %LOG%
echo.

echo [STEP] Checking Flutter...>>"%LOG%"
where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter not found in PATH.
  echo [ERROR] Flutter not found in PATH.>>"%LOG%"
  echo.
  echo Install Flutter and add it to PATH.
  goto :hold
)

echo [STEP] flutter --version>>"%LOG%"
flutter --version >>"%LOG%" 2>&1

echo [STEP] Running flutter pub get...>>"%LOG%"
flutter pub get >>"%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] flutter pub get failed.
  echo [ERROR] flutter pub get failed. See launcher.log>>"%LOG%"
  goto :hold
)

:menu
echo.
echo Choose action:
echo   1 - Run app in Chrome
echo   2 - Run app on Windows
echo   3 - Run with Supabase vars
echo   4 - flutter analyze
echo   5 - flutter test
echo   6 - Open launcher log
echo   0 - Exit
set /p M="Enter number and press Enter [default 1]: "
if "%M%"=="" set "M=1"

if "%M%"=="1" goto run_chrome
if "%M%"=="2" goto run_windows
if "%M%"=="3" goto run_define
if "%M%"=="4" goto run_analyze
if "%M%"=="5" goto run_test
if "%M%"=="6" goto open_log
if "%M%"=="0" goto done

echo [WARN] Unknown option: %M%
goto menu

:run_chrome
echo [RUN] flutter run -d chrome
 echo [RUN] flutter run -d chrome>>"%LOG%"
flutter run -d chrome
set "RC=%errorlevel%"
echo [EXIT] code %RC%>>"%LOG%"
goto menu

:run_windows
echo [RUN] flutter run -d windows
 echo [RUN] flutter run -d windows>>"%LOG%"
flutter run -d windows
set "RC=%errorlevel%"
echo [EXIT] code %RC%>>"%LOG%"
goto menu

:run_define
set /p SUPABASE_URL=SUPABASE_URL: 
set /p SUPABASE_PUBLISHABLE_KEY=SUPABASE_PUBLISHABLE_KEY: 
echo [RUN] flutter run with dart-define
 echo [RUN] flutter run with dart-define>>"%LOG%"
flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY%
set "RC=%errorlevel%"
echo [EXIT] code %RC%>>"%LOG%"
goto menu

:run_analyze
echo [RUN] flutter analyze
 echo [RUN] flutter analyze>>"%LOG%"
flutter analyze
set "RC=%errorlevel%"
echo [EXIT] code %RC%>>"%LOG%"
goto menu

:run_test
echo [RUN] flutter test
 echo [RUN] flutter test>>"%LOG%"
flutter test
set "RC=%errorlevel%"
echo [EXIT] code %RC%>>"%LOG%"
goto menu

:open_log
start "Launcher Log" notepad "%LOG%"
goto menu

:hold
echo.
echo Press any key to continue...
pause >nul
goto menu

:done
echo.
echo Done.
popd
endlocal
exit /b 0
