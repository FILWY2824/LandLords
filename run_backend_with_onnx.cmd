@echo off
setlocal

set "ROOT=%~dp0"
set "SERVER_EXE=%ROOT%backend\server\build-vs\Debug\landlords_server.exe"
set "ONNX_DIR_EASY=%ROOT%backend\ai_models\onnx\douzero_ADP"
set "ONNX_DIR_NORMAL=%ROOT%backend\ai_models\onnx\sl"
set "ONNX_DIR_HARD=%ROOT%backend\ai_models\onnx\douzero_WP"

if not exist "%SERVER_EXE%" (
  echo [landlords] Backend server not found: %SERVER_EXE%
  exit /b 1
)

if not exist "%ONNX_DIR_EASY%\landlord.onnx" (
  echo [landlords] Easy ONNX model not found under: %ONNX_DIR_EASY%
  exit /b 1
)

if not exist "%ONNX_DIR_NORMAL%\landlord.onnx" (
  echo [landlords] Normal ONNX model not found under: %ONNX_DIR_NORMAL%
  exit /b 1
)

if not exist "%ONNX_DIR_HARD%\landlord.onnx" (
  echo [landlords] Hard ONNX model not found under: %ONNX_DIR_HARD%
  exit /b 1
)

set "LANDLORDS_BOT_BACKEND=onnx"
set "LANDLORDS_DOUZERO_ONNX_DIR=%ONNX_DIR_NORMAL%"
set "LANDLORDS_DOUZERO_ONNX_DIR_EASY=%ONNX_DIR_EASY%"
set "LANDLORDS_DOUZERO_ONNX_DIR_NORMAL=%ONNX_DIR_NORMAL%"
set "LANDLORDS_DOUZERO_ONNX_DIR_HARD=%ONNX_DIR_HARD%"
if "%LANDLORDS_LOG_LEVEL%"=="" set "LANDLORDS_LOG_LEVEL=DEBUG"
if "%LANDLORDS_MANAGED_DELAY_MIN_MS%"=="" set "LANDLORDS_MANAGED_DELAY_MIN_MS=380"
if "%LANDLORDS_MANAGED_DELAY_MAX_MS%"=="" set "LANDLORDS_MANAGED_DELAY_MAX_MS=680"
if "%LANDLORDS_BOT_BID_DELAY_MIN_MS%"=="" set "LANDLORDS_BOT_BID_DELAY_MIN_MS=260"
if "%LANDLORDS_BOT_BID_DELAY_MAX_MS%"=="" set "LANDLORDS_BOT_BID_DELAY_MAX_MS=460"
if "%LANDLORDS_BOT_PLAY_DELAY_MIN_MS%"=="" set "LANDLORDS_BOT_PLAY_DELAY_MIN_MS=320"
if "%LANDLORDS_BOT_PLAY_DELAY_MAX_MS%"=="" set "LANDLORDS_BOT_PLAY_DELAY_MAX_MS=520"
if "%LANDLORDS_FINISH_DELAY_MS%"=="" set "LANDLORDS_FINISH_DELAY_MS=520"

echo [landlords] backend=onnx
echo [landlords] easy=%LANDLORDS_DOUZERO_ONNX_DIR_EASY%
echo [landlords] normal=%LANDLORDS_DOUZERO_ONNX_DIR_NORMAL%
echo [landlords] hard=%LANDLORDS_DOUZERO_ONNX_DIR_HARD%
echo [landlords] log_level=%LANDLORDS_LOG_LEVEL%
"%SERVER_EXE%"

endlocal
