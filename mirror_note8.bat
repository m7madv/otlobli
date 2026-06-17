@echo off
REM Mirrors and controls the screen-less Samsung Note 8 (the dedicated Sham
REM Cash notification phone) from this PC over the existing USB/ADB
REM connection. Mouse clicks/keyboard on the mirror window control the real
REM phone, so you can do the one-time setup (install apps, log into Sham
REM Cash, configure MacroDroid) without ever needing the phone's own screen.
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
set SCRCPY=%LOCALAPPDATA%\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v4.0\scrcpy.exe
set DEVICE=988e16384e4f51395230

"%ADB%" -s %DEVICE% wait-for-device
"%SCRCPY%" -s %DEVICE% --stay-awake
