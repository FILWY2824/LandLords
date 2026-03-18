@echo off
setlocal

set "ROOT=%~dp0"
set "SERVER_EXE=%ROOT%backend\server\build-vs\Debug\landlords_server.exe"
set "PROXY_SCRIPT=%ROOT%backend\ai_service\douzero_proxy\run_proxy.cmd"
set "BASELINE=%~1"

if not exist "%PROXY_SCRIPT%" (
  echo [landlords] Proxy script not found: %PROXY_SCRIPT%
  exit /b 1
)

if not exist "%SERVER_EXE%" (
  echo [landlords] Backend server not found: %SERVER_EXE%
  exit /b 1
)

set "LANDLORDS_BOT_ENDPOINT=http://127.0.0.1:31001/choose_move"
set "LANDLORDS_BOT_TIMEOUT_SECONDS=20"
if "%LANDLORDS_LOG_LEVEL%"=="" set "LANDLORDS_LOG_LEVEL=INFO"
if "%LANDLORDS_PROXY_LOG_LEVEL%"=="" set "LANDLORDS_PROXY_LOG_LEVEL=INFO"
if "%LANDLORDS_DOUZERO_DEVICE%"=="" set "LANDLORDS_DOUZERO_DEVICE=cpu"

if "%BASELINE%"=="" (
  start "LandLords DouZero Proxy" cmd /k ""%PROXY_SCRIPT%""
) else (
  start "LandLords DouZero Proxy" cmd /k ""%PROXY_SCRIPT%" "%BASELINE%""
)

timeout /t 3 /nobreak >nul

echo [landlords] backend endpoint: %LANDLORDS_BOT_ENDPOINT%
"%SERVER_EXE%"

endlocal
