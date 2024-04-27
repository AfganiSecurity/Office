@echo off
title OfficeAFSS
color 0A
:Office
echo.
echo.
echo            ::::::::::::::::::::::::::::::::::::::::::::::
echo            ::       INSTALADOR OFFICE AFSS Zaki        ::
echo            ::::::::::::::::::::::::::::::::::::::::::::::
echo.
echo.
echo                     1 Descargar Archivos
echo.
echo                     2 Instalar Office
echo.
echo                     3 Activar Office y Windows 10 , 11
echo.
echo.
set /p Opciones= Elige el numero de opcion para continuar 
if %Opciones%== 1 goto Descargar
if %Opciones%== 2 goto Instalar
if %Opciones%== 3 goto Activar
if %Opciones%== %Opcione% goto error

:error
msg * Opcion no valida intenta con un numero 
goto Office

:Descargar
cls
color 0A
pause 
echo.
echo.
echo            :::::::::::::::::::::::::::::::::::
echo            ::   Descargando Archivos AFSS   ::
echo            :::::::::::::::::::::::::::::::::::
ECHO.
echo.
set Bypass= Set-ExecutionPolicy -ExecutionPolicy Bypass -Force 
powershell.exe "%Bypass%""
set Ins= powershell.exe .\Download.ps1 -Branch ProPlus2019Retail -Channel Current -Components Word, Excel, PowerPoint
%Ins%
echo Porfavor dale 10min a 20min , se cerrara la Ventana negra automaticamente y se habra descargado office
pause
goto Office

:Instalar
cls
echo.
echo.
echo            :::::::::::::::::::::::::::::::::::::::
echo            :: Ya casi terminamos , Falta poco   ::
echo            :::::::::::::::::::::::::::::::::::::::
echo.
echo.
color 0A
echo Si ya se cerro la Ventana negra , Se finalizo la descarga del office. Dale enter para continuar 
pause
set instala= powershell.exe ./Install.ps1
%instala%
echo Permite que finalize la instalacion , no abras office y ve al paso3
pause
goto Office

:Activar
cls
echo Elige la opcion 4 y luego la 3
pause
./Activadore.cmd
pause
exit




 