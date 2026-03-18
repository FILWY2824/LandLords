@echo off
setlocal

cd /d %~dp0

echo [benchmark] building strategy benchmark target...
cmake --build backend\server\build-vs --config Debug --target landlords_strategy_benchmark
if errorlevel 1 (
  echo [benchmark] build failed
  exit /b 1
)

echo [benchmark] running batch evaluation...
backend\server\build-vs\Debug\landlords_strategy_benchmark.exe
if errorlevel 1 (
  echo [benchmark] evaluation failed
  exit /b 1
)

echo [benchmark] report written to reports\strategy_benchmark.md
endlocal
