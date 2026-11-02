@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================================
echo   DONG BO & PUSH TOAN BO CODE MOI LEN GITHUB
echo ========================================================
echo.

git add .
git status
echo.

set "MSG=feat: Phat am mac dinh tieng Viet, nut nghe da ngu ke ben am Viet, luyen viet but thuan, 3D Flashcard, game 60s va video nap tim"

git commit -m "%MSG%"
echo.
echo Dang day len GitHub (origin main)...
git push origin main

echo.
echo ========================================================
echo   HOAN TAT! Code moi da duoc dong bo len GitHub!
echo ========================================================
pause
