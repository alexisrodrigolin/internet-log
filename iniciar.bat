@echo off
setlocal
title Monitor de internet
set "LOCK=%~dp0monitor.lock"
set "STOP=%~dp0monitor.stop"

2>nul (>>"%LOCK%" (call )) || goto :ya_corriendo

del "%STOP%" 2>nul
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0monitor.ps1"

for /L %%i in (1,1,15) do (
    ping -n 2 127.0.0.1 >nul
    2>nul (>>"%LOCK%" (call )) || goto :ok
)
echo ERROR: el monitor no pudo arrancar.
goto :fin

:ok
echo Monitor iniciado. Log: %~dp0internet_log.txt
goto :fin

:ya_corriendo
echo El monitor ya esta corriendo.

:fin
ping -n 4 127.0.0.1 >nul
