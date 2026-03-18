@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..") do set "ROOT=%%~fI"
set "PYTHON=F:\pythonFile\anaconda\envs\anaconda_environment\python.exe"
set "SERVER_SCRIPT=%SCRIPT_DIR%server.py"
set "DEFAULT_BASELINE=%ROOT%\third_party\baselines\douzero_ADP"
set "ARG=%~1"

if "%ARG%"=="" (
  set "BASELINE_DIR=%DEFAULT_BASELINE%"
) else (
  if exist "%ARG%" (
    set "BASELINE_DIR=%ARG%"
  ) else (
    set "BASELINE_DIR=%ROOT%\third_party\baselines\%ARG%"
  )
)

if not exist "%PYTHON%" (
  echo [douzero_proxy] Python env not found: %PYTHON%
  exit /b 1
)

if not exist "%SERVER_SCRIPT%" (
  echo [douzero_proxy] Server script not found: %SERVER_SCRIPT%
  exit /b 1
)

if not exist "%BASELINE_DIR%" (
  echo [douzero_proxy] Baseline dir not found: %BASELINE_DIR%
  exit /b 1
)

echo [douzero_proxy] using baseline: %BASELINE_DIR%
if "%LANDLORDS_DOUZERO_DEVICE%"=="" set "LANDLORDS_DOUZERO_DEVICE=cpu"
if "%LANDLORDS_DOUZERO_PRELOAD%"=="" set "LANDLORDS_DOUZERO_PRELOAD=1"
if "%LANDLORDS_DOUZERO_WARMUP%"=="" set "LANDLORDS_DOUZERO_WARMUP=1"
if "%LANDLORDS_PROXY_LOG_LEVEL%"=="" set "LANDLORDS_PROXY_LOG_LEVEL=INFO"
"%PYTHON%" "%SERVER_SCRIPT%" --host 127.0.0.1 --port 31001 --baseline-dir "%BASELINE_DIR%"

endlocal
