@echo off
set iconcache=%localappdata%\IconCache.db
set iconcache_x=%localappdata%\Microsoft\Windows\Explorer\iconcache*
ie4uinit.exe -show
taskkill /IM explorer.exe /F
timeout /t 2 >nul
del /A /F /Q "%iconcache%"
del /A /F /Q "%iconcache_x%"
start explorer.exe