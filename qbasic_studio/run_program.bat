@echo off
chcp 65001 >nul
if "%~1"=="" goto :usage

set "TARGET_FILE=%~f1"
set "TARGET_DIR=%~dp1"
set "TARGET_NAME=%~nx1"
set "QBASIC_EXE=%~dp0..\qbasic_win\qbasic_win.exe"

if not exist "%QBASIC_EXE%" (
    echo Erreur : qbasic_win.exe introuvable a l'emplacement :
    echo "%QBASIC_EXE%"
    pause
    exit /b 1
)

cd /d "%TARGET_DIR%"
title QBasic - %TARGET_NAME%

echo ======================================================================
echo   QBasic Studio - Execution : %TARGET_NAME%
echo ======================================================================
echo.

"%QBASIC_EXE%" -r "%TARGET_FILE%"
set "QB_EXIT_CODE=%errorlevel%"

echo.
echo ======================================================================
if %QB_EXIT_CODE% equ 0 (
    echo   [Programme termine avec succes - Code : 0]
) else (
    echo   [Programme termine avec le code : %QB_EXIT_CODE%]
)
echo ======================================================================
echo Appuyez sur une touche pour fermer ce terminal...
pause >nul
exit /b %QB_EXIT_CODE%

:usage
echo Usage: run_program.bat <chemin_vers_fichier.bas>
pause
exit /b 1