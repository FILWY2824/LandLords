@echo off
set "DART_SUPPRESS_ANALYTICS=true"
set "APPDATA=%~dp0..\.dart_appdata\roaming"
set "LOCALAPPDATA=%~dp0..\.dart_appdata\local"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
dart pub global run protoc_plugin:protoc_plugin %*
