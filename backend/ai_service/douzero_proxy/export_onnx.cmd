@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..") do set "ROOT=%%~fI"
set "PYTHON=F:\pythonFile\anaconda\envs\anaconda_environment\python.exe"
set "SCRIPT=%SCRIPT_DIR%export_onnx.py"
set "BASELINE=%~1"
set "BASELINE_NAME="

if "%BASELINE%"=="" (
  set "BASELINE_NAME=douzero_ADP"
  set "BASELINE_DIR=%ROOT%\third_party\baselines\douzero_ADP"
  set "OUTPUT_DIR=%ROOT%\backend\ai_models\onnx\douzero_ADP"
) else (
  if exist "%BASELINE%\landlord.ckpt" (
    for %%I in ("%BASELINE%") do (
      set "BASELINE_DIR=%%~fI"
      set "BASELINE_NAME=%%~nxI"
    )
  ) else (
    set "BASELINE_NAME=%BASELINE%"
    set "BASELINE_DIR=%ROOT%\third_party\baselines\%BASELINE%"
  )
  set "OUTPUT_DIR=%ROOT%\backend\ai_models\onnx\!BASELINE_NAME!"
)

if not exist "%PYTHON%" (
  echo [douzero_export] Python env not found: %PYTHON%
  exit /b 1
)

if not exist "%SCRIPT%" (
  echo [douzero_export] Export script not found: %SCRIPT%
  exit /b 1
)

if "%LANDLORDS_PROXY_LOG_LEVEL%"=="" set "LANDLORDS_PROXY_LOG_LEVEL=INFO"
"%PYTHON%" "%SCRIPT%" --baseline-dir "%BASELINE_DIR%" --output-dir "%OUTPUT_DIR%" --device "cpu" --overwrite

endlocal
