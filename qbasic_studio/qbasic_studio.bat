@echo off
chcp 65001 >nul
title QBasic Studio

cd /d "%~dp0"

echo ========================================================
echo       Lancement de QBasic Studio - IDE Professionnel
echo ========================================================

rem Verification si le serveur ecoute deja sur le port 3000
netstat -ano | findstr ":3000" | findstr "LISTENING" >nul
if %errorlevel% equ 0 (
    echo Le serveur QBasic Studio est deja actif.
) else (
    echo Demarrage du serveur Node.js en arriere-plan...
    start /b node server.js
    timeout /t 2 /nobreak >nul
)

rem Detection de Microsoft Edge pour le mode application native
set "EDGE_PATH="
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "EDGE_PATH=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if "%EDGE_PATH%"=="" if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "EDGE_PATH=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if "%EDGE_PATH%"=="" if exist "%LOCALAPPDATA%\Microsoft\Edge\Application\msedge.exe" set "EDGE_PATH=%LOCALAPPDATA%\Microsoft\Edge\Application\msedge.exe"

if defined EDGE_PATH (
    echo Lancement de QBasic Studio en mode Application native...
    start "" "%EDGE_PATH%" --app=http://localhost:3000 --window-size=1280,840
) else (
    echo Ouverture dans le navigateur par defaut...
    start http://localhost:3000
)

echo Pret !