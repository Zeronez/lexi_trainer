@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

pushd "%~dp0"

echo ==========================================
echo   Lexi Trainer - быстрый запуск и тесты
echo ==========================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ОШИБКА] Flutter не найден в PATH.
  echo Установите Flutter и добавьте его в PATH, затем запустите файл снова.
  popd
  exit /b 1
)

echo [1/2] Выполняю flutter pub get...
flutter pub get
if errorlevel 1 (
  echo [ОШИБКА] flutter pub get завершился с ошибкой.
  popd
  exit /b 1
)

:menu
echo.
echo Выберите режим:
echo   1 - Запуск в Chrome
echo   2 - Запуск для Windows
echo   3 - Запуск с Supabase dart-define
echo   4 - flutter analyze
echo   5 - flutter test
echo   0 - Выход
echo.
choice /c 123450 /n /m "Введите номер режима: "
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
echo [ЗАПУСК] flutter run -d chrome
flutter run -d chrome
goto menu

:run_windows
echo.
echo [ЗАПУСК] flutter run -d windows
flutter run -d windows
goto menu

:run_define
echo.
set /p SUPABASE_URL=Введите SUPABASE_URL: 
set /p SUPABASE_PUBLISHABLE_KEY=Введите SUPABASE_PUBLISHABLE_KEY: 
echo.
echo [ЗАПУСК] flutter run с dart-define для Supabase
flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY%
goto menu

:analyze
echo.
echo [ПРОВЕРКА] flutter analyze
flutter analyze
goto menu

:run_test
echo.
echo [ПРОВЕРКА] flutter test
flutter test
goto menu

:exit
echo.
echo Завершение работы.
popd
endlocal
