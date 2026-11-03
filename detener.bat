@echo off
setlocal
title Monitor de internet
set "LOCK=%~dp0monitor.lock"
set "STOP=%~dp0monitor.stop"

2>nul (>>"%LOCK%" (call )) && goto :no_corriendo

type nul > "%STOP%"

for /L %%i in (1,1,15) do (
    ping -n 2 127.0.0.1 >nul
    2>nul (>>"%LOCK%" (call )) && goto :ok
)
echo ERROR: el monitor no respondio. Volve a intentar en unos segundos.
goto :fin

:ok
echo Monitor detenido. Log: %~dp0internet_log.txt
goto :fin

:no_corriendo
echo El monitor no esta corriendo.

:fin
ping -n 4 127.0.0.1 >nul
