@echo off
title AuraShare - Secure Offline File Sharing
color 0b
echo ==============================================================
echo        AuraShare - Secure Offline File Sharing Desktop
echo ==============================================================
echo.
echo Launching offline local node server...
start /b python desktop_app.py
timeout /t 2 >nul
echo AuraShare is running!
pause
