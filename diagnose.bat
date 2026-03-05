@echo off
:: ============================================================
:: EWItool Diagnostic Launcher  (Windows – Batch)
:: ============================================================
:: Double-click this file (or run it from a command prompt) to
:: run the EWItool diagnostic script.
::
:: It launches diagnose.ps1 in the same directory and saves the
:: results to ewi-diagnostics.txt in the same directory.
:: ============================================================

echo EWItool Diagnostic Launcher
echo ----------------------------
echo.
echo This will collect system information to help diagnose why
echo EWItool.jar is not opening on your computer.
echo.
echo Results will be saved to: ewi-diagnostics.txt
echo.

:: Temporarily allow this script to run (ProcessScope only, reverts when window closes)
powershell.exe -ExecutionPolicy Bypass -File "%~dp0diagnose.ps1" -JarPath "%~dp0EWItool.jar"

echo.
if %ERRORLEVEL% NEQ 0 (
    echo Something went wrong. Exit code: %ERRORLEVEL%
    echo Try opening PowerShell and running diagnose.ps1 manually.
) else (
    echo Done! Upload ewi-diagnostics.txt to the project maintainer.
)

echo.
pause
